import Foundation

/*---------------------------------enums--------------------------------------*/

/// Prompt and answer pairing for one review card.
public enum ReviewCardType: String, Codable, CaseIterable, Sendable {
    case kanjiToMeaning
    case kanjiToReading
    case meaningToKanji

    public var displayName: String {
        switch self {
        case .kanjiToMeaning: "Kanji to meaning"
        case .kanjiToReading: "Kanji to reading"
        case .meaningToKanji: "Meaning to kanji"
        }
    }

    public var subtitleNote: String {
        switch self {
        case .kanjiToMeaning: "See the kanji, recall what it means."
        case .kanjiToReading: "See the kanji, recall how it is read."
        case .meaningToKanji: "See the meaning, recall the kanji."
        }
    }
}

/// Ordering strategy for the cards in a review session.
public enum ReviewOrder: String, Codable, CaseIterable, Sendable {
    case dueFirst
    case hardestFirst
    case newestFirst
    case random

    public var displayName: String {
        switch self {
        case .dueFirst: "Due first"
        case .hardestFirst: "Hardest first"
        case .newestFirst: "Newest first"
        case .random: "Random"
        }
    }

    public var subtitleNote: String {
        switch self {
        case .dueFirst: "Kanji that are due longest ago come first."
        case .hardestFirst: "Kanji you forget most often come first."
        case .newestFirst: "Recently learned kanji come first."
        case .random: "A different mix every time."
        }
    }
}

/// Number of cards a review session pulls from the due queue.
public enum ReviewSessionSize: String, Codable, CaseIterable, Sendable {
    case five
    case ten
    case twenty
    case allDue

    /// Card cap for the session, or nil when every due kanji is included.
    public var limit: Int? {
        switch self {
        case .five: 5
        case .ten: 10
        case .twenty: 20
        case .allDue: nil
        }
    }

    /// Chip label on the Review settings screen.
    public var chipLabel: String {
        limit.map(String.init) ?? "All due"
    }
}

/// What the review audio speaks when it plays.
public enum ReviewAudioContent: String, Codable, CaseIterable, Sendable {
    case reading
    case readingAndWord

    public var displayName: String {
        switch self {
        case .reading: "Reading"
        case .readingAndWord: "Reading and word"
        }
    }
}

/// Shared UserDefaults keys for review session preferences.
public enum ReviewPreferenceKey: String, Sendable {
    case cardTypes = "reviewCardTypes"
    case order = "reviewOrder"
    case sessionSize = "reviewSessionSize"
    case showsExampleWord = "reviewShowsExampleWord"
    case repeatsForgotten = "reviewRepeatsForgotten"
    case autoplaysAudio = "reviewAutoplaysAudio"
    case audioContent = "reviewAudioContent"
}

/*--------------------------------structs-------------------------------------*/

/// Value snapshot of the review preferences stored in UserDefaults.
public struct ReviewPreferencesSnapshot: Codable, Equatable, Sendable {
    /// Enabled card types. Never empty: the last enabled type cannot be turned off.
    public private(set) var cardTypes: Set<ReviewCardType>
    public var order: ReviewOrder
    public var sessionSize: ReviewSessionSize
    public var showsExampleWord: Bool
    public var repeatsForgotten: Bool
    public var autoplaysAudio: Bool
    public var audioContent: ReviewAudioContent

    public static let defaultCardTypes: Set<ReviewCardType> = [.kanjiToMeaning, .kanjiToReading]

    public init(
        cardTypes: Set<ReviewCardType> = Self.defaultCardTypes,
        order: ReviewOrder = .dueFirst,
        sessionSize: ReviewSessionSize = .ten,
        showsExampleWord: Bool = true,
        repeatsForgotten: Bool = true,
        autoplaysAudio: Bool = false,
        audioContent: ReviewAudioContent = .reading
    ) {
        self.cardTypes = cardTypes.isEmpty ? Self.defaultCardTypes : cardTypes
        self.order = order
        self.sessionSize = sessionSize
        self.showsExampleWord = showsExampleWord
        self.repeatsForgotten = repeatsForgotten
        self.autoplaysAudio = autoplaysAudio
        self.audioContent = audioContent
    }

