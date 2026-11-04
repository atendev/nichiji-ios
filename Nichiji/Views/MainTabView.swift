import SwiftUI

/*----------------------------------tabs----------------------------------*/

public struct MainTabView: View {
    @State private var selectedTab: AppTab = .today
    @State private var isSettingsPresented: Bool = false

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
        .sheet(isPresented: $isSettingsPresented) {
            SettingsSheet()
        }
        .onOpenURL { url in
            guard let link = AppDeepLink(url: url) else { return }
            isSettingsPresented = false
            selectedTab = link.tab
        }
    }
}
