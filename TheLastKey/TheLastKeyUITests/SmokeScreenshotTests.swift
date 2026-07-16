import XCTest

/// Walks the main flows (Today → session → reveal → grade, Library, add sheet,
/// Settings) and attaches a screenshot at each step. Export them with:
/// `xcrun xcresulttool export attachments --path <xcresult> --output-path <dir>`
final class SmokeScreenshotTests: XCTestCase {

    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testWalkMainFlows() throws {
        let app = XCUIApplication()
        app.launch()

        // Today
        let start = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Start today'")
        ).firstMatch
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Start button missing on Today")
        snap(app, "01-today")

        // Parse the session size out of the button label ("… · N cards").
        let sessionSize = start.label
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
            .first ?? 0
        XCTAssertGreaterThan(sessionSize, 0, "Could not parse session size from start button")

        // Session: first card, cued
        start.tap()
        let reveal = app.buttons["Reveal"]
        XCTAssertTrue(reveal.waitForExistence(timeout: 5), "Reveal button missing on card")
        snap(app, "02-card-cued")

        // Revealed card
        reveal.tap()
        let gotIt = app.buttons["Got it"]
        XCTAssertTrue(gotIt.waitForExistence(timeout: 5), "Got it button missing after reveal")
        snap(app, "03-card-revealed")

        // Grade one card as "Review again", then "Got it" through the rest.
        app.buttons["Review again"].tap()
        var laterReveals = 0
        var safety = 40
        while safety > 0 {
            safety -= 1
            if app.buttons["Reveal"].waitForExistence(timeout: 2) {
                laterReveals += 1
                app.buttons["Reveal"].tap()
                XCTAssertTrue(app.buttons["Got it"].waitForExistence(timeout: 5))
                app.buttons["Got it"].tap()
            } else {
                break
            }
        }
        // N-1 remaining cards + the one re-queued by "Review again".
        XCTAssertEqual(laterReveals, sessionSize,
                       "Missed card was not re-queued into today's session")
        let done = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'see you tomorrow'")
        ).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Completion screen missing")
        snap(app, "04-session-done")
        app.buttons["Close"].tap()

        // Library
        app.tabBars.buttons["Library"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        snap(app, "05-library")

        // Add-entry sheet
        let add = app.navigationBars["Library"].buttons.firstMatch
        add.tap()
        XCTAssertTrue(app.navigationBars["New entry"].waitForExistence(timeout: 5), "Add sheet missing")
        snap(app, "06-entry-new")
        app.buttons["Cancel"].tap()

        // Settings
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        snap(app, "07-settings")

        // Back to Today (now shows last-reviewed caption)
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        snap(app, "08-today-after-session")
    }

    /// Runs after testWalkMainFlows (alphabetical order). Empties the library,
    /// checks the Today empty-state CTA jumps to the add sheet, and re-adds
    /// one entry so later runs still have a session to practice.
    func testZEmptyLibraryCTA() throws {
        let app = XCUIApplication()
        app.launch()

        // Delete every entry.
        app.tabBars.buttons["Library"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        var safety = 40
        while app.cells.count > 0 && safety > 0 {
            safety -= 1
            app.cells.firstMatch.swipeLeft()
            let delete = app.buttons["Delete"]
            if delete.waitForExistence(timeout: 2) {
                delete.tap()
            }
        }
        XCTAssertEqual(app.cells.count, 0, "Library should be empty")
        snap(app, "09-library-empty")

        // Today's empty-state CTA should open the add sheet on the Library tab.
        app.tabBars.buttons["Today"].tap()
        let cta = app.buttons["Add your first sentence"]
        XCTAssertTrue(cta.waitForExistence(timeout: 5), "Empty-state CTA missing on Today")
        snap(app, "10-today-empty")
        cta.tap()
        XCTAssertTrue(app.navigationBars["New entry"].waitForExistence(timeout: 5),
                      "CTA did not open the add sheet")

        // The sentence field is auto-focused; type straight into it.
        app.typeText("This app looks lovely now.")
        let meaningField = app.descendants(matching: .any).matching(
            NSPredicate(format: "placeholderValue BEGINSWITH 'e.g. 어려운'")
        ).firstMatch
        XCTAssertTrue(meaningField.waitForExistence(timeout: 5), "Meaning field missing")
        meaningField.tap()
        app.typeText("test meaning")
        snap(app, "11-entry-filled")

        let save = app.buttons["Save"]
        XCTAssertTrue(save.isEnabled, "Save should be enabled once both fields are filled")
        save.tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.cells.count, 1, "New entry should appear in the library")
    }
}