    public static let standard = ReviewPreferencesSnapshot()

    /// Summary string displayed in the main Settings row (`10 cards · Due first`).
    public var settingsSummary: String {
        Self.settingsSummary(sessionSize: sessionSize, order: order)
    }

    public static func settingsSummary(sessionSize: ReviewSessionSize, order: ReviewOrder) -> String {
        let size = sessionSize.limit.map { "\($0) cards" } ?? "All due"
        return "\(size) · \(order.displayName)"
    }

    /// Turns a card type on or off. Turning off the last enabled type is ignored and returns false.
    @discardableResult
    public mutating func setCardType(_ type: ReviewCardType, enabled: Bool) -> Bool {
        if enabled {
            cardTypes.insert(type)
            return true
        }
        guard cardTypes.count > 1 || !cardTypes.contains(type) else { return false }
        cardTypes.remove(type)
        return true
    }

    /// Reads the current snapshot from a UserDefaults instance, applying defaults for unset keys.
    public static func load(
        from defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
    ) -> ReviewPreferencesSnapshot {
        let standard = Self.standard
        let storedTypes = (defaults.stringArray(forKey: ReviewPreferenceKey.cardTypes.rawValue) ?? [])
            .compactMap(ReviewCardType.init(rawValue:))
        let order = ReviewOrder(
            rawValue: defaults.string(forKey: ReviewPreferenceKey.order.rawValue) ?? ""
        ) ?? standard.order
        let sessionSize = ReviewSessionSize(
            rawValue: defaults.string(forKey: ReviewPreferenceKey.sessionSize.rawValue) ?? ""
        ) ?? standard.sessionSize
        let showsExampleWord = defaults.object(forKey: ReviewPreferenceKey.showsExampleWord.rawValue) as? Bool
            ?? standard.showsExampleWord
        let repeatsForgotten = defaults.object(forKey: ReviewPreferenceKey.repeatsForgotten.rawValue) as? Bool
            ?? standard.repeatsForgotten
        let autoplaysAudio = defaults.object(forKey: ReviewPreferenceKey.autoplaysAudio.rawValue) as? Bool
            ?? standard.autoplaysAudio
        let audioContent = ReviewAudioContent(
            rawValue: defaults.string(forKey: ReviewPreferenceKey.audioContent.rawValue) ?? ""
        ) ?? standard.audioContent

        return ReviewPreferencesSnapshot(
            cardTypes: Set(storedTypes),
            order: order,
            sessionSize: sessionSize,
            showsExampleWord: showsExampleWord,
            repeatsForgotten: repeatsForgotten,
            autoplaysAudio: autoplaysAudio,
            audioContent: audioContent
        )
    }

    /// Writes all fields of the snapshot into a UserDefaults instance.
    public func save(
        to defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
    ) {
        let types = ReviewCardType.allCases.filter(cardTypes.contains).map(\.rawValue)
        defaults.set(types, forKey: ReviewPreferenceKey.cardTypes.rawValue)
        defaults.set(order.rawValue, forKey: ReviewPreferenceKey.order.rawValue)
        defaults.set(sessionSize.rawValue, forKey: ReviewPreferenceKey.sessionSize.rawValue)
        defaults.set(showsExampleWord, forKey: ReviewPreferenceKey.showsExampleWord.rawValue)
        defaults.set(repeatsForgotten, forKey: ReviewPreferenceKey.repeatsForgotten.rawValue)
        defaults.set(autoplaysAudio, forKey: ReviewPreferenceKey.autoplaysAudio.rawValue)
        defaults.set(audioContent.rawValue, forKey: ReviewPreferenceKey.audioContent.rawValue)
    }
}
