import Foundation

/*-----------------------------------enums------------------------------------*/

/// The features "Nichiji Pro" unlocks. Anything not listed here is free.
public enum ProFeature: String, CaseIterable, Sendable {
    case lockScreenWidgets
    case csvExport
    case photoLookup
    case handwritingSearch
}

/// The one Pro product, a non-consumable with Family Sharing on.
public enum ProProduct {
    public static let id = "com.aten.nichiji.pro"
}

/// Shared UserDefaults keys for the cached Pro entitlement.
public enum ProEntitlementKey: String, Sendable {
    case isPurchased = "proIsPurchased"
    /// Debug-only override. Release builds never read it.
    case isDevUnlocked = "proIsDevUnlocked"
}

/*----------------------------------structs-----------------------------------*/

/// Whether Pro is unlocked on this device, from a purchase or the Debug dev unlock.
public struct ProAccess: Equatable, Sendable {
    public var isPurchased: Bool
    public var isDevUnlocked: Bool

    public init(isPurchased: Bool = false, isDevUnlocked: Bool = false) {
        self.isPurchased = isPurchased
        self.isDevUnlocked = isDevUnlocked
    }

    public static let locked = ProAccess()
    public static let purchased = ProAccess(isPurchased: true)

    public var isUnlocked: Bool {
        isPurchased || isDevUnlocked
    }

    /// Every `ProFeature` needs Pro, so this is `isUnlocked` named per call site.
    public func allows(_ feature: ProFeature) -> Bool {
        isUnlocked
    }
}

/// One StoreKit entitlement, reduced to what the unlock rule reads.
public struct ProEntitlementRecord: Equatable, Sendable {
    public let productID: String
    public let isVerified: Bool
    public let isRevoked: Bool

    public init(productID: String, isVerified: Bool, isRevoked: Bool) {
        self.productID = productID
        self.isVerified = isVerified
        self.isRevoked = isRevoked
    }
}

/*-----------------------------------rules------------------------------------*/

/// The unlock rule: a verified, unrevoked Pro entitlement, bought or family shared.
public enum ProEntitlementResolver {
    public static func isPurchased(_ records: [ProEntitlementRecord], productID: String = ProProduct.id) -> Bool {
        records.contains { $0.productID == productID && $0.isVerified && !$0.isRevoked }
    }
}

/// The App Group copy of the entitlement, read by the app at launch and by the widget extension.
public enum ProEntitlementCache {
    public static func load(
        from defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
    ) -> ProAccess {
        let isPurchased = defaults.bool(forKey: ProEntitlementKey.isPurchased.rawValue)
        #if DEBUG
        let isDevUnlocked = defaults.bool(forKey: ProEntitlementKey.isDevUnlocked.rawValue)
        #else
        let isDevUnlocked = false
        #endif
        return ProAccess(isPurchased: isPurchased, isDevUnlocked: isDevUnlocked)
    }

    /// Writes only the purchased flag, so a refresh never clears the dev unlock.
    public static func savePurchased(
        _ isPurchased: Bool,
        to defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
    ) {
        defaults.set(isPurchased, forKey: ProEntitlementKey.isPurchased.rawValue)
    }

    #if DEBUG
    public static func setDevUnlocked(
        _ isOn: Bool,
        in defaults: UserDefaults = UserDefaults(suiteName: AppStorageGroup.suiteName) ?? .standard
    ) {
        defaults.set(isOn, forKey: ProEntitlementKey.isDevUnlocked.rawValue)
    }
    #endif
}
