import Foundation

/*-----------------------------data-sources-------------------------------*/

/// One bullet from the generated `DATA-SOURCES.md`: its text with link markup stripped, and its links in order.
struct DataSourceItem: Equatable, Sendable {
    struct Link: Equatable, Sendable {
        let title: String
        let url: URL
    }

    let text: String
    let links: [Link]

    init(markdown: String) {
        var text = ""
        var links: [Link] = []
        var rest = Substring(markdown)
        while let match = rest.firstMatch(of: /\[([^\]]+)\]\(([^)\s]+)\)/) {
            let title = String(match.output.1)
            text += rest[..<match.range.lowerBound]
            text += title
            if let url = URL(string: String(match.output.2)) {
                links.append(Link(title: title, url: url))
            }
            rest = rest[match.range.upperBound...]
        }
        text += rest
        self.text = text
        self.links = links
    }
}

/// The bulleted sections of `DATA-SOURCES.md`. The Inputs table and plain paragraphs are left out.
struct DataSourcesDocument: Equatable, Sendable {
    struct Section: Equatable, Sendable {
        let title: String
        let items: [DataSourceItem]
    }

    let sections: [Section]

    init(markdown: String) {
        var sections: [Section] = []
        var title: String?
        var items: [DataSourceItem] = []
        for rawLine in markdown.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("## ") {
                if let title, !items.isEmpty {
                    sections.append(Section(title: title, items: items))
                }
                title = String(line.dropFirst(3))
                items = []
            } else if line.hasPrefix("- "), title != nil {
                items.append(DataSourceItem(markdown: String(line.dropFirst(2))))
            }
        }
        if let title, !items.isEmpty {
            sections.append(Section(title: title, items: items))
        }
        self.sections = sections
    }

    func section(_ title: String) -> Section? {
        sections.first { $0.title == title }
    }
}

/// What the Sources screen shows: the parsed document, or an error when the bundled file is absent or unreadable.
enum SourcesState: Equatable, Sendable {
    case loaded(DataSourcesDocument)
    case missing

    static let resourceName = "DATA-SOURCES"

    init(data: Data?) {
        guard let data, let markdown = String(data: data, encoding: .utf8) else {
            self = .missing
            return
        }
        let document = DataSourcesDocument(markdown: markdown)
        self = document.sections.isEmpty ? .missing : .loaded(document)
    }

    static func load(from bundle: Bundle) -> SourcesState {
        let url = bundle.url(forResource: resourceName, withExtension: "md")
        return SourcesState(data: url.flatMap { try? Data(contentsOf: $0) })
    }
}

enum SourcesCopy {
    static let title = "Sources"
    static let intro = "The JLPT has not published official kanji lists since 2010. Levels follow Jonathan Waller's community lists."
    static let missing = "Sources could not be loaded."
    static let attributionSection = "Attribution"
    static let snapshotsSection = "Snapshots"
    static let levelFooter = "JLPT levels are unofficial community lists."
}
