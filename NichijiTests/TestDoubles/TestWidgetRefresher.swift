import Foundation
@testable import Nichiji

/*---------------------------test-widgets-------------------------------*/

final class TestWidgetRefresher: WidgetRefresher, @unchecked Sendable {
    var reloadCount = 0

    func reloadTimelines() {
        reloadCount += 1
    }
}
