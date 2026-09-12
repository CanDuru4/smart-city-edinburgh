import XCTest

/// Exercises navigation and failure paths without signing in or writing account data.
final class AppFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let locationAlert = springboard.alerts.firstMatch
        if locationAlert.waitForExistence(timeout: 3) {
            let deny = locationAlert.buttons["Don’t Allow"]
            let alternateDeny = locationAlert.buttons["Don't Allow"]
            if deny.exists { deny.tap() }
            else if alternateDeny.exists { alternateDeny.tap() }
        }
    }

    func testTabsRemainUsableWhenTransitIsUnavailable() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons["stopsStatus"].waitForExistence(timeout: 20))
        app.tabBars.buttons.element(boundBy: 2).tap()
        XCTAssertTrue(app.buttons["scanCardButton"].waitForExistence(timeout: 5))
        recordScreen("Cards")
        if app.buttons["scanCardButton"].isEnabled {
            app.buttons["scanCardButton"].tap()
            XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
            app.alerts.buttons.firstMatch.tap()
        } else {
            XCTAssertTrue(app.staticTexts["Account features are currently unavailable."].exists)
        }
        app.tabBars.buttons.element(boundBy: 3).tap()
        let signIn = app.buttons["accountSignInButton"]
        let unavailable = app.staticTexts["Account features are currently unavailable."]
        XCTAssertTrue(signIn.waitForExistence(timeout: 5) || unavailable.exists)
        recordScreen("Settings")
    }

    func testPasswordResetRequiresTheEmailField() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        app.tabBars.buttons.element(boundBy: 3).tap()
        app.buttons["accountSignInButton"].tap()
        XCTAssertTrue(app.buttons["resetPasswordButton"].waitForExistence(timeout: 5))
        recordScreen("Login")
        let password = app.secureTextFields.firstMatch
        password.tap()
        password.typeText("not-an-email")
        app.buttons["resetPasswordButton"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.alerts.staticTexts["Please enter your email to first field."].exists)
    }

    func testShareSheetOpensFromTheMenu() {
        XCTAssertTrue(app.buttons["openMenuButton"].waitForExistence(timeout: 15))
        app.buttons["openMenuButton"].tap()
        let share = app.cells["menuItem-2"]
        XCTAssertTrue(share.waitForExistence(timeout: 5))
        share.tap()
        XCTAssertTrue(app.collectionViews["activityCollectionView"].cells.matching(NSPredicate(format: "label == %@", "Copy")).firstMatch.waitForExistence(timeout: 10))
        recordScreen("Share sheet")
    }

    func testSignUpRejectsMismatchedPasswordsBeforeCreatingAnAccount() {
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 15))
        app.tabBars.buttons.element(boundBy: 3).tap()
        app.buttons["accountSignInButton"].tap()
        app.buttons["I want to create an account!"].tap()
        XCTAssertTrue(app.buttons["signUpButton"].waitForExistence(timeout: 5))
        recordScreen("Sign up")
        let name = app.textFields["Name"]
        name.tap()
        name.typeText("Example User")
        let email = app.textFields["Email"]
        email.tap()
        email.typeText("example@example.com")
        let password = app.secureTextFields.element(boundBy: 0)
        password.tap()
        password.typeText("Sample123!")
        let confirmation = app.secureTextFields.element(boundBy: 1)
        confirmation.tap()
        confirmation.typeText("Different123!")
        app.buttons["signUpButton"].tap()
        XCTAssertTrue(app.alerts.staticTexts["Passwords do not match!"].waitForExistence(timeout: 5))
    }

    private func recordScreen(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
