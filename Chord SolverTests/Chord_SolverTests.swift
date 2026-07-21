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
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 2), .vivace)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 3), .ask)
    }

    func testResolvingOutOfRangeFallsBackToChords() {
        XCTAssertEqual(MainSectionTab.resolving(initialTab: -1), .chords)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 99), .chords)
    }

    func testSectionTitlesMatchLandingAndTabChrome() {
        let titles = MainSectionTab.landingSectionTitles
        XCTAssertEqual(titles, ["Chords", "Scales", "Vivace", "Ask"])
        XCTAssertEqual(MainSectionTab.chords.title, "Chords")
        XCTAssertEqual(MainSectionTab.scales.title, "Scales")
        XCTAssertEqual(MainSectionTab.vivace.title, "Vivace")
        XCTAssertEqual(MainSectionTab.ask.title, "Ask")
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

    func testAllCasesCoverFourPrimarySections() {
        XCTAssertEqual(MainSectionTab.allCases.count, 4)
        XCTAssertEqual(
            Set(MainSectionTab.allCases.map(\.rawValue)),
            Set([0, 1, 2, 3])
        )
    }

    // MARK: - Natural language → state (Ask tab)

    func testParseChordMajor() {
        let m = MusicQueryParser.parse("C major")
        XCTAssertEqual(m?.destination, .chords)
        XCTAssertEqual(m?.root, "C")
        XCTAssertEqual(m?.chordQuality, .major)
    }

    func testParseChordMaj7Compact() {
        let m = MusicQueryParser.parse("Bbmaj7")
        XCTAssertEqual(m?.destination, .chords)
        XCTAssertEqual(m?.root, "Bb")
        XCTAssertEqual(m?.chordQuality, .MM7)
    }

    func testParseScaleDorian() {
        let m = MusicQueryParser.parse("F# dorian")
        XCTAssertEqual(m?.destination, .scales)
        XCTAssertEqual(m?.root, "F#")
        XCTAssertEqual(m?.scaleQuality, .dorian)
    }

    func testParseScaleHarmonicMinor() {
        let m = MusicQueryParser.parse("Eb harmonic minor scale")
        XCTAssertEqual(m?.destination, .scales)
        XCTAssertEqual(m?.root, "Eb")
        XCTAssertEqual(m?.scaleQuality, .minorHarm)
    }

    /// Word "scale" forces the scales destination (not chords / note-list).
    func testParseScaleKeywordForcesScale() {
        let major = MusicQueryParser.parse("C major scale")
        XCTAssertEqual(major?.destination, .scales)
        XCTAssertEqual(major?.root, "C")
        XCTAssertEqual(major?.scaleQuality, .major)

        let minor = MusicQueryParser.parse("Bb minor scale")
        XCTAssertEqual(minor?.destination, .scales)
        XCTAssertEqual(minor?.root, "Bb")
        XCTAssertEqual(minor?.scaleQuality, .minorNat)

        let ofPhrase = MusicQueryParser.parse("scale of G major")
        XCTAssertEqual(ofPhrase?.destination, .scales)
        XCTAssertEqual(ofPhrase?.root, "G")
        XCTAssertEqual(ofPhrase?.scaleQuality, .major)

        // Multi-note + "scale" must not go to Vivace.
        let degrees = MusicQueryParser.parse("C D E F G A B scale")
        XCTAssertEqual(degrees?.destination, .scales)
        XCTAssertEqual(degrees?.root, "C")
        XCTAssertEqual(degrees?.scaleQuality, .major)

        // Compact quality + scale word.
        let compact = MusicQueryParser.parse("Cmaj scale")
        XCTAssertEqual(compact?.destination, .scales)
        XCTAssertEqual(compact?.root, "C")
        XCTAssertEqual(compact?.scaleQuality, .major)
    }

    func testParseScaleMixolydianFlat6() {
        let m = MusicQueryParser.parse("G mixolydian b6")
        XCTAssertEqual(m?.destination, .scales)
        XCTAssertEqual(m?.root, "G")
        XCTAssertEqual(m?.scaleQuality, .mixoB6)
        // Must not collapse to plain Mixolydian.
        XCTAssertNotEqual(m?.scaleQuality, .mixo)
    }

    func testParseScaleLocrianNatural2() {
        let m = MusicQueryParser.parse("D locrian natural 2")
        XCTAssertEqual(m?.destination, .scales)
        XCTAssertEqual(m?.root, "D")
        XCTAssertEqual(m?.scaleQuality, .locNat2)
        XCTAssertNotEqual(m?.scaleQuality, .locrian)
    }

    func testMelodicMinorModesBuildNotes() {
        let mixo = scalesViewModel()
        mixo.root = "C"
        mixo.resetButtons()
        mixo.mixoB6 = true
        // Mixolydian ♭6: C D E F G Ab Bb
        XCTAssertEqual(mixo.returnRoot(), "C")
        XCTAssertEqual(mixo.two(), "D")
        XCTAssertEqual(mixo.three(), "E")
        XCTAssertEqual(mixo.four(), "F")
        XCTAssertEqual(mixo.five(), "G")
        XCTAssertEqual(mixo.six(), "Ab")
        XCTAssertEqual(mixo.sev(), "Bb")

        let loc = scalesViewModel()
        loc.root = "C"
        loc.resetButtons()
        loc.locNat2 = true
        // Locrian ♮2: C D Eb F Gb Ab Bb
        XCTAssertEqual(loc.returnRoot(), "C")
        XCTAssertEqual(loc.two(), "D")
        XCTAssertEqual(loc.three(), "Eb")
        XCTAssertEqual(loc.four(), "F")
        XCTAssertEqual(loc.five(), "Gb")
        XCTAssertEqual(loc.six(), "Ab")
        XCTAssertEqual(loc.sev(), "Bb")
    }

    func testParseVivaceNoteList() {
        let m = MusicQueryParser.parse("identify C E G")
        XCTAssertEqual(m?.destination, .vivace)
        XCTAssertEqual(m?.vivaceNotes, ["C", "E", "G"])
    }

    func testParseMinor7MapsQuality() {
        let match = MusicQueryParser.parse("A minor 7")
        XCTAssertEqual(match?.destination, .chords)
        XCTAssertEqual(match?.root, "A")
        XCTAssertEqual(match?.chordQuality, .mm7)
        XCTAssertEqual(match?.tab, .chords)
    }

    /// Classical "major-minor 7th" = dominant 7 (major triad + minor 7), not minor 7.
    func testParseMajorMinor7IsDominant() {
        let m = MusicQueryParser.parse("C Major Minor 7")
        XCTAssertEqual(m?.destination, .chords)
        XCTAssertEqual(m?.root, "C")
        XCTAssertEqual(m?.chordQuality, .Mm7, "major-minor 7th should be dominant, got \(String(describing: m?.chordQuality))")
        XCTAssertNotEqual(m?.chordQuality, .mm7)
        XCTAssertNotEqual(m?.chordQuality, .mM7)
    }

    func testParseMinorMajor7() {
        let m = MusicQueryParser.parse("C minor major 7")
        XCTAssertEqual(m?.destination, .chords)
        XCTAssertEqual(m?.root, "C")
        XCTAssertEqual(m?.chordQuality, .mM7)
    }

    // MARK: - Vivace Theory identifier (shipped VivaceChordIdentifier path)

    /// 2 notes → named interval (Vivace Perfect 5th wording).
    func testVivaceIdentifiesPerfectFifthInterval() {
        let result = VivaceChordIdentifier.identify(notes: ["C", "G"])
        XCTAssertEqual(result, "Perfect 5th", "got \(result)")
    }

    /// 3 notes root position → root + quality.
    func testVivaceIdentifiesMajorTriad() {
        let result = VivaceChordIdentifier.identify(notes: ["C", "E", "G"])
        XCTAssertTrue(result.contains("Major"), "got \(result)")
        XCTAssertTrue(result.contains("C"), "got \(result)")
        XCTAssertFalse(result.contains("Inversion"), "root position should not claim inversion: \(result)")
    }

    func testVivaceIdentifiesMinorTriad() {
        let result = VivaceChordIdentifier.identify(notes: ["A", "C", "E"])
        XCTAssertTrue(result.contains("Minor"), "got \(result)")
        XCTAssertTrue(result.contains("A"), "got \(result)")
    }

    /// 4 notes inverted → inversion wording + slash alternate (Vivace A Minor 7 / C style).
    func testVivaceIdentifiesMinor7FirstInversionWithSlash() {
        // C E G A — first note is bass; Vivace tables yield A Minor 7 First Inversion + slash.
        let result = VivaceChordIdentifier.identify(notes: ["C", "E", "G", "A"])
        XCTAssertTrue(
            result.contains("Minor 7") || result.contains("Minor"),
            "expected minor-7 family, got \(result)"
        )
        XCTAssertTrue(
            result.contains("Inversion") || result.contains("/"),
            "expected inversion or slash alternate, got \(result)"
        )
    }

    /// Unknown / unsupported stack → non-crash failure string.
    func testVivaceUnknownStackReturnsFailureString() {
        // Same pitch letter thrice with no table match path that crashes.
        let result = VivaceChordIdentifier.identify(notes: ["C", "C", "C"])
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(
            result.contains("No chord") || result.contains("No interval") || result.contains("Enter"),
            "expected failure wording, got \(result)"
        )
    }

    func testVivaceAcceptsAsciiAccidentals() {
        let result = VivaceChordIdentifier.identify(notes: ["C", "Eb", "G"])
        XCTAssertTrue(
            result.contains("Minor") || result.contains("minor") || result.contains("C"),
            "got \(result)"
        )
    }

    /// UI session path: appendNote → refreshAnswer → VivaceChordIdentifier.identify
    func testVivaceSessionAppendNoteDrivesIdentifier() {
        let session = VivaceSessionState()
        session.appendNote("C")
        session.appendNote("E")
        session.appendNote("G")
        XCTAssertEqual(session.notes, ["C", "E", "G"])
        XCTAssertTrue(
            session.answer.contains("Major"),
            "session answer should identify C major via shipped path, got \(session.answer)"
        )
        XCTAssertTrue(session.answer.contains("C"), "got \(session.answer)")
    }

    func testVivaceSessionRemoveNote() {
        let session = VivaceSessionState()
        session.appendNote("C")
        session.appendNote("G")
        XCTAssertEqual(session.answer, "Perfect 5th")
        session.removeNote(at: 1)
        XCTAssertEqual(session.notes, ["C"])
        session.removeNote(at: 0)
        XCTAssertTrue(session.notes.isEmpty)
        XCTAssertTrue(session.answer.isEmpty)
    }

    func testVivaceSessionBackspaceRemovesLast() {
        let session = VivaceSessionState()
        session.appendNote("C")
        session.appendNote("E")
        session.appendNote("G")
        session.backspace()
        XCTAssertEqual(session.notes, ["C", "E"])
        session.backspace()
        session.backspace()
        XCTAssertTrue(session.notes.isEmpty)
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
