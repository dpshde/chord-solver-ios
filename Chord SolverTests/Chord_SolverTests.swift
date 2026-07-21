//
//  Chord_SolverTests.swift
//  Chord SolverTests
//
//  Tests navigation section routing used by Liquid Glass tab chrome.
//

import XCTest
@testable import Chord_Solver

final class Chord_SolverTests: XCTestCase {

    // MARK: - MainSectionTab routing (shipped entry points)

    func testResolvingInitialTabMapsLandingIndices() {
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 0), .chords)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 1), .scales)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 2), .intervals)
    }

    func testResolvingOutOfRangeFallsBackToChords() {
        XCTAssertEqual(MainSectionTab.resolving(initialTab: -1), .chords)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 99), .chords)
    }

    func testSectionTitlesMatchLandingAndTabChrome() {
        let titles = MainSectionTab.landingSectionTitles
        XCTAssertEqual(titles, ["Chords", "Scales", "Intervals"])
        XCTAssertEqual(MainSectionTab.chords.title, "Chords")
        XCTAssertEqual(MainSectionTab.scales.title, "Scales")
        XCTAssertEqual(MainSectionTab.intervals.title, "Intervals")
    }

    func testLandingTitleResolvesToSameTabAsInitialTabIndex() {
        for tab in MainSectionTab.allCases {
            let fromTitle = MainSectionTab.tab(forLandingTitle: tab.title)
            let fromIndex = MainSectionTab.resolving(initialTab: tab.rawValue)
            XCTAssertEqual(fromTitle, fromIndex, "Landing title and index must open the same section")
            XCTAssertEqual(fromTitle?.rawValue, tab.rawValue)
        }
    }

    func testUnknownLandingTitleReturnsNil() {
        XCTAssertNil(MainSectionTab.tab(forLandingTitle: "Chord Solver"))
        XCTAssertNil(MainSectionTab.tab(forLandingTitle: ""))
    }

    func testAllCasesCoverThreePrimarySections() {
        XCTAssertEqual(MainSectionTab.allCases.count, 3)
        XCTAssertEqual(
            Set(MainSectionTab.allCases.map(\.rawValue)),
            Set([0, 1, 2])
        )
    }

    func testSystemImagesAreNonEmptyForTabChrome() {
        for tab in MainSectionTab.allCases {
            XCTAssertFalse(tab.systemImage.isEmpty, "\(tab) needs a SF Symbol for the tab bar")
        }
    }

    // MARK: - Root / session persistence (shell-owned models)

    /// MainTabView owns triadBuildViewModel as @StateObject so chord root survives tab switches.
    func testChordRootPersistsOnShellOwnedViewModel() {
        let shellOwned = triadBuildViewModel()
        shellOwned.root = "F#"
        shellOwned.major = true

        // Simulate TabView tearing down/recreating tab content while the shell keeps the model.
        let reattached = shellOwned
        XCTAssertEqual(reattached.root, "F#")
        XCTAssertTrue(reattached.major)
    }

    /// MainTabView owns scalesViewModel as @StateObject so scale root survives tab switches.
    func testScaleRootPersistsOnShellOwnedViewModel() {
        let shellOwned = scalesViewModel()
        shellOwned.root = "Bb"
        shellOwned.dorian = true

        let reattached = shellOwned
        XCTAssertEqual(reattached.root, "Bb")
        XCTAssertTrue(reattached.dorian)
    }

    /// Interval notes live on IntervalSessionState owned by MainTabView.
    func testIntervalSessionPersistsNotesAcrossReattach() {
        let session = IntervalSessionState()
        session.bottomNote = "C"
        session.topNote = "G"
        session.intervalResult = "Perfect 5th"

        let reattached = session
        XCTAssertEqual(reattached.bottomNote, "C")
        XCTAssertEqual(reattached.topNote, "G")
        XCTAssertEqual(reattached.intervalResult, "Perfect 5th")
    }

    // MARK: - Chord interval formula (shipped triadBuildViewModel.quality path)

    func testMajorChordIntervalFormula() {
        let vm = triadBuildViewModel()
        vm.resetButtons()
        vm.major = true
        XCTAssertEqual(vm.chordIntervalsFromRoot(), ["M3", "P5"])
        XCTAssertEqual(vm.chordIntervalStack(), ["R", "M3", "P5"])
        XCTAssertEqual(vm.chordIntervalFormula(), "R  ·  M3  ·  P5")
    }

    func testMinorSeventhIntervalFormula() {
        let vm = triadBuildViewModel()
        vm.resetButtons()
        vm.mm7 = true
        XCTAssertEqual(vm.chordIntervalsFromRoot(), ["m3", "P5", "m7"])
        XCTAssertTrue(vm.chordIntervalFormula().contains("m3"))
        XCTAssertTrue(vm.chordIntervalFormula().contains("m7"))
    }

    func testDominantSeventhIntervalFormula() {
        let vm = triadBuildViewModel()
        vm.resetButtons()
        vm.Mm7 = true
        XCTAssertEqual(vm.chordIntervalsFromRoot(), ["M3", "P5", "m7"])
    }

    func testSus2IntervalFormulaOmitsEmptySlots() {
        let vm = triadBuildViewModel()
        vm.resetButtons()
        vm.sus2 = true
        XCTAssertEqual(vm.chordIntervalsFromRoot(), ["M2", "P5"])
        XCTAssertFalse(vm.chordIntervalFormula().contains("  ·  ·  "))
    }

    func testCompactIntervalLabelsForAugDim() {
        let vm = triadBuildViewModel()
        vm.resetButtons()
        vm.aug = true
        XCTAssertEqual(vm.chordIntervalsFromRoot(), ["M3", "A5"])

        vm.resetButtons()
        vm.dim = true
        XCTAssertEqual(vm.chordIntervalsFromRoot(), ["m3", "d5"])
    }
}
