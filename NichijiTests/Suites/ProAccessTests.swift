import Testing
import Foundation
import WidgetKit
@testable import Nichiji

/// Finds the unit-test bundle, which ships `Nichiji.storekit`.
final class ProTestBundleToken {}

/// A throwaway shared-defaults suite, removed when the test ends.
struct ProTestSuite {
    let name = "ProAccessTests.\(UUID().uuidString)"

    var defaults: UserDefaults { UserDefaults(suiteName: name) ?? .standard }

    func remove() { defaults.removePersistentDomain(forName: name) }
}

/*--------------------------------access-tests--------------------------------*/

@Suite("ProAccess Tests")
struct ProAccessTests {
    @Test("Every Pro feature is locked until Pro unlocks")
    func featuresFollowAccess() {
        #expect(ProFeature.allCases == [.lockScreenWidgets, .csvExport, .photoLookup, .handwritingSearch])
        for feature in ProFeature.allCases {
            #expect(!ProAccess.locked.allows(feature))
            #expect(ProAccess.purchased.allows(feature))
            #expect(ProAccess(isDevUnlocked: true).allows(feature))
        }
    }

    @Test("Only a verified, unrevoked Pro entitlement counts as purchased")
    func resolverRule() {
        let pro = TestPurchaseSource.pro
        #expect(ProEntitlementResolver.isPurchased([pro]))
        #expect(!ProEntitlementResolver.isPurchased([]))
        #expect(!ProEntitlementResolver.isPurchased([ProEntitlementRecord(productID: ProProduct.id, isVerified: false, isRevoked: false)]))
        #expect(!ProEntitlementResolver.isPurchased([ProEntitlementRecord(productID: ProProduct.id, isVerified: true, isRevoked: true)]))
        #expect(!ProEntitlementResolver.isPurchased([ProEntitlementRecord(productID: "com.aten.nichiji.other", isVerified: true, isRevoked: false)]))
    }

    @Test("The entitlement cache round-trips and reads missing keys as locked")
    func cacheRoundTrip() {
        let suite = ProTestSuite()
        defer { suite.remove() }

        #expect(ProEntitlementCache.load(from: suite.defaults) == .locked)
        ProEntitlementCache.savePurchased(true, to: suite.defaults)
        #expect(ProEntitlementCache.load(from: suite.defaults) == .purchased)
        ProEntitlementCache.savePurchased(false, to: suite.defaults)
        #expect(ProEntitlementCache.load(from: suite.defaults) == .locked)
    }

    #if DEBUG
    @Test("The dev unlock lives on its own key and survives a refresh with no entitlement")
    func devUnlockSurvivesRefresh() async {
        let suite = ProTestSuite()
        defer { suite.remove() }
        let store = TestPurchaseSource()
        let service = StoreKitPurchaseService(suiteName: suite.name, source: store.source)

        #expect(service.setDevUnlocked(true) == ProAccess(isDevUnlocked: true))
        let access = await service.refreshAccess()
        #expect(access == ProAccess(isPurchased: false, isDevUnlocked: true))
        #expect(access.allows(.csvExport))
        #expect(suite.defaults.object(forKey: ProEntitlementKey.isPurchased.rawValue) as? Bool == false)
        #expect(suite.defaults.bool(forKey: ProEntitlementKey.isDevUnlocked.rawValue))
    }
    #endif

    @Test("The StoreKit configuration defines Nichiji Pro as a family-shareable non-consumable at 4.99")
    func storeKitConfiguration() throws {
        let url = try #require(Bundle(for: ProTestBundleToken.self).url(forResource: "Nichiji", withExtension: "storekit"))
        let json = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
        let products = try #require(json["products"] as? [[String: Any]])
        #expect(products.count == 1)
        let product = try #require(products.first)
        #expect(product["productID"] as? String == ProProduct.id)
        #expect(product["type"] as? String == "NonConsumable")
        #expect(product["familyShareable"] as? Bool == true)
        #expect(product["displayPrice"] as? String == "4.99")
    }
}

/*-------------------------------service-tests--------------------------------*/

@Suite("StoreKitPurchaseService Tests")
struct StoreKitPurchaseServiceTests {
    @Test("Refresh caches what StoreKit reports, including a revocation")
    func refreshWritesCache() async {
        let suite = ProTestSuite()
        defer { suite.remove() }
        let store = TestPurchaseSource()
        let service = StoreKitPurchaseService(suiteName: suite.name, source: store.source)

        store.records = [TestPurchaseSource.pro]
        #expect(await service.refreshAccess() == .purchased)
        #expect(service.cachedAccess() == .purchased)

        store.records = [ProEntitlementRecord(productID: ProProduct.id, isVerified: true, isRevoked: true)]
        #expect(await service.refreshAccess() == .locked)
        #expect(ProEntitlementCache.load(from: suite.defaults) == .locked)
    }

    @Test("A failed sync rethrows and leaves the cached purchase in place")
    func failedRestoreKeepsCache() async {
        let suite = ProTestSuite()
        defer { suite.remove() }
        let store = TestPurchaseSource()
        let service = StoreKitPurchaseService(suiteName: suite.name, source: store.source)

        store.records = [TestPurchaseSource.pro]
        _ = await service.refreshAccess()
        store.records = []
        store.syncFails = true

        await #expect(throws: TestPurchaseFailure.self) {
            _ = try await service.restorePurchases()
        }
        #expect(ProEntitlementCache.load(from: suite.defaults) == .purchased)
    }

    @Test("A successful restore refreshes from StoreKit")
    func restoreRefreshes() async throws {
        let suite = ProTestSuite()
        defer { suite.remove() }
        let store = TestPurchaseSource()
        let service = StoreKitPurchaseService(suiteName: suite.name, source: store.source)

        store.records = [TestPurchaseSource.pro]
        #expect(try await service.restorePurchases() == .purchased)
        #expect(service.cachedAccess() == .purchased)
    }

    @Test("Each transaction update yields a refreshed access")
    func updatesYieldRefreshedAccess() async {
        let suite = ProTestSuite()
        defer { suite.remove() }
        let store = TestPurchaseSource()
        let service = StoreKitPurchaseService(suiteName: suite.name, source: store.source)
        var updates = service.accessUpdates().makeAsyncIterator()

        store.records = [TestPurchaseSource.pro]
        store.signalContinuation.yield(())
        #expect(await updates.next() == .purchased)

        store.records = []
        store.signalContinuation.yield(())
        #expect(await updates.next() == .locked)
        #expect(service.cachedAccess() == .locked)
    }
}

