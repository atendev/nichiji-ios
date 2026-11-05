import Testing
import Foundation
@testable import Nichiji

/*---------------------------------copy-tests---------------------------------*/

@Suite("PaywallCopy Tests")
struct PaywallCopyTests {
    @Test("The tapped feature leads and every Pro feature is listed once", arguments: ProFeature.allCases)
    func featureOrder(_ feature: ProFeature) {
        let features = PaywallCopy.features(leading: feature)
        #expect(features.first == feature)
        #expect(Set(features) == Set(ProFeature.allCases))
        #expect(features.count == ProFeature.allCases.count)
    }

    @Test("Each feature has its own reason, name and detail")
    func featureCopy() {
        #expect(PaywallCopy.reason(for: .lockScreenWidgets) == "Lock screen widgets need Nichiji Pro.")
        #expect(PaywallCopy.reason(for: .csvExport) == "History export needs Nichiji Pro.")
        for feature in ProFeature.allCases {
            #expect(!PaywallCopy.name(for: feature).isEmpty)
            #expect(!PaywallCopy.detail(for: feature).isEmpty)
        }
    }

    @Test("The primary button shows the price once loaded and retries when unavailable")
    func primaryTitle() {
        let info = ProProductInfo(displayName: "Nichiji Pro", displayPrice: "$4.99")
        #expect(PaywallCopy.primaryTitle(product: nil, phase: .loading) == "Unlock Nichiji Pro")
        #expect(PaywallCopy.primaryTitle(product: info, phase: .ready) == "Unlock for $4.99")
        #expect(PaywallCopy.primaryTitle(product: info, phase: .purchasing) == "Unlocking…")
        #expect(PaywallCopy.primaryTitle(product: nil, phase: .unavailable) == "Try again")
    }

    @Test("Purchase errors map to their own messages")
    func errorMessages() {
        #expect(PaywallMessage(purchaseError: PurchaseError.productUnavailable) == .productUnavailable)
        #expect(PaywallMessage(purchaseError: PurchaseError.unverified) == .unverified)
        #expect(PaywallMessage(purchaseError: TestPurchaseFailure()) == .purchaseFailed)
        let messages: [PaywallMessage] = [.pending, .productUnavailable, .unverified, .purchaseFailed, .restored, .nothingToRestore, .restoreFailed]
        #expect(Set(messages.map(PaywallCopy.text(for:))).count == messages.count)
    }

    @Test("Settings shows purchased, dev unlock and not purchased")
    func settingsStatus() {
        #expect(SettingsProCopy.status(.purchased) == "Unlocked")
        #expect(SettingsProCopy.status(ProAccess(isDevUnlocked: true)) == "Dev unlock")
        #expect(SettingsProCopy.status(.locked) == "Not purchased")
    }
}

/*--------------------------------model-tests---------------------------------*/

@Suite("PaywallModel Tests")
@MainActor
struct PaywallModelTests {
    private func makeModel(_ service: TestPurchaseService, feature: ProFeature = .csvExport) -> PaywallModel {
        PaywallModel(feature: feature, access: ProAccessModel(service: service, widgetRefresher: TestWidgetRefresher()))
    }

    @Test("Loading the product enables buying at its price")
    func loadReady() async {
        let model = makeModel(TestPurchaseService())
        #expect(model.phase == .loading)
        #expect(!model.isPrimaryEnabled)

        await model.load()
        #expect(model.phase == .ready)
        #expect(model.primaryTitle == "Unlock for $4.99")
        #expect(model.isPrimaryEnabled)
        #expect(model.message == nil)
    }

    @Test("A missing product offers a retry that recovers")
    func loadUnavailableThenRetry() async {
        let service = TestPurchaseService()
        service.productError = PurchaseError.productUnavailable
        let model = makeModel(service)

        await model.load()
        #expect(model.phase == .unavailable)
        #expect(model.message == .productUnavailable)
        #expect(model.primaryTitle == "Try again")

        service.productError = nil
        await model.primaryTapped()
        #expect(model.phase == .ready)
        #expect(model.message == nil)
    }

    @Test("A purchase unlocks, which closes the sheet")
    func purchaseUnlocks() async {
        let service = TestPurchaseService()
        service.purchaseResult = .success(.purchased(.purchased))
        let model = makeModel(service)

        await model.load()
        #expect(!model.isUnlocked)
        await model.primaryTapped()
        #expect(model.isUnlocked)
        #expect(model.message == nil)
    }

    @Test("Pending shows the approval note; cancelled shows nothing; both stay locked")
    func pendingAndCancelled() async {
        let service = TestPurchaseService()
        let model = makeModel(service)
        await model.load()

        service.purchaseResult = .success(.pending)
        await model.primaryTapped()
        #expect(model.message == .pending)
        #expect(model.phase == .ready)

        service.purchaseResult = .success(.cancelled)
        await model.primaryTapped()
        #expect(model.message == nil)
        #expect(model.phase == .ready)
        #expect(!model.isUnlocked)
    }

    @Test("A failed purchase shows a message and stays locked")
    func purchaseFails() async {
        let service = TestPurchaseService()
        service.purchaseResult = .failure(TestPurchaseFailure())
        let model = makeModel(service)
        await model.load()

        await model.primaryTapped()
        #expect(model.message == .purchaseFailed)
        #expect(model.phase == .ready)
        #expect(!model.isUnlocked)
    }

    @Test("Restore reports restored, nothing found or a failure")
    func restoreOutcomes() async {
        let service = TestPurchaseService()
        let model = makeModel(service)
        await model.load()

        service.restoreResult = .failure(TestPurchaseFailure())
        await model.restore()
        #expect(model.message == .restoreFailed)
        #expect(model.phase == .ready)

        service.restoreResult = .success(.locked)
        await model.restore()
        #expect(model.message == .nothingToRestore)

        service.restoreResult = .success(.purchased)
        await model.restore()
        #expect(model.message == .restored)
        #expect(model.isUnlocked)
    }

    @Test("Restore waits for the product to finish loading")
    func restoreDisabledWhileLoading() async {
        let service = TestPurchaseService()
        service.restoreResult = .success(.purchased)
        let model = makeModel(service)

        #expect(!model.isRestoreEnabled)
        await model.restore()
        #expect(model.message == nil)
        #expect(!model.isUnlocked)
    }

    #if DEBUG
    @Test("The dev unlock does not count as a restored purchase")
    func devUnlockIsNotRestored() async {
        let service = TestPurchaseService()
        let access = ProAccessModel(service: service, widgetRefresher: TestWidgetRefresher())
        access.setDevUnlocked(true)
        service.restoreResult = .success(ProAccess(isDevUnlocked: true))

        #expect(await ProRestore.run(access) == .nothingToRestore)
    }
    #endif
}

/*-----------------------------deep-link-tests--------------------------------*/

@Suite("Paywall deep link Tests")
struct PaywallDeepLinkTests {
    @Test("Only the pro link opens the paywall, and only while locked")
    func paywallFeature() {
        #expect(AppDeepLink.pro.paywallFeature(access: .locked) == .lockScreenWidgets)
        #expect(AppDeepLink.pro.paywallFeature(access: .purchased) == nil)
        #expect(AppDeepLink.pro.paywallFeature(access: ProAccess(isDevUnlocked: true)) == nil)
        #expect(AppDeepLink.today.paywallFeature(access: .locked) == nil)
    }
}
