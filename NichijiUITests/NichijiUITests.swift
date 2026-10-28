import XCTest

final class NichijiUITests: XCTestCase {
    @MainActor
    func testLaunchShowsTitle() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["title"].waitForExistence(timeout: 5))
    }
}
