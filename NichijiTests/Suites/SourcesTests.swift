import Testing
import Foundation
@testable import Nichiji

/*-------------------------------sources-tests------------------------------*/

private final class TestBundleMarker {}

@Suite("Sources Tests")
struct SourcesTests {
    private static let committedFile: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Dataset/Shared/DATA-SOURCES.md")

    private static let fixture = """
    # Data sources

    The bundle holds 2 kanji.

    ## Inputs

    | File | Version |
    |---|---|
    | a.json | 1 |

    ## Attribution

    - Stroke order: [KanjiVG](https://kanjivg.tagaini.net) by Ulrich Apel, [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).
    - Radical names are the app's own.

    ## Snapshots

    - KanjiVG: 2026-07-14 (release r20260714)
    """

    @Test("Bulleted sections parse and the Inputs table and prose are skipped")
    func parsesSections() {
        let document = DataSourcesDocument(markdown: Self.fixture)

        #expect(document.sections.map { $0.title } == ["Attribution", "Snapshots"])
        #expect(document.section("Attribution")?.items.count == 2)
        #expect(document.section("Snapshots")?.items.first?.text == "KanjiVG: 2026-07-14 (release r20260714)")
        #expect(document.section("Inputs") == nil)
    }

    @Test("A bullet's text drops link markup and keeps its links in order")
    func stripsLinks() {
        let item = DataSourceItem(markdown: "Stroke order: [KanjiVG](https://kanjivg.tagaini.net) by Ulrich Apel, [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).")

        #expect(item.text == "Stroke order: KanjiVG by Ulrich Apel, CC BY-SA 3.0.")
        #expect(item.links.map { $0.title } == ["KanjiVG", "CC BY-SA 3.0"])
        #expect(item.links.map { $0.url.absoluteString } == ["https://kanjivg.tagaini.net", "https://creativecommons.org/licenses/by-sa/3.0/"])
    }

    @Test("The committed file has Attribution and Snapshots, and Waller's licence links the sharing page")
    func committedFileParses() throws {
        let markdown = try String(contentsOf: Self.committedFile, encoding: .utf8)
        let document = DataSourcesDocument(markdown: markdown)

        let attribution = try #require(document.section("Attribution"))
        #expect(document.section("Snapshots")?.items.count == 4)
        let waller = try #require(attribution.items.first { $0.text.contains("Jonathan Waller's JLPT Resources") })
        #expect(waller.links.contains { $0.title == "CC BY" && $0.url.absoluteString == "https://www.tanos.co.uk/jlpt/sharing/" })
        #expect(!markdown.contains("isJLPTLevelEstimated"))
    }

    @Test("Missing or non-UTF-8 data reads as missing")
    func missingData() {
        #expect(SourcesState(data: nil) == .missing)
        #expect(SourcesState(data: Data([0xFF, 0xFE, 0xFD])) == .missing)
        #expect(SourcesState(data: Data("no bullets here".utf8)) == .missing)
    }

    @Test("A bundle without the file is missing, and the app bundle ships it")
    func loadsFromBundle() {
        #expect(SourcesState.load(from: Bundle(for: TestBundleMarker.self)) == .missing)

        guard case .loaded(let document) = SourcesState.load(from: .main) else {
            Issue.record("The app bundle has no readable DATA-SOURCES.md")
            return
        }
        #expect(document.section("Attribution") != nil)
    }
}
