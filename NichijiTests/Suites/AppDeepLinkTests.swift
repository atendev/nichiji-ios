import Testing
import Foundation
@testable import Nichiji

/*-----------------------------deep-link-tests----------------------------*/

@Suite("AppDeepLink Tests")
struct AppDeepLinkTests {
    @Test("The today link round-trips through its URL")
    func todayRoundTrips() throws {
        let url = AppDeepLink.today.url
        #expect(url.absoluteString == "nichiji://today")
        #expect(AppDeepLink(url: url) == .today)
    }

    @Test("Scheme and host match case-insensitively")
    func caseInsensitive() throws {
        let url = try #require(URL(string: "NICHIJI://Today"))
        #expect(AppDeepLink(url: url) == .today)
    }

    @Test("A trailing slash still opens Today")
    func trailingSlash() throws {
        let url = try #require(URL(string: "nichiji://today/"))
        #expect(AppDeepLink(url: url) == .today)
    }

    @Test("Unknown schemes, hosts and paths are rejected", arguments: [
        "https://today",
        "nichiji://review",
        "nichiji://today/extra",
        "nichiji:today"
    ])
    func rejectsOtherURLs(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(AppDeepLink(url: url) == nil)
    }

    @Test("The today link selects the Today tab")
    func selectsTodayTab() {
        #expect(AppDeepLink.today.tab == .today)
    }
}
