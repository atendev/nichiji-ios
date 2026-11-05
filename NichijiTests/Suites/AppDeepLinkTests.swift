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

    @Test("The pro link round-trips, ignores case and allows a trailing slash")
    func proRoundTrips() throws {
        #expect(AppDeepLink.pro.url.absoluteString == "nichiji://pro")
        #expect(AppDeepLink(url: AppDeepLink.pro.url) == .pro)
        #expect(AppDeepLink(url: try #require(URL(string: "NICHIJI://Pro"))) == .pro)
        #expect(AppDeepLink(url: try #require(URL(string: "nichiji://pro/"))) == .pro)
        #expect(AppDeepLink.pro.tab == .today)
    }

    @Test("Unknown schemes, hosts and paths are rejected", arguments: [
        "https://today",
        "https://pro",
        "nichiji://review",
        "nichiji://today/extra",
        "nichiji://pro/extra",
        "nichiji:today"
    ])
    func rejectsOtherURLs(_ string: String) throws {
        let url = try #require(URL(string: string))
        #expect(AppDeepLink(url: url) == nil)
    }

    @Test("The app bundle registers the nichiji URL scheme")
    func bundleRegistersScheme() throws {
        let types = try #require(Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]])
        let schemes = types.flatMap { $0["CFBundleURLSchemes"] as? [String] ?? [] }
        #expect(schemes.contains(AppDeepLink.scheme))
    }

    @Test("The today link selects the Today tab")
    func selectsTodayTab() {
        #expect(AppDeepLink.today.tab == .today)
    }
}
