import SwiftUI
import WidgetKit

/*---------------------------------bundle-------------------------------------*/

@main
struct NichijiWidgetBundle: WidgetBundle {
    // TODO: Add accessory families in "Build the lock-screen widgets". Configurable widgets wait on "Fix the v1.0 scope".
    var body: some Widget {
        DailyKanjiWidget()
    }
}
