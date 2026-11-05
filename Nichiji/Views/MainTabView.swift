import SwiftUI

/*----------------------------------tabs----------------------------------*/

public struct MainTabView: View {
    @State private var selectedTab: AppTab = .today
    @State private var isSettingsPresented: Bool = false
    @State private var paywallFeature: ProFeature?
    /// Held while Settings closes, since one view cannot swap sheets in a single update.
    @State private var pendingPaywallFeature: ProFeature?

    @Environment(ProAccessModel.self) private var proAccess: ProAccessModel?

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(onOpenSettings: { isSettingsPresented = true })
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag(AppTab.today)

            DictionaryView(onOpenSettings: { isSettingsPresented = true })
                .tabItem {
                    Label("Dictionary", systemImage: "book")
                }
                .tag(AppTab.dictionary)

            ReviewView(onOpenSettings: { isSettingsPresented = true })
                .tabItem {
                    Label("Review", systemImage: "rectangle.stack")
                }
                .tag(AppTab.review)

            YouView(onOpenSettings: { isSettingsPresented = true })
                .tabItem {
                    Label("You", systemImage: "person")
                }
                .tag(AppTab.you)
        }
        .tint(Color.nichijiVermilion)
        .sheet(isPresented: $isSettingsPresented, onDismiss: showPendingPaywall) {
            SettingsSheet()
        }
        .paywallSheet(feature: $paywallFeature)
        .onOpenURL { url in
            guard let link = AppDeepLink(url: url) else { return }
            selectedTab = link.tab
            let feature = link.paywallFeature(access: proAccess?.access ?? .locked)
            if isSettingsPresented {
                pendingPaywallFeature = feature
                isSettingsPresented = false
            } else {
                paywallFeature = feature
            }
        }
    }

    private func showPendingPaywall() {
        guard let pendingPaywallFeature else { return }
        paywallFeature = pendingPaywallFeature
        pendingPaywallFeature = nil
    }
}
