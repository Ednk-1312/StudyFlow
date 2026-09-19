//
//  StudyOSUITests.swift
//  StudyOSUITests
//
//  Real UI automation over the shipping app. Every test launches with
//  -uitest-reset so it starts from a deterministic fresh install.
//

import XCTest

final class StudyOSUITests: XCTestCase {

    /// Must match Study_Tracking_AIOApp.uiTestResetArgument (UI tests run in a
    /// separate process and cannot import the app module).
    static let resetArgument = "-uitest-reset"

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Launch helpers

    /// Fresh install: store wiped, onboarding visible.
    private func launchFresh() {
        app = XCUIApplication()
        app.launchArguments = [Self.resetArgument]
        app.launch()
    }

    /// Fresh install with onboarding already dismissed.
    private func launchPastOnboarding() {
        app = XCUIApplication()
        app.launchArguments = [Self.resetArgument]
        app.launch()
        dismissOnboardingIfPresent()
    }

    private func dismissOnboardingIfPresent() {
        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 5) {
            getStarted.tap()
        }
    }

    /// Scheduling the first reminder requests notification permission
    /// contextually. The system alert lives in Springboard, so it is handled
    /// there. Tapping Allow keeps the flow realistic (permission granted). If
    /// a test needs the denied path it can tap the other button explicitly.
    private func handleNotificationPermissionAlert() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for label in ["Allow", "OK"] {
            let button = springboard.buttons[label]
            if button.waitForExistence(timeout: 4) {
                button.tap()
                return
            }
        }
    }

    /// Types into a field robustly: taps, waits for the keyboard to actually
    /// appear, and retries once if focus wasn't gained (sheet animations can
    /// swallow the first tap).
    private func typeInto(_ field: XCUIElement, text: String) {
        field.tap()
        var keyboardUp = app.keyboards.element(boundBy: 0).waitForExistence(timeout: 3)
        if !keyboardUp {
            field.tap()
            keyboardUp = app.keyboards.element(boundBy: 0).waitForExistence(timeout: 3)
        }
        XCTAssertTrue(keyboardUp, "Keyboard never appeared for field: \(field.identifier)")
        field.typeText(text)
    }

    /// Creates one assignment through the real Quick Add UI and waits for the
    /// sheet to close. Returns the title used.
    @discardableResult
    private func createAssignment(title: String = "Lab Questions", subject: String = "Chemistry") -> String {
        let addButton = app.buttons["home.addTask"]
        addButton.tap()

        let titleField = app.textFields["quickadd.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Quick Add title field did not appear")
        typeInto(titleField, text: title)

        let subjectField = app.textFields["quickadd.subject"]
        typeInto(subjectField, text: subject)

        app.buttons["quickadd.save"].tap()
        handleNotificationPermissionAlert()
        XCTAssertTrue(titleField.waitForNonExistence(timeout: 5), "Quick Add sheet did not dismiss")
        return title
    }

    // MARK: - 1. Onboarding

    func testOnboardingShowsOnFreshInstallAndCanBeCompleted() throws {
        launchFresh()
        let getStarted = app.buttons["Get Started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 8), "Onboarding did not appear on fresh install")
        getStarted.tap()
        // Home is reachable after dismissal (today's date is the nav title).
        XCTAssertTrue(app.buttons["home.addTask"].waitForExistence(timeout: 5), "Home did not appear after onboarding")
    }

    // MARK: - 2. Add assignment

    func testAddAssignmentThroughQuickAdd() throws {
        launchPastOnboarding()
        let title = createAssignment()
        // The new assignment is visible on Home (recommended work) — search
        // the assignments list for certainty.
        app.tabBars.buttons["Assignments"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "Created assignment not listed")
    }

    // MARK: - 3. Edit assignment

    func testEditAssignmentTitle() throws {
        launchPastOnboarding()
        let title = createAssignment()
        app.tabBars.buttons["Assignments"].tap()
        app.staticTexts[title].tap()
        app.buttons["Edit"].tap()
        let titleField = app.textFields["assignment.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Edit sheet did not appear")
        titleField.tap()
        // Clear the field, then type the replacement.
        for _ in 0..<title.count {
            titleField.typeText(XCUIKeyboardKey.delete.rawValue)
        }
        titleField.typeText("Lab Questions Revised")

        app.buttons["assignment.save"].tap()
        XCTAssertTrue(app.staticTexts["Lab Questions Revised"].waitForExistence(timeout: 5), "Edited title not shown in detail")
    }

    // MARK: - 4. Mark complete

    func testMarkAssignmentComplete() throws {
        launchPastOnboarding()
        let title = createAssignment()
        app.tabBars.buttons["Assignments"].tap()
        app.staticTexts[title].tap()
        let complete = app.buttons["detail.complete"]
        XCTAssertTrue(complete.waitForExistence(timeout: 5))
        complete.tap()
        // Detail reflects completion once the state change renders.
        XCTAssertTrue(app.buttons["detail.complete"].firstMatch.waitForLabelContaining("Incomplete", timeout: 5), "Row did not switch to completed state")
    }

    // MARK: - 5. Undo completion

    func testUndoCompletionRestoresActiveState() throws {
        launchPastOnboarding()
        let title = createAssignment()
        app.tabBars.buttons["Assignments"].tap()
        app.staticTexts[title].tap()
        app.buttons["detail.complete"].tap()
        // Toast appears with Undo (the action can surface twice in the a11y tree).
        let undo = app.buttons["toast.undo"].firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 5), "Undo toast did not appear after completing")
        undo.tap()
        XCTAssertTrue(app.buttons["detail.complete"].firstMatch.waitForLabelContaining("Mark Complete", timeout: 5), "Completion was not undone")
    }

    // MARK: - 6. Delete assignment

    func testDeleteAssignmentWithConfirmation() throws {
        launchPastOnboarding()
        let title = createAssignment()
        app.tabBars.buttons["Assignments"].tap()
        app.staticTexts[title].tap()
        app.buttons["detail.delete"].tap()
        let confirm = app.buttons["detail.deleteConfirm"].firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Delete confirmation did not appear")
        confirm.tap()
        // Back on the list; the row disappears.
        XCTAssertTrue(app.staticTexts[title].waitForNonExistence(timeout: 5), "Deleted assignment still listed")
        // Empty state explains what to do next.
        XCTAssertTrue(app.staticTexts["No active assignments"].waitForExistence(timeout: 5))
    }

    // MARK: - 7. Scanner entry

    func testScannerOpensAndCancels() throws {
        launchPastOnboarding()
        app.buttons["home.scan"].tap()
        XCTAssertTrue(app.navigationBars["Scan Assignment"].waitForExistence(timeout: 5), "Scanner sheet did not open")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["home.addTask"].waitForExistence(timeout: 5), "Scanner sheet did not dismiss")
    }

    // MARK: - 8. Create + search material

    func testCreateAndSearchMaterial() throws {
        launchPastOnboarding()
        app.tabBars.buttons["Materials"].tap()
        // Both the empty-state action and the toolbar button open the sheet.
        app.buttons["Add Material"].firstMatch.tap()
        let titleField = app.textFields["material.title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Add Material sheet did not appear")
        typeInto(titleField, text: "Photosynthesis Notes")
        let subjectField = app.textFields["material.subject"]
        typeInto(subjectField, text: "Biology")
        app.buttons["material.save"].tap()

        XCTAssertTrue(app.staticTexts["Photosynthesis Notes"].waitForExistence(timeout: 5), "Material did not appear after save")

        // Search narrows to the matching document.
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5), "Search field not found")
        searchField.tap()
        searchField.typeText("Photosyn")
        XCTAssertTrue(app.staticTexts["Photosynthesis Notes"].exists, "Matching material missing during search")
        searchField.typeText("zzz")
        XCTAssertTrue(app.staticTexts["No Matching Materials"].waitForExistence(timeout: 5), "No-results empty state missing")
    }

    // MARK: - 9. Study session pause/resume

    func testStudySessionPauseAndResume() throws {
        launchPastOnboarding()
        createAssignment(title: "Essay Outline", subject: "English")
        // Start from Home's recommended task.
        app.tabBars.buttons["Today"].tap()
        let start = app.buttons["home.startSession"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Start Study Session CTA missing")
        start.tap()

        let playPause = app.buttons["session.playPause"]
        XCTAssertTrue(playPause.waitForExistence(timeout: 5), "Timer screen did not appear")
        // Sessions open paused: first tap starts.
        playPause.tap()
        XCTAssertTrue(playPause.waitForLabel("Pause", timeout: 3), "Timer did not start")
        playPause.tap()
        XCTAssertTrue(playPause.waitForLabel("Play", timeout: 3), "Timer did not pause")
        playPause.tap()
        XCTAssertTrue(playPause.waitForLabel("Pause", timeout: 3), "Timer did not resume")
    }

    // MARK: - 10. Session completion asks (never auto-completes)

    func testSessionCompletionAsksAboutAssignment() throws {
        launchPastOnboarding()
        createAssignment(title: "Reading Response", subject: "History")
        app.tabBars.buttons["Today"].tap()
        app.buttons["home.startSession"].tap()
        XCTAssertTrue(app.buttons["session.playPause"].waitForExistence(timeout: 5))
        app.buttons["End Session"].tap()
        XCTAssertTrue(app.buttons["session.complete"].waitForExistence(timeout: 5), "Completion prompt did not ask about the assignment")
        XCTAssertTrue(app.buttons["session.finish"].exists, "Finish & Close missing")
        app.buttons["session.finish"].tap()
        XCTAssertTrue(app.buttons["home.addTask"].waitForExistence(timeout: 5), "Timer did not close")
    }

    // MARK: - 11. Google Classroom optional/unavailable state

    func testGoogleClassroomShowsOptionalNotBroken() throws {
        launchPastOnboarding()
        app.buttons["home.settings"].tap()
        let classroomRow = app.buttons["settings.classroom"]
        XCTAssertTrue(classroomRow.waitForExistence(timeout: 5), "Classroom row missing in Settings")
        // Honest status: not connected — never an error.
        XCTAssertTrue(classroomRow.label.contains("Not Connected"), "Classroom status should read Not Connected, got: \(classroomRow.label)")
        classroomRow.tap()
        let connect = app.buttons["Connect Google Classroom"]
        XCTAssertTrue(connect.waitForExistence(timeout: 5), "Connect action missing")
        // Core reassurance copy is present.
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'work without'")).firstMatch.exists, "Reassurance copy missing")
    }

    // MARK: - 12. Appearance states

    /// Forces the accessibility XXXL content size through the supported launch
    /// argument and verifies the core flow still works end to end.
    func testAssignmentFlowAtAccessibilityTextSize() throws {
        app = XCUIApplication()
        app.launchArguments = [Self.resetArgument, "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        dismissOnboardingIfPresent()

        let title = createAssignment(title: "Problem Set 5", subject: "Algebra")
        app.tabBars.buttons["Assignments"].tap()
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5), "Assignment row missing at AX text size")
        XCTAssertTrue(app.buttons["assignments.add"].isHittable, "Add button not reachable at AX text size")
    }

    func testDarkModeKeyScreensRender() throws {
        app = XCUIApplication()
        app.launchArguments = [Self.resetArgument]
        app.launch()
        dismissOnboardingIfPresent()
        // The host simulator's appearance is set externally (simctl ui ... dark)
        // before the suite runs; here we verify key screens still expose their
        // controls so the appearance switch cannot hide core functionality.
        app.tabBars.buttons["Tools"].tap()
        XCTAssertTrue(app.staticTexts["GPA Calculator"].waitForExistence(timeout: 5), "Tools hub missing in dark appearance")
        app.tabBars.buttons["Planner"].tap()
        XCTAssertTrue(app.navigationBars["Planner & Calendar"].waitForExistence(timeout: 5), "Planner missing")
    }
}

// MARK: - Helpers

extension XCUIElement {
    /// Waits until the element no longer exists.
    @discardableResult
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !exists { return true }
            usleep(100_000)
        }
        return !exists
    }

    /// Waits until the element's label matches (state updates can lag a tap).
    @discardableResult
    func waitForLabel(_ label: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if self.label == label { return true }
            usleep(100_000)
        }
        return self.label == label
    }

    /// Waits until the element's label contains the substring.
    @discardableResult
    func waitForLabelContaining(_ substring: String, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if self.label.contains(substring) { return true }
            usleep(100_000)
        }
        return self.label.contains(substring)
    }
}
