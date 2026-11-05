import Foundation
@testable import Nichiji

/*-------------------------------test-purchases-------------------------------*/

struct TestPurchaseFailure: Error, Equatable {}

final class TestPurchaseService: PurchaseService, @unchecked Sendable {
    var cached: ProAccess = .locked
    var refreshed: ProAccess = .locked
    var purchaseResult: Result<PurchaseOutcome, TestPurchaseFailure> = .success(.cancelled)
    var restoreResult: Result<ProAccess, TestPurchaseFailure> = .success(.locked)
    var productError: (any Error)?
    let updates: AsyncStream<ProAccess>
    let updateContinuation: AsyncStream<ProAccess>.Continuation

    init() {
        let pair = AsyncStream.makeStream(of: ProAccess.self)
        updates = pair.stream
        updateContinuation = pair.continuation
    }

    func cachedAccess() -> ProAccess { cached }

    func refreshAccess() async -> ProAccess { refreshed }

    func productInfo() async throws -> ProProductInfo {
        if let productError { throw productError }
        return ProProductInfo(displayName: "Nichiji Pro", displayPrice: "$4.99")
    }

    func purchase() async throws -> PurchaseOutcome { try purchaseResult.get() }

    func restorePurchases() async throws -> ProAccess { try restoreResult.get() }

    func accessUpdates() -> AsyncStream<ProAccess> { updates }

    #if DEBUG
    func setDevUnlocked(_ isOn: Bool) -> ProAccess {
        cached.isDevUnlocked = isOn
        return cached
    }
    #endif
}

/// Mutable StoreKit stand-in behind a `PurchaseSource`.
final class TestPurchaseSource: @unchecked Sendable {
    var records: [ProEntitlementRecord] = []
    var syncFails = false
    let signals: AsyncStream<Void>
    let signalContinuation: AsyncStream<Void>.Continuation

    init() {
        let pair = AsyncStream.makeStream(of: Void.self)
        signals = pair.stream
        signalContinuation = pair.continuation
    }

    var source: PurchaseSource {
        PurchaseSource(
            entitlements: { self.records },
            sync: {
                if self.syncFails { throw TestPurchaseFailure() }
            },
            updates: { self.signals }
        )
    }

    static let pro = ProEntitlementRecord(productID: ProProduct.id, isVerified: true, isRevoked: false)
}
