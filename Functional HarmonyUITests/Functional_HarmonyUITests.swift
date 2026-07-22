//
//  Functional_HarmonyUITests.swift
//  Functional HarmonyUITests
//
//  App Store screenshot capture (iPhone 17 Pro Max → 1320×2868).
//

import XCTest

final class Functional_HarmonyUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-functionalHarmony.lastSectionRaw", "0",
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 15)
        Thread.sleep(forTimeInterval: 1.0)
        dismissContinueIfPresent()
    }

    /// Full set used by CI / local regeneration.
    func testCaptureAppStoreScreenshots() throws {
        let dir = shotsDir()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // --- 1. Chords: C Major (collapsed quality) ---
        goToTab("Chords")
        selectRootLetter("C")
        selectOptionChip(primary: "Major")
        collapseCatalogIfNeeded()
        Thread.sleep(forTimeInterval: 0.8)
        try save("01-chords-c-major", to: dir)

        // --- 2. Scales: D Major degrees (collapsed) ---
        goToTab("Scales")
        selectRootLetter("D")
        selectOptionChip(primary: "Major")
        collapseCatalogIfNeeded()
        Thread.sleep(forTimeInterval: 0.8)
        try save("02-scales-d-major", to: dir)

        // --- 3. Notes: identify C–E–G ---
        // Notes pad a11y labels are "Note C", "Note E", … (not bare letters).
        goToTab("Notes")
        Thread.sleep(forTimeInterval: 0.5)
        let clearAll = app.buttons["Clear all notes"]
        if clearAll.exists, clearAll.isHittable, clearAll.isEnabled {
            clearAll.tap()
        }
        for letter in ["C", "E", "G"] {
            let key = app.buttons["Note \(letter)"]
            XCTAssertTrue(key.waitForExistence(timeout: 3), "Missing Note \(letter)")
            key.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }
        Thread.sleep(forTimeInterval: 1.0)
        try save("03-notes-c-e-g", to: dir)

        // --- 4. Ask: natural-language G major 7 ---
        goToTab("Ask")
        dismissContinueIfPresent()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 4))
        field.tap()
        dismissContinueIfPresent()
        // Replace any residual query
        if let val = field.value as? String, !val.isEmpty {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: val.count + 8)
            field.typeText(deleteString)
        }
        field.typeText("G major 7")
        Thread.sleep(forTimeInterval: 1.0)
        // Tap the result banner (top third) to resign keyboard — never the Open Chords button.
        let banner = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18))
        banner.tap()
        Thread.sleep(forTimeInterval: 0.5)
        dismissContinueIfPresent()
        // Stay on Ask
        XCTAssertTrue(app.tabBars.buttons["Ask"].isSelected, "Ask tab should stay selected for shot 04")
        try save("04-ask-gmaj7", to: dir)

        // --- 5. Chords: seventh quality (Major 7 on A) ---
        goToTab("Chords")
        selectRootLetter("A")
        // Expand catalog to pick Major 7 if not already
        if app.buttons["Change"].waitForExistence(timeout: 1), app.buttons["Change"].isHittable {
            // If collapsed showing something else, open catalog
            let changeLabel = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Change'")).firstMatch
            if changeLabel.exists { changeLabel.tap(); Thread.sleep(forTimeInterval: 0.4) }
        }
        if app.buttons["Major 7"].waitForExistence(timeout: 1.5) {
            app.buttons["Major 7"].tap()
        } else if app.staticTexts["Major 7"].exists {
            app.staticTexts["Major 7"].tap()
        } else if app.buttons["MM7"].exists {
            app.buttons["MM7"].tap()
        }
        collapseCatalogIfNeeded()
        // If still expanded, tap Change path once more via selecting Major 7 from common if visible as chip
        Thread.sleep(forTimeInterval: 0.8)
        try save("05-chords-a-maj7", to: dir)
    }

    /// Re-capture only Notes + Ask (after a11y label fix).
    func testCaptureNotesAndAskOnly() throws {
        let dir = shotsDir()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        goToTab("Notes")
        Thread.sleep(forTimeInterval: 0.5)
        for letter in ["C", "E", "G"] {
            let key = app.buttons["Note \(letter)"]
            XCTAssertTrue(key.waitForExistence(timeout: 3), "Missing Note \(letter)")
            key.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }
        Thread.sleep(forTimeInterval: 1.0)
        try save("03-notes-c-e-g", to: dir)

        goToTab("Ask")
        dismissContinueIfPresent()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 4))
        field.tap()
        dismissContinueIfPresent()
        if let val = field.value as? String, !val.isEmpty {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: val.count + 8))
        }
        field.typeText("G major 7")
        Thread.sleep(forTimeInterval: 1.0)
        // Prefer hardware-style keyboard return (blue arrow / Go)
        if app.keyboards.buttons["Go"].exists {
            app.keyboards.buttons["Go"].tap()
        } else if app.keyboards.buttons["return"].exists {
            app.keyboards.buttons["return"].tap()
        } else if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
        } else {
            // Fall back: tap result banner
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
        }
        Thread.sleep(forTimeInterval: 0.6)
        // If keyboard still up, drag it down from above the keys
        if app.keyboards.element.exists {
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.62))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
            start.press(forDuration: 0.05, thenDragTo: end)
            Thread.sleep(forTimeInterval: 0.4)
        }
        XCTAssertTrue(app.tabBars.buttons["Ask"].isSelected)
        try save("04-ask-gmaj7", to: dir)
    }

    // MARK: - Interactions

    private func goToTab(_ name: String) {
        dismissKeyboardSafely()
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Missing tab \(name)")
        tab.tap()
        Thread.sleep(forTimeInterval: 0.7)
    }

    private func selectRootLetter(_ letter: String) {
        // Root pad keys are plain buttons labeled with the letter
        tapNoteKey(letter)
        Thread.sleep(forTimeInterval: 0.2)
    }

    private func selectOptionChip(primary: String) {
        // If already selected (collapsed chip shows name), don't re-tap — that reopens catalog
        let change = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Change'")).firstMatch
        let selectedChip = app.buttons[primary]
        if selectedChip.exists, selectedChip.isHittable {
            // Check if we're in collapsed mode (Change visible nearby)
            if change.exists {
                // Already have a selection showing — only retap if not matching
                let label = selectedChip.label
                if label.localizedCaseInsensitiveContains(primary) {
                    return
                }
            }
            selectedChip.tap()
            return
        }
        // Expand catalog
        if change.exists, change.isHittable {
            change.tap()
            Thread.sleep(forTimeInterval: 0.3)
        }
        if app.buttons[primary].waitForExistence(timeout: 2) {
            app.buttons[primary].tap()
        } else if app.staticTexts[primary].exists {
            app.staticTexts[primary].tap()
        }
    }

    private func collapseCatalogIfNeeded() {
        // "Show Less" / chevron collapses expanded pickers
        if app.buttons["Show Less"].waitForExistence(timeout: 0.5) {
            app.buttons["Show Less"].tap()
            Thread.sleep(forTimeInterval: 0.4)
            return
        }
        // Tapping the selected quality chip again may collapse in this UI
        let change = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Change'")).firstMatch
        // If Change is not visible, catalog is expanded — look for chevron up
        if !change.exists {
            let chevron = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'less' OR identifier CONTAINS[c] 'chevron'")).firstMatch
            if chevron.exists, chevron.isHittable {
                chevron.tap()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }

    private func tapNoteKey(_ letter: String) {
        // Prefer buttons that are not the tab bar
        let pred = NSPredicate(format: "label == %@ AND NOT identifier CONTAINS[c] 'tab'", letter)
        let matches = app.buttons.matching(pred)
        // Prefer the last hittable match (pad is usually after chrome)
        var tapped = false
        let count = matches.count
        if count > 0 {
            for i in stride(from: count - 1, through: 0, by: -1) {
                let el = matches.element(boundBy: i)
                if el.exists, el.isHittable {
                    el.tap()
                    tapped = true
                    break
                }
            }
        }
        if !tapped {
            let fallback = app.buttons[letter]
            if fallback.waitForExistence(timeout: 1), fallback.isHittable {
                fallback.tap()
            }
        }
    }

    private func dismissKeyboardSafely() {
        dismissContinueIfPresent()
        guard app.keyboards.element.exists else { return }
        // Prefer Return / Go on the keyboard only
        for key in ["return", "Return", "Go", "Done", "Search"] {
            let k = app.keyboards.buttons[key]
            if k.exists {
                k.tap()
                Thread.sleep(forTimeInterval: 0.3)
                break
            }
        }
        if app.keyboards.element.exists {
            // Swipe down from upper half — avoid center buttons like Open Chords
            let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
            start.press(forDuration: 0.05, thenDragTo: end)
            Thread.sleep(forTimeInterval: 0.3)
        }
        dismissContinueIfPresent()
    }

    private func dismissContinueIfPresent() {
        if app.buttons["Continue"].waitForExistence(timeout: 0.3) {
            app.buttons["Continue"].tap()
            Thread.sleep(forTimeInterval: 0.2)
        }
    }

    private func shotsDir() -> URL {
        if let override = ProcessInfo.processInfo.environment["APPSTORE_SHOTS_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }
        return URL(fileURLWithPath: "/Users/dps/Developer/chord-solver-ios/screenshots/raw")
    }

    private func save(_ name: String, to dir: URL) throws {
        dismissContinueIfPresent()
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        try shot.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
    }


    /// iPad Pro 13" capture (top segmented tabs, 2064×2752).
    func testCaptureIPadAppStoreScreenshots() throws {
        let dir = URL(fileURLWithPath: "/Users/dps/Developer/chord-solver-ios/screenshots/raw-ipad")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // iPad uses top chrome buttons, not tabBars in the same way
        func go(_ name: String) {
            let candidates = [
                app.tabBars.buttons[name],
                app.buttons[name],
                app.segmentedControls.buttons[name],
            ]
            for c in candidates {
                if c.waitForExistence(timeout: 1), c.isHittable {
                    c.tap()
                    Thread.sleep(forTimeInterval: 0.7)
                    return
                }
            }
            // Last resort predicate
            let any = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", name)).element(boundBy: 0)
            if any.waitForExistence(timeout: 2) { any.tap(); Thread.sleep(forTimeInterval: 0.7) }
        }

        // 1. Chords C Major
        go("Chords")
        selectRootLetter("C")
        selectOptionChip(primary: "Major")
        collapseCatalogIfNeeded()
        Thread.sleep(forTimeInterval: 0.8)
        try save("01-chords-c-major", to: dir)

        // 2. Scales D Major
        go("Scales")
        selectRootLetter("D")
        selectOptionChip(primary: "Major")
        collapseCatalogIfNeeded()
        Thread.sleep(forTimeInterval: 0.8)
        try save("02-scales-d-major", to: dir)

        // 3. Notes C E G
        go("Notes")
        Thread.sleep(forTimeInterval: 0.4)
        for letter in ["C", "E", "G"] {
            let key = app.buttons["Note \(letter)"]
            if key.waitForExistence(timeout: 2) { key.tap() }
            Thread.sleep(forTimeInterval: 0.25)
        }
        Thread.sleep(forTimeInterval: 1.0)
        try save("03-notes-c-e-g", to: dir)

        // 4. Ask
        go("Ask")
        dismissContinueIfPresent()
        let field = app.textFields.firstMatch
        if field.waitForExistence(timeout: 4) {
            field.tap()
            dismissContinueIfPresent()
            field.typeText("G major 7")
            Thread.sleep(forTimeInterval: 1.0)
            // Tap result area to dismiss keyboard without Open Chords
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
            Thread.sleep(forTimeInterval: 0.5)
        }
        try save("04-ask-gmaj7", to: dir)

        // 5. Chords A Major 7
        go("Chords")
        selectRootLetter("A")
        if app.buttons["Change"].waitForExistence(timeout: 1) {
            // may already be collapsed
        }
        // Open catalog if needed and pick Major 7
        let change = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Change'")).firstMatch
        if change.exists, change.isHittable { change.tap(); Thread.sleep(forTimeInterval: 0.3) }
        if app.buttons["Major 7"].waitForExistence(timeout: 1.5) {
            app.buttons["Major 7"].tap()
        } else if app.staticTexts["Major 7"].exists {
            app.staticTexts["Major 7"].tap()
        }
        collapseCatalogIfNeeded()
        Thread.sleep(forTimeInterval: 0.8)
        try save("05-chords-a-maj7", to: dir)
    }

}
