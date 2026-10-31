import XCTest

final class NichijiUITests: XCTestCase {
    @MainActor
    func testLaunchShowsPrimaryAction() {
        let app = XCUIApplication()
        app.launch()
        let primaryAction = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'primaryButton' OR label == 'Learned today'"))
            .firstMatch
        XCTAssertTrue(primaryAction.waitForExistence(timeout: 15))
    }
}
