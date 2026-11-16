import SwiftUI

@main
struct PhotoLookupApp: App {
    @State private var store = TrialStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
