import Foundation

/*--------------------------------folding-------------------------------------*/

/// The one folding that runs on both the data and the query, so the two always meet.
enum SearchFolding {
    private static let droppedRomaji: Set<Character> = ["'", "\u{2019}", ".", "-"]
    private static let romajiPairs: [(from: String, to: String)] = [
        ("tsu", "tu"), ("chi", "ti"), ("shi", "si"), ("mb", "nb")
    ]

    /*-------------------------------scripts--------------------------------*/

    /// Han ideographs across every block, plus the numeral zero 〇, matching the generator.
    static func isKanji(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xF900...0xFAFF, 0x20000...0x2FA1F, 0x3007:
            return true
        default:
            return false
        }
    }

    static func isKana(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3041...0x3096, 0x309D...0x309F, 0x30A1...0x30FA, 0x30FC...0x30FF, 0xFF66...0xFF9F:
            return true
        default:
            return false
        }
    }

    /// Basic Latin through Latin Extended-B letters, which covers macron vowels.
    static func isLatinLetter(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value < 0x250 && scalar.properties.isAlphabetic
    }

    /*--------------------------------kana----------------------------------*/

    /// Katakana becomes hiragana. Okurigana markers (`.`, `-`), middle dots and spaces drop.
    static func kana(_ text: String) -> String {
        var folded = String.UnicodeScalarView()
        for scalar in text.precomposedStringWithCompatibilityMapping.unicodeScalars where !isKanaMarker(scalar) {
            folded.append(hiragana(scalar))
        }
        return String(folded)
    }

    private static func isKanaMarker(_ scalar: Unicode.Scalar) -> Bool {
        scalar == "." || scalar == "-" || scalar == "\u{30FB}" || scalar.properties.isWhitespace
    }

    private static func hiragana(_ scalar: Unicode.Scalar) -> Unicode.Scalar {
        guard (0x30A1...0x30F6).contains(scalar.value), let converted = Unicode.Scalar(scalar.value - 0x60) else {
            return scalar
        }
        return converted
    }

    /*-------------------------------romaji---------------------------------*/

    /// Lowercase, macrons off, long vowels collapsed (`ō`/`ou`/`oo` to `o`, `ū`/`uu` to `u`),
    /// apostrophes, dots, hyphens and spaces dropped, then `shi`/`tsu`/`chi`/`mb` folded to `si`/`tu`/`ti`/`nb`.
    static func romaji(_ text: String) -> String {
        var letters: [Character] = []
        for character in text.lowercased() where !droppedRomaji.contains(character) && !character.isWhitespace {
            letters.append(plainVowel(character))
        }
        let collapsed = String(collapseLongVowels(letters))
        return romajiPairs.reduce(collapsed) { $0.replacingOccurrences(of: $1.from, with: $1.to) }
    }

    private static func plainVowel(_ character: Character) -> Character {
        switch character {
        case "\u{101}": return "a"
        case "\u{12B}": return "i"
        case "\u{16B}": return "u"
        case "\u{113}": return "e"
        case "\u{14D}": return "o"
        default: return character
        }
    }

    private static func collapseLongVowels(_ letters: [Character]) -> [Character] {
        var result: [Character] = []
        for letter in letters {
            if let last = result.last, extendsVowel(last, with: letter) {
                continue
            }
            result.append(letter)
        }
        return result
    }

    private static func extendsVowel(_ last: Character, with next: Character) -> Bool {
        if last == "o" {
            return next == "o" || next == "u"
        }
        return last == next && "aeiu".contains(next)
    }

    /*-------------------------------english--------------------------------*/

    /// Lowercase, accents off, every run of other characters (hyphens, dots, brackets) read as one space.
    static func english(_ text: String) -> String {
        var result = ""
        var pendingSpace = false
        for character in text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) {
            if character.isLetter || character.isNumber {
                if pendingSpace && !result.isEmpty {
                    result.append(" ")
                }
                pendingSpace = false
                result.append(character)
            } else {
                pendingSpace = true
            }
        }
        return result
    }
}

/*--------------------------------matching------------------------------------*/

/// Byte-level substring tiers, so a keystroke scan over about 20k rows stays cheap.
enum SearchMatcher {
    /// Exact, prefix or substring of `needle` in `text`; nil when it is absent.
    /// With `wordStartOnly`, a hit past the start must follow a space, so `one` finds "one sided" but not "someone".
    static func tier(of needle: [UInt8], in text: String, wordStartOnly: Bool) -> MatchTier? {
        var mutableText = text
        return mutableText.withUTF8 { (haystack: UnsafeBufferPointer<UInt8>) -> MatchTier? in
            guard !needle.isEmpty, haystack.count >= needle.count else { return nil }
            for start in 0...(haystack.count - needle.count) where matches(needle, in: haystack, at: start) {
                if start == 0 {
                    return haystack.count == needle.count ? .exact : .prefix
                }
                if !wordStartOnly || haystack[start - 1] == 0x20 {
                    return .substring
                }
            }
            return nil
        }
    }

    /// The best tier over several fields, or nil when none match.
    static func bestTier(of needle: [UInt8], in texts: [String], wordStartOnly: Bool) -> MatchTier? {
        texts.compactMap { tier(of: needle, in: $0, wordStartOnly: wordStartOnly) }.min()
    }

    private static func matches(_ needle: [UInt8], in haystack: UnsafeBufferPointer<UInt8>, at start: Int) -> Bool {
        needle.indices.allSatisfy { haystack[start + $0] == needle[$0] }
    }
}