/*--------------------------------model-tests---------------------------------*/

@Suite("ProAccessModel Tests")
@MainActor
struct ProAccessModelTests {
    @Test("The model starts from the cache, then applies the refresh and each update")
    func startAppliesCacheRefreshAndUpdates() async {
        let service = TestPurchaseService()
        let refresher = TestWidgetRefresher()
        service.cached = .purchased
        service.refreshed = .purchased
        let model = ProAccessModel(service: service, widgetRefresher: refresher)
        #expect(model.allows(.lockScreenWidgets))

        service.updateContinuation.yield(.locked)
        service.updateContinuation.finish()
        await model.start()

        #expect(model.access == .locked)
        #expect(refresher.reloadCount == 1)
    }

    @Test("A purchase unlocks; pending and cancelled do not")
    func purchaseOutcomes() async throws {
        let service = TestPurchaseService()
        let refresher = TestWidgetRefresher()
        let model = ProAccessModel(service: service, widgetRefresher: refresher)

        service.purchaseResult = .success(.cancelled)
        #expect(try await model.purchase() == .cancelled)
        service.purchaseResult = .success(.pending)
        #expect(try await model.purchase() == .pending)
        #expect(model.access == .locked)
        #expect(refresher.reloadCount == 0)

        service.purchaseResult = .success(.purchased(.purchased))
        try await model.purchase()
        #expect(model.allows(.csvExport))
        #expect(refresher.reloadCount == 1)
    }

    @Test("A throwing purchase or restore leaves access unchanged")
    func failuresChangeNothing() async throws {
        let service = TestPurchaseService()
        let refresher = TestWidgetRefresher()
        service.cached = .purchased
        let model = ProAccessModel(service: service, widgetRefresher: refresher)

        service.purchaseResult = .failure(TestPurchaseFailure())
        service.restoreResult = .failure(TestPurchaseFailure())
        await #expect(throws: TestPurchaseFailure.self) { try await model.purchase() }
        await #expect(throws: TestPurchaseFailure.self) { try await model.restorePurchases() }
        #expect(model.access == .purchased)
        #expect(refresher.reloadCount == 0)

        service.restoreResult = .success(.locked)
        try await model.restorePurchases()
        #expect(model.access == .locked)
        #expect(refresher.reloadCount == 1)

        service.restoreResult = .success(.purchased)
        try await model.restorePurchases()
        #expect(model.allows(.lockScreenWidgets))
        #expect(refresher.reloadCount == 2)
    }

    @Test("Product info passes through for the paywall")
    func productInfoPassesThrough() async throws {
        let model = ProAccessModel(service: TestPurchaseService(), widgetRefresher: TestWidgetRefresher())
        #expect(try await model.productInfo() == ProProductInfo(displayName: "Nichiji Pro", displayPrice: "$4.99"))
    }
}

/*-----------------------------widget-gate-tests------------------------------*/

@Suite("LockScreenWidgetGate Tests")
struct LockScreenWidgetGateTests {
    @Test("Only the lock-screen families lock without Pro")
    func gateLocksAccessoryFamilies() {
        for family in [WidgetFamily.accessoryCircular, .accessoryRectangular, .accessoryInline] {
            #expect(LockScreenWidgetGate.isLocked(family: family, access: .locked))
            #expect(!LockScreenWidgetGate.isLocked(family: family, access: .purchased))
        }
        for family in [WidgetFamily.systemSmall, .systemMedium] {
            #expect(!LockScreenWidgetGate.isLocked(family: family, access: .locked))
        }
    }

    @Test("The locked placeholder copy is pinned")
    func lockedCopy() {
        #expect(AccessoryWidgetCopy.proLocked == "Nichiji Pro")
        #expect(AccessoryWidgetCopy.proLockedDetail == "Tap to unlock")
        #expect(AccessoryWidgetCopy.proLockedInline == "Unlock Nichiji Pro")
        #expect(AccessoryWidgetCopy.proLockedAccessibility == "Lock screen widgets need Nichiji Pro. Tap to unlock it in the app.")
    }

    @Test("Locked lock-screen families open the paywall; every other tap opens Today")
    func tapURLs() {
        for family in [WidgetFamily.accessoryCircular, .accessoryRectangular, .accessoryInline] {
            #expect(LockScreenWidgetGate.url(family: family, access: .locked) == AppDeepLink.pro.url)
            #expect(LockScreenWidgetGate.url(family: family, access: .purchased) == AppDeepLink.today.url)
        }
        for family in [WidgetFamily.systemSmall, .systemMedium] {
            #expect(LockScreenWidgetGate.url(family: family, access: .locked) == AppDeepLink.today.url)
        }
    }

    @Test("The gallery sample shows the unlocked layout")
    func sampleIsUnlocked() {
        #expect(DailyKanjiWidgetEntry.sample.proAccess.allows(.lockScreenWidgets))
    }
}
