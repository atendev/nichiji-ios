import Foundation
import Observation

/*-----------------------------------types------------------------------------*/

extension ProFeature: Identifiable {
    public var id: String { rawValue }
}

extension AppDeepLink {
    /// The feature whose paywall this link opens, or nil when it opens none or Pro is already unlocked.
    func paywallFeature(access: ProAccess) -> ProFeature? {
        switch self {
        case .today: nil
        case .pro: access.allows(.lockScreenWidgets) ? nil : .lockScreenWidgets
        }
    }
}

enum PaywallPhase: Equatable, Sendable {
    case loading
    case ready
    /// The product did not load, so the primary button retries instead of buying.
    case unavailable
    case purchasing
    case restoring
}

/// A note shown under the paywall or Settings buttons after an action.
enum PaywallMessage: Equatable, Sendable {
    case pending
    case productUnavailable
    case unverified
    case purchaseFailed
    case restored
    case nothingToRestore
    case restoreFailed

    init(purchaseError error: any Error) {
        switch error as? PurchaseError {
        case .productUnavailable: self = .productUnavailable
        case .unverified: self = .unverified
        case nil: self = .purchaseFailed
        }
    }
}

/*-----------------------------------copy-------------------------------------*/

enum PaywallCopy {
    static let title = "Nichiji Pro"
    static let oneTime = "One purchase, no subscription."
    static let freeNote = "Today, Review, Practice, the Dictionary and the You tab stay free."
    static let familySharing = "Family Sharing is on, so your family group gets Pro too."
    static let notNow = "Not now"
    static let restore = "Restore purchases"
    static let restoring = "Restoring…"
    static let unavailable = "Nichiji Pro isn't available right now."

    /// The requested feature first, then the rest in their usual order.
    static func features(leading feature: ProFeature) -> [ProFeature] {
        [feature] + ProFeature.allCases.filter { $0 != feature }
    }

    static func reason(for feature: ProFeature) -> String {
        switch feature {
        case .lockScreenWidgets: "Lock screen widgets need Nichiji Pro."
        case .csvExport: "History export needs Nichiji Pro."
        case .photoLookup: "Photo lookup needs Nichiji Pro."
        case .handwritingSearch: "Handwriting search needs Nichiji Pro."
        }
    }

    static func name(for feature: ProFeature) -> String {
        switch feature {
        case .lockScreenWidgets: "Lock screen widgets"
        case .csvExport: "History export"
        case .photoLookup: "Photo lookup"
        case .handwritingSearch: "Handwriting search"
        }
    }

    static func detail(for feature: ProFeature) -> String {
        switch feature {
        case .lockScreenWidgets: "Today's kanji on your lock screen."
        case .csvExport: "Save your study history as a CSV file."
        case .photoLookup: "Point the camera at a sign to look up its kanji."
        case .handwritingSearch: "Draw a kanji to find it in the Dictionary."
        }
    }

    static func symbol(for feature: ProFeature) -> String {
        switch feature {
        case .lockScreenWidgets: "lock.iphone"
        case .csvExport: "square.and.arrow.down"
        case .photoLookup: "camera.viewfinder"
        case .handwritingSearch: "pencil.and.scribble"
        }
    }

    static func primaryTitle(product: ProProductInfo?, phase: PaywallPhase) -> String {
        switch phase {
        case .purchasing: "Unlocking…"
        case .unavailable: "Try again"
        case .loading, .ready, .restoring: product.map { "Unlock for \($0.displayPrice)" } ?? "Unlock Nichiji Pro"
        }
    }

    static func text(for message: PaywallMessage) -> String {
        switch message {
        case .pending: "Waiting for approval. Pro unlocks once the purchase goes through."
        case .productUnavailable: "Nichiji Pro isn't available right now. Check your connection and try again."
        case .unverified: "The App Store couldn't verify this purchase, so Pro stays locked. Try again or restore purchases."
        case .purchaseFailed: "The purchase didn't go through. Try again."
        case .restored: "Nichiji Pro restored."
        case .nothingToRestore: "No Nichiji Pro purchase found for this Apple Account."
        case .restoreFailed: "Couldn't reach the App Store to restore. Try again."
        }
    }
}

/*----------------------------------restore-----------------------------------*/

/// Shared by the paywall and Settings. Only a real purchase counts as restored, not the dev unlock.
enum ProRestore {
    @MainActor
    static func run(_ access: ProAccessModel) async -> PaywallMessage {
        do {
            try await access.restorePurchases()
            return access.access.isPurchased ? .restored : .nothingToRestore
        } catch {
            return .restoreFailed
        }
    }
}

/*-----------------------------------model------------------------------------*/

/// The paywall's state. A purchase that unlocks shows up in `isUnlocked`, which closes the sheet.
@MainActor
@Observable
final class PaywallModel {
    let feature: ProFeature
    private(set) var product: ProProductInfo?
    private(set) var phase: PaywallPhase = .loading
    private(set) var message: PaywallMessage?

    private let access: ProAccessModel

    init(feature: ProFeature, access: ProAccessModel) {
        self.feature = feature
        self.access = access
    }

    var isUnlocked: Bool {
        access.access.isUnlocked
    }

    var isPrimaryEnabled: Bool {
        phase == .ready || phase == .unavailable
    }

    var isRestoreEnabled: Bool {
        phase == .ready || phase == .unavailable
    }

    var primaryTitle: String {
        PaywallCopy.primaryTitle(product: product, phase: phase)
    }

    func load() async {
        phase = .loading
        do {
            product = try await access.productInfo()
            phase = .ready
            if message == .productUnavailable { message = nil }
        } catch {
            phase = .unavailable
            message = .productUnavailable
        }
    }

    func primaryTapped() async {
        switch phase {
        case .ready: await buy()
        case .unavailable: await load()
        case .loading, .purchasing, .restoring: break
        }
    }

    func restore() async {
        guard isRestoreEnabled else { return }
        let resumePhase = phase
        phase = .restoring
        message = nil
        message = await ProRestore.run(access)
        phase = resumePhase
    }

    private func buy() async {
        phase = .purchasing
        message = nil
        do {
            if try await access.purchase() == .pending {
                message = .pending
            }
        } catch {
            message = PaywallMessage(purchaseError: error)
        }
        phase = .ready
    }
}
