import SwiftUI
import WidgetKit

/*---------------------------------bundle-------------------------------------*/

@main
struct NichijiWidgetBundle: WidgetBundle {
    // TODO: Configurable widgets wait on "Fix the v1.0 scope".
    var body: some Widget {
        DailyKanjiWidget()
    }
}
