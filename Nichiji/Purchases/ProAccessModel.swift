import Foundation
import Observation

/*-----------------------------------model------------------------------------*/

/// The app's live Pro state. Starts from the cache, confirms with StoreKit at launch, then follows transaction updates.
@MainActor
@Observable
final class ProAccessModel {
    private(set) var access: ProAccess

    private let service: any PurchaseService
    private let widgetRefresher: any WidgetRefresher

    init(service: any PurchaseService, widgetRefresher: any WidgetRefresher) {
        self.service = service
        self.widgetRefresher = widgetRefresher
        self.access = service.cachedAccess()
    }

    func allows(_ feature: ProFeature) -> Bool {
        access.allows(feature)
    }

    /// Restores automatically on launch, then applies every transaction update until the task is cancelled.
    func start() async {
        apply(await service.refreshAccess())
        for await update in service.accessUpdates() {
            apply(update)
        }
    }

    func productInfo() async throws -> ProProductInfo {
        try await service.productInfo()
    }

    /// Pending and cancelled purchases leave access as it was; a throw changes nothing.
    @discardableResult
    func purchase() async throws -> PurchaseOutcome {
        let outcome = try await service.purchase()
        if case .purchased(let newAccess) = outcome {
            apply(newAccess)
        }
        return outcome
    }

    func restorePurchases() async throws {
        apply(try await service.restorePurchases())
    }

    #if DEBUG || DEV_UNLOCK
    func setDevUnlocked(_ isOn: Bool) {
        apply(service.setDevUnlocked(isOn))
    }
    #endif

    /// Lock-screen widgets read the cache, so they reload whenever access changes.
    private func apply(_ newAccess: ProAccess) {
        guard newAccess != access else { return }
        access = newAccess
        widgetRefresher.reloadTimelines()
    }
}
