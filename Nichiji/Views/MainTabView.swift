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

            PlaceholderTabView(kanjiTitle: "辞書", englishTitle: "Dictionary", systemImage: "book") {
                isSettingsPresented = true
            }
            .tabItem {
                Label("Dictionary", systemImage: "book")
            }
            .tag(AppTab.dictionary)

            ReviewView(onOpenSettings: { isSettingsPresented = true })
                .tabItem {
                    Label("Review", systemImage: "rectangle.stack")
                }
                .tag(AppTab.review)

            PlaceholderTabView(kanjiTitle: "私", englishTitle: "You", systemImage: "person") {
                isSettingsPresented = true
            }
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

/*------------------------------placeholder-------------------------------*/

struct PlaceholderTabView: View {
    let kanjiTitle: String
    let englishTitle: String
    let systemImage: String
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: LayoutTokens.space16) {
            HeaderBar(kanjiTitle: kanjiTitle, englishTitle: englishTitle) {
                Button(action: onOpenSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.nichijiInk)
                        .frame(width: LayoutTokens.minHitTarget, height: LayoutTokens.minHitTarget)
                }
            }

            Spacer()

            VStack(spacing: LayoutTokens.space8) {
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundColor(.nichijiInkSubtle)

                Text("\(englishTitle) will be available in a future update.")
                    .font(.nichijiCallout)
                    .foregroundColor(.nichijiInkMuted)
            }

            Spacer()
        }
        .background(Color.nichijiSurface.ignoresSafeArea())
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Replace the placeholders in "Build kanji detail and the Dictionary browse grid", "Build Dictionary search" and "Build the You tab".
