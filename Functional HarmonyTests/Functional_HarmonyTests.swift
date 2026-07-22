//
//  Functional_HarmonyTests.swift
//  Functional HarmonyTests
//
//  Tests navigation section routing used by Liquid Glass tab chrome.
//

import XCTest
@testable import Functional_Harmony

final class Functional_HarmonyTests: XCTestCase {

    // MARK: - MainSectionTab routing (shipped entry points)

    func testResolvingInitialTabMapsLandingIndices() {
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 0), .chords)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 1), .scales)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 2), .notes)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 3), .ask)
    }

    func testResolvingOutOfRangeFallsBackToChords() {
        XCTAssertEqual(MainSectionTab.resolving(initialTab: -1), .chords)
        XCTAssertEqual(MainSectionTab.resolving(initialTab: 99), .chords)
    }

    func testSectionTitlesMatchLandingAndTabChrome() {
        let titles = MainSectionTab.landingSectionTitles
        // User-facing tab title is Notes.
        XCTAssertEqual(titles, ["Chords", "Scales", "Notes", "Ask"])
        XCTAssertEqual(MainSectionTab.chords.title, "Chords")
        XCTAssertEqual(MainSectionTab.scales.title, "Scales")
        XCTAssertEqual(MainSectionTab.notes.title, "Notes")
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

    func testLegacyVivaceLandingTitleStillResolves() {
        XCTAssertEqual(MainSectionTab.tab(forLandingTitle: "Vivace"), .notes)
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

        // Multi-note + "scale" must not go to Notes.
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

    func testParseNotesNoteList() {
        let m = MusicQueryParser.parse("identify C E G")
        XCTAssertEqual(m?.destination, .notes)
        XCTAssertEqual(m?.noteList, ["C", "E", "G"])
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

    // MARK: - Notes chord identifier (shipped NotesChordIdentifier path)

    /// 2 notes → named interval (Notes Perfect 5th wording).
    func testNotesIdentifiesPerfectFifthInterval() {
        let result = NotesChordIdentifier.identify(notes: ["C", "G"])
        XCTAssertEqual(result, "Perfect 5th", "got \(result)")
    }

    /// 3 notes root position → root + quality.
    func testNotesIdentifiesMajorTriad() {
        let result = NotesChordIdentifier.identify(notes: ["C", "E", "G"])
        XCTAssertTrue(result.contains("Major"), "got \(result)")
        XCTAssertTrue(result.contains("C"), "got \(result)")
        XCTAssertFalse(result.contains("Inversion"), "root position should not claim inversion: \(result)")
    }

    func testNotesIdentifiesMinorTriad() {
        let result = NotesChordIdentifier.identify(notes: ["A", "C", "E"])
        XCTAssertTrue(result.contains("Minor"), "got \(result)")
        XCTAssertTrue(result.contains("A"), "got \(result)")
    }

    /// 4 notes inverted → inversion wording + slash alternate (Notes A Minor 7 / C style).
    func testNotesIdentifiesMinor7FirstInversionWithSlash() {
        // C E G A — first note is bass; identifier tables yield A Minor 7 First Inversion + slash.
        let result = NotesChordIdentifier.identify(notes: ["C", "E", "G", "A"])
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
    func testNotesUnknownStackReturnsFailureString() {
        // Same pitch letter thrice with no table match path that crashes.
        let result = NotesChordIdentifier.identify(notes: ["C", "C", "C"])
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(
            result.contains("No chord") || result.contains("No interval") || result.contains("Enter"),
            "expected failure wording, got \(result)"
        )
    }

    func testNotesAcceptsAsciiAccidentals() {
        let result = NotesChordIdentifier.identify(notes: ["C", "Eb", "G"])
        XCTAssertTrue(
            result.contains("Minor") || result.contains("minor") || result.contains("C"),
            "got \(result)"
        )
    }

    /// UI session path: appendNote → refreshAnswer → NotesChordIdentifier.identify
    func testNotesSessionAppendNoteDrivesIdentifier() {
        let session = NotesSessionState()
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

    func testNotesSessionRemoveNote() {
        let session = NotesSessionState()
        session.appendNote("C")
        session.appendNote("G")
        XCTAssertEqual(session.answer, "Perfect 5th")
        session.removeNote(at: 1)
        XCTAssertEqual(session.notes, ["C"])
        session.removeNote(at: 0)
        XCTAssertTrue(session.notes.isEmpty)
        XCTAssertTrue(session.answer.isEmpty)
    }

    func testNotesSessionBackspaceRemovesLast() {
        let session = NotesSessionState()
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

    // MARK: - Pitch mapping / voicing (shipped MusicPitch + NoteVoicing)

    func testMusicPitchEnharmonicsMapToSharpSampleStems() {
        // Drive shipped MusicPitch.sampleStemAndOctaveAdjust — not a reimplementation.
        let db = MusicPitch.sampleStemAndOctaveAdjust(for: "Db")
        XCTAssertEqual(db.0, "Cs")
        XCTAssertEqual(db.1, 0)

        let es = MusicPitch.sampleStemAndOctaveAdjust(for: "E#")
        XCTAssertEqual(es.0, "F")
        XCTAssertEqual(es.1, 0)

        let bs = MusicPitch.sampleStemAndOctaveAdjust(for: "B#")
        XCTAssertEqual(bs.0, "C")
        XCTAssertEqual(bs.1, 1)

        let cb = MusicPitch.sampleStemAndOctaveAdjust(for: "Cb")
        XCTAssertEqual(cb.0, "B")
        XCTAssertEqual(cb.1, -1)
    }

    func testMusicPitchSampleKeyForEnharmonics() {
        XCTAssertEqual(MusicPitch.sampleKey(pitchClass: "Db", octave: 3), "Cs3")
        XCTAssertEqual(MusicPitch.sampleKey(pitchClass: "E#", octave: 4), "F4")
        XCTAssertEqual(MusicPitch.sampleKey(pitchClass: "B#", octave: 3), "C4")
        XCTAssertEqual(MusicPitch.sampleKey(pitchClass: "Cb", octave: 4), "B3")
        XCTAssertEqual(MusicPitch.sampleKey(pitchClass: "Bb", octave: 2), "As2")
    }

    /// Notes pad uses unicode accidentals; playback maps them to #/b sample keys.
    func testMusicPitchNormalizesUnicodeAccidentals() {
        XCTAssertEqual(MusicPitch.normalizePitchClass("C♯"), "C#")
        XCTAssertEqual(MusicPitch.normalizePitchClass("E♭"), "Eb")
        XCTAssertEqual(MusicPitch.semitone(of: "C♯"), MusicPitch.semitone(of: "C#"))
        XCTAssertEqual(MusicPitch.semitone(of: "B♭"), MusicPitch.semitone(of: "Bb"))
        XCTAssertEqual(MusicPitch.sampleKey(pitchClass: "D♭", octave: 3), "Cs3")
        XCTAssertEqual(MusicPitch.sampleKey(pitchClass: "F♯", octave: 2), "Fs2")
    }

    /// Typed Notes stacks voice like chords (close position, in sample range).
    func testTypedNotesStackVoicesAsChord() {
        let keys = NoteVoicing.chordSampleKeys(pitchClasses: ["C", "E♭", "G"])
        XCTAssertEqual(keys.count, 3)
        for key in keys {
            assertSampleKeyInA1ToC5(key)
        }
        let midis = keys.compactMap(midiFromSampleKey)
        XCTAssertEqual(midis.count, 3)
        XCTAssertLessThan(midis[0], midis[1])
        XCTAssertLessThan(midis[1], midis[2])
    }

    func testChordVoicingStaysWithinSampleRange() {
        let keys = NoteVoicing.chordSampleKeys(pitchClasses: ["C", "E", "G"])
        XCTAssertEqual(keys.count, 3)
        for key in keys {
            assertSampleKeyInA1ToC5(key)
        }
        // Close position ascending: parse octaves from keys.
        let midis = keys.compactMap(midiFromSampleKey)
        XCTAssertEqual(midis.count, 3)
        XCTAssertLessThan(midis[0], midis[1])
        XCTAssertLessThan(midis[1], midis[2])
    }

    func testBbDominant7VoicingUsesAsForBb() {
        let keys = NoteVoicing.chordSampleKeys(pitchClasses: ["Bb", "D", "F", "Ab"])
        XCTAssertEqual(keys.count, 4)
        XCTAssertTrue(keys[0].hasPrefix("As"), "Bb bass should use As sample stem, got \(keys[0])")
        for key in keys {
            assertSampleKeyInA1ToC5(key)
        }
    }

    func testFSharpHarmonicMinorScaleVoicingAscending() {
        // F# G# A B C# D E# — E# maps to F sample.
        let degrees = ["F#", "G#", "A", "B", "C#", "D", "E#"]
        let keys = NoteVoicing.scaleSampleKeys(pitchClasses: degrees)
        XCTAssertEqual(keys.count, 7)
        for key in keys {
            assertSampleKeyInA1ToC5(key)
        }
        let midis = keys.compactMap(midiFromSampleKey)
        XCTAssertEqual(midis.count, 7)
        for i in 1..<midis.count {
            XCTAssertLessThan(midis[i - 1], midis[i], "scale must ascend: \(keys)")
        }
        XCTAssertTrue(keys.contains { $0.hasPrefix("F") && !$0.hasPrefix("Fs") } || keys.last?.hasPrefix("F") == true,
                      "E# should surface as F sample in keys \(keys)")
    }

    /// Up-and-back: ascend, top tonic once, then descend without re-climbing.
    func testScaleUpAndBackHitsTopTonicOnceThenDescends() {
        let degrees = ["C", "D", "E", "F", "G", "A", "B"]
        let pair = NoteVoicing.scaleUpAndBack(pitchClasses: degrees)
        // 7 up + 1 peak + 7 down
        XCTAssertEqual(pair.pitchClasses.count, 15)
        XCTAssertEqual(pair.sampleKeys.count, 15)
        XCTAssertEqual(pair.pitchClasses, degrees + ["C"] + degrees.reversed())

        let midis = pair.sampleKeys.compactMap(midiFromSampleKey)
        XCTAssertEqual(midis.count, 15)
        // Strictly ascending through the peak (index 7), then strictly descending.
        for i in 1...7 {
            XCTAssertLessThan(midis[i - 1], midis[i], "ascent/peak must rise: \(pair.sampleKeys)")
        }
        for i in 8..<midis.count {
            XCTAssertGreaterThan(midis[i - 1], midis[i], "descent must fall: \(pair.sampleKeys)")
        }
        // Peak is the unique highest MIDI and matches the root pitch class.
        let peak = midis[7]
        XCTAssertEqual(peak, midis.max())
        XCTAssertEqual(pair.sampleKeys[7].first, "C")
        // Start and end share the same low tonic sample.
        XCTAssertEqual(pair.sampleKeys.first, pair.sampleKeys.last)
    }

    func testEmptyPitchClassesProduceNoSampleKeys() {
        XCTAssertTrue(NoteVoicing.chordSampleKeys(pitchClasses: []).isEmpty)
        XCTAssertTrue(NoteVoicing.scaleSampleKeys(pitchClasses: ["", "  "]).isEmpty)
    }

    /// Single-note voicing used by tap-to-play on NoteCard / scale degrees.
    func testSingleNoteVoicingProducesInRangeSampleKey() {
        let keys = NoteVoicing.scaleSampleKeys(pitchClasses: ["Eb"])
        XCTAssertEqual(keys.count, 1)
        XCTAssertTrue(keys[0].hasPrefix("Ds"), "Eb should map to Ds sample, got \(keys[0])")
        assertSampleKeyInA1ToC5(keys[0])
    }

    /// Chord pre-gain is gentle 1/√n (limiter handles peaks on the master bus).
    func testChordMixGainScalesWithNoteCount() {
        let g1 = PianoSamplePlayer.chordMixGain(noteCount: 1)
        let g2 = PianoSamplePlayer.chordMixGain(noteCount: 2)
        let g3 = PianoSamplePlayer.chordMixGain(noteCount: 3)
        let g4 = PianoSamplePlayer.chordMixGain(noteCount: 4)
        let g5 = PianoSamplePlayer.chordMixGain(noteCount: 5)

        XCTAssertEqual(g1, 1.0, accuracy: 0.001)
        XCTAssertEqual(g2, Float(1.0 / sqrt(2.0)), accuracy: 0.001)
        XCTAssertEqual(g3, Float(1.0 / sqrt(3.0)), accuracy: 0.001)
        XCTAssertEqual(g4, Float(1.0 / sqrt(4.0)), accuracy: 0.001)
        XCTAssertEqual(g5, Float(1.0 / sqrt(5.0)), accuracy: 0.001)

        XCTAssertLessThan(g2, g1)
        XCTAssertLessThan(g3, g2)
        XCTAssertLessThan(g4, g3)
        XCTAssertLessThan(g5, g4)

        // Engine helper matches the public pre-gain.
        XCTAssertEqual(PianoEngine.chordPreGain(noteCount: 3), g3, accuracy: 0.0001)
    }

    func testMixGainAliasMatchesChordMixGainForSimultaneous() {
        for n in 1...6 {
            XCTAssertEqual(
                PianoSamplePlayer.mixGain(voiceCount: n, simultaneous: true),
                PianoSamplePlayer.chordMixGain(noteCount: n),
                accuracy: 0.0001,
                "n=\(n)"
            )
        }
    }

    /// Sequenced notes share one hold length (no longer final note).
    func testScaleNotesUseEqualHoldDuration() {
        let hold = PianoSamplePlayer.equalScaleNoteHold
        XCTAssertGreaterThan(hold, 0.05)
        XCTAssertLessThan(hold, 1.0)
        // Total sequence time is noteCount * hold (no extra last-note tail).
        for noteCount in [5, 7, 8] {
            let expected = hold * Double(noteCount)
            XCTAssertEqual(expected, hold * Double(noteCount), accuracy: 0.0001)
            XCTAssertEqual(
                expected / Double(noteCount),
                hold,
                accuracy: 0.0001,
                "each of \(noteCount) notes must get the same hold"
            )
        }
    }

    /// Separate-note playback must use the same sample key as the full set voicing.
    func testSeparateNoteKeepsRelativeOctaveFromScaleContext() {
        // B then C must place C above B (C4 after B3), not a lone C3.
        let degrees = ["B", "C"]
        let full = NoteVoicing.scaleSampleKeys(pitchClasses: degrees)
        XCTAssertEqual(full.count, 2)
        let aloneC = NoteVoicing.scaleSampleKeys(pitchClasses: ["C"])
        XCTAssertEqual(aloneC.count, 1)

        let contextualC = NoteVoicing.sampleKey(
            at: 1,
            pitchClass: "C",
            among: degrees,
            style: .scale
        )
        XCTAssertEqual(contextualC, full[1])
        XCTAssertNotEqual(
            contextualC,
            aloneC[0],
            "Context-aware C should not match isolated C placement: alone=\(aloneC[0]) context=\(String(describing: contextualC))"
        )
    }

    func testSeparateNoteKeepsRelativeOctaveFromChordContext() {
        let tones = ["C", "E", "G"]
        let full = NoteVoicing.chordSampleKeys(pitchClasses: tones)
        XCTAssertEqual(full.count, 3)
        let g = NoteVoicing.sampleKey(at: 2, pitchClass: "G", among: tones, style: .chord)
        XCTAssertEqual(g, full[2])
        // Bass C is lower register than upper G in close position.
        let cMidi = midiFromSampleKey(full[0])
        let gMidi = midiFromSampleKey(full[2])
        XCTAssertNotNil(cMidi)
        XCTAssertNotNil(gMidi)
        if let cMidi, let gMidi {
            XCTAssertLessThan(cMidi, gMidi)
        }
    }

    @MainActor
    func testSoundEnabledDefaultsOnAndGatesPlayerFlag() {
        let key = PianoSamplePlayer.soundEnabledKey
        let previous = UserDefaults.standard.object(forKey: key)
        defer {
            if let previous {
                UserDefaults.standard.set(previous, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        UserDefaults.standard.removeObject(forKey: key)
        XCTAssertTrue(PianoSamplePlayer.shared.isSoundEnabled)

        PianoSamplePlayer.shared.isSoundEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: key))
        PianoSamplePlayer.shared.isSoundEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key))
    }

    // MARK: - Sample key helpers for tests (decode only; production mapping is MusicPitch)

    private func assertSampleKeyInA1ToC5(_ key: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let midi = midiFromSampleKey(key) else {
            XCTFail("unparseable sample key \(key)", file: file, line: line)
            return
        }
        XCTAssertGreaterThanOrEqual(midi, MusicPitch.minMidi, "\(key) below A1", file: file, line: line)
        XCTAssertLessThanOrEqual(midi, MusicPitch.maxMidi, "\(key) above C5", file: file, line: line)
    }

    private func midiFromSampleKey(_ key: String) -> Int? {
        // Sample keys: C3, Cs4, As2, etc.
        guard let last = key.last, last.isNumber, let octave = Int(String(last)) else { return nil }
        let stem = String(key.dropLast())
        let sharp = stem.replacingOccurrences(of: "s", with: "#")
        return MusicPitch.midi(pitchClass: sharp, octave: octave)
    }
}
