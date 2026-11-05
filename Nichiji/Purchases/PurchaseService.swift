import Foundation
import StoreKit

/*-----------------------------------types------------------------------------*/

/// The Pro product's StoreKit name and localized price, for the paywall.
struct ProProductInfo: Equatable, Sendable {
    let displayName: String
    let displayPrice: String
}

enum PurchaseOutcome: Equatable, Sendable {
    case purchased(ProAccess)
    /// Waiting on Ask to Buy or a payment step; the update stream reports the result.
    case pending
    case cancelled
}

enum PurchaseError: Error, Equatable, Sendable {
    /// StoreKit returned no product for `ProProduct.id`.
    case productUnavailable
    /// StoreKit could not verify the transaction's signature, so it never unlocks.
    case unverified
}

/*----------------------------------protocol----------------------------------*/

/// Buys, restores and reports the Pro unlock. Only `refreshAccess()` writes the entitlement cache.
protocol PurchaseService: Sendable {
    /// The App Group cache, readable offline and before StoreKit answers.
    func cachedAccess() -> ProAccess
    /// Reads the device's StoreKit entitlements, caches the result and returns it.
    func refreshAccess() async -> ProAccess
    func productInfo() async throws -> ProProductInfo
    func purchase() async throws -> PurchaseOutcome
    /// Syncs with the App Store, then refreshes. A failed sync throws and leaves the cache as it was.
    func restorePurchases() async throws -> ProAccess
    /// A refreshed access after every transaction update: other devices, Ask to Buy, refunds.
    func accessUpdates() -> AsyncStream<ProAccess>
    #if DEBUG
    func setDevUnlocked(_ isOn: Bool) -> ProAccess
    #endif
}

/*-----------------------------------source-----------------------------------*/

/// The StoreKit calls behind refresh, restore and updates, swappable so tests run without StoreKit.
struct PurchaseSource: Sendable {
    var entitlements: @Sendable () async -> [ProEntitlementRecord]
    var sync: @Sendable () async throws -> Void
    /// One signal per transaction update, after any verified transaction is finished.
    var updates: @Sendable () -> AsyncStream<Void>

    static let storeKit = PurchaseSource(
        entitlements: {
            var records: [ProEntitlementRecord] = []
            for await result in StoreKit.Transaction.currentEntitlements {
                records.append(ProEntitlementRecord(result))
            }
            return records
        },
        sync: {
            try await AppStore.sync()
        },
        updates: {
            AsyncStream { continuation in
                let task = Task {
                    for await result in StoreKit.Transaction.updates {
                        if case .verified(let transaction) = result {
                            await transaction.finish()
                        }
                        continuation.yield(())
                    }
                    continuation.finish()
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    )
}

extension ProEntitlementRecord {
    init(_ result: VerificationResult<StoreKit.Transaction>) {
        switch result {
        case .verified(let transaction):
            self.init(productID: transaction.productID, isVerified: true, isRevoked: transaction.revocationDate != nil)
        case .unverified(let transaction, _):
            self.init(productID: transaction.productID, isVerified: false, isRevoked: transaction.revocationDate != nil)
        }
    }
}

/*----------------------------------storekit----------------------------------*/

/// StoreKit 2 purchase service for the single Pro non-consumable. No server and no third-party SDK.
struct StoreKitPurchaseService: PurchaseService {
    /// The App Group suite by default; tests pass a throwaway suite name.
    let suiteName: String?
    let source: PurchaseSource

    init(suiteName: String? = AppStorageGroup.suiteName, source: PurchaseSource = .storeKit) {
        self.suiteName = suiteName
        self.source = source
    }

    func cachedAccess() -> ProAccess {
        ProEntitlementCache.load(from: defaults())
    }

    func refreshAccess() async -> ProAccess {
        let isPurchased = ProEntitlementResolver.isPurchased(await source.entitlements())
        ProEntitlementCache.savePurchased(isPurchased, to: defaults())
        return cachedAccess()
    }

    func productInfo() async throws -> ProProductInfo {
        let product = try await loadProduct()
        return ProProductInfo(displayName: product.displayName, displayPrice: product.displayPrice)
    }

    func purchase() async throws -> PurchaseOutcome {
        let product = try await loadProduct()
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else { throw PurchaseError.unverified }
            await transaction.finish()
            return .purchased(await refreshAccess())
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    func restorePurchases() async throws -> ProAccess {
        try await source.sync()
        return await refreshAccess()
    }

    func accessUpdates() -> AsyncStream<ProAccess> {
        let signals = source.updates()
        return AsyncStream { continuation in
            let task = Task {
                for await _ in signals {
                    continuation.yield(await refreshAccess())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    #if DEBUG
    func setDevUnlocked(_ isOn: Bool) -> ProAccess {
        ProEntitlementCache.setDevUnlocked(isOn, in: defaults())
        return cachedAccess()
    }
    #endif

    private func loadProduct() async throws -> Product {
        guard let product = try await Product.products(for: [ProProduct.id]).first else {
            throw PurchaseError.productUnavailable
        }
        return product
    }

    /// Built per call because `UserDefaults` is not `Sendable`.
    private func defaults() -> UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }
}
