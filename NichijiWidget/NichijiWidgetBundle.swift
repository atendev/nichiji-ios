import SwiftUI
import WidgetKit

/*---------------------------------bundle-------------------------------------*/

@main
struct NichijiWidgetBundle: WidgetBundle {
    // TODO: Add lock-screen accessory families and configurable widgets after the MVP.
    var body: some Widget {
        DailyKanjiWidget()
    }
}
