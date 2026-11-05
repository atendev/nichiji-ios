import Testing
import Foundation
import StoreKitTest
@testable import Nichiji

/*------------------------------storekit-session------------------------------*/

/// End-to-end runs of the real service against `Nichiji.storekit`. Serialized because a session is process-wide.
/// CI sets the skip variable because its simulator returned no products from the session, cause unknown.
@Suite(
    "StoreKit session Tests",
    .serialized,
    .timeLimit(.minutes(1)),
    .disabled(if: ProcessInfo.processInfo.environment["NICHIJI_SKIP_STOREKIT_TESTS"] == "1", "StoreKit testing is unavailable on the CI simulator")
)
@MainActor
struct StoreKitSessionTests {
    private func makeSession() throws -> SKTestSession {
        let url = try #require(Bundle(for: ProTestBundleToken.self).url(forResource: "Nichiji", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    @Test("Product info loads the name and price")
    func productInfo() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }
        let service = StoreKitPurchaseService(suiteName: ProTestSuite().name)

        let info = try await service.productInfo()
        #expect(info.displayName == "Nichiji Pro")
        #expect(info.displayPrice.contains("4.99"))
    }

    @Test("A purchase unlocks and caches; clearing the transaction locks again")
    func purchaseThenClear() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }
        let suite = ProTestSuite()
        defer { suite.remove() }
        let service = StoreKitPurchaseService(suiteName: suite.name)

        #expect(try await service.purchase() == .purchased(.purchased))
        #expect(ProEntitlementCache.load(from: suite.defaults) == .purchased)

        session.clearTransactions()
        #expect(await service.refreshAccess() == .locked)
        #expect(ProEntitlementCache.load(from: suite.defaults) == .locked)
    }

    @Test("Restore after a purchase reports Pro")
    func restoreAfterPurchase() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }
        let suite = ProTestSuite()
        defer { suite.remove() }
        let service = StoreKitPurchaseService(suiteName: suite.name)

        _ = try await service.purchase()
        #expect(try await service.restorePurchases() == .purchased)
    }

    @Test("A purchase made outside the app arrives on the update stream")
    func outsidePurchaseArrives() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }
        let suite = ProTestSuite()
        defer { suite.remove() }
        let service = StoreKitPurchaseService(suiteName: suite.name)
        var updates = service.accessUpdates().makeAsyncIterator()
        // The app's own listener may finish the transaction first, so give this stream time to subscribe.
        try await Task.sleep(for: .milliseconds(500))

        try session.buyProduct(productIdentifier: ProProduct.id)
        #expect(await updates.next() == .purchased)
    }
}
