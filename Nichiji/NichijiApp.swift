import SwiftUI
import SwiftData

/*-----------------------------------app----------------------------------*/

@main
struct NichijiApp: App {
    @AppStorage(
        LearnerPreferenceKey.appearanceMode.rawValue,
        store: UserDefaults(suiteName: AppStorageGroup.suiteName)
    )
    private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearanceModeRaw) {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system, .none:
            return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferredColorScheme)
        }
    }
}

/*----------------------------------TODO----------------------------------*/

// TODO: Instantiate shared App Group SwiftData ModelContainer and inject ServiceContainer into environment in Slice 3 and Slice 4.
