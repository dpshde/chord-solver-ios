//
//  MusicPitch.swift
//  Functional Harmony
//
//  Pitch-class → sample-key mapping for Canon-derived piano samples (A1–C5).
//

import Foundation

/// Pure pitch helpers shared by voicing and the sample player.
/// Sample files are named like `Cs3_bip.caf` (sharp = `s`).
enum MusicPitch {

    /// Lowest bundled sample (A1).
    static let minMidi = 21
    /// Highest bundled sample (C5).
    static let maxMidi = 72

    /// Pitch class → chromatic class (C = 0 … B = 11).
    /// Includes common enharmonics used by the chord/scale builders.
    static let noteToSemitone: [String: Int] = [
        "C": 0, "B#": 0, "Dbb": 0,
        "C#": 1, "Db": 1, "B##": 1, "Bx": 1,
        "D": 2, "C##": 2, "Cx": 2, "Ebb": 2,
        "D#": 3, "Eb": 3, "Fbb": 3,
        "E": 4, "Fb": 4, "D##": 4, "Dx": 4,
        "F": 5, "E#": 5, "Gbb": 5,
        "F#": 6, "Gb": 6, "E##": 6, "Ex": 6,
        "G": 7, "F##": 7, "Fx": 7, "Abb": 7,
        "G#": 8, "Ab": 8,
        "A": 9, "G##": 9, "Gx": 9, "Bbb": 9,
        "A#": 10, "Bb": 10, "Cbb": 10,
        "B": 11, "Cb": 11, "A##": 11, "Ax": 11,
    ]

    private static let sharpNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

    /// Normalize UI pitch-class spelling (trim; keep case of first letter).
    static func normalizePitchClass(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        // Builders emit spellings like "C", "Eb", "F#", occasionally lowercase.
        let first = trimmed.prefix(1).uppercased()
        let rest = trimmed.dropFirst()
        return first + rest
    }

    /// Chromatic class 0…11 for a pitch-class string, if known.
    static func semitone(of pitchClass: String) -> Int? {
        let pc = normalizePitchClass(pitchClass)
        return noteToSemitone[pc]
    }

    /// MIDI number for pitch class + octave (scientific pitch: C4 = 60).
    static func midi(pitchClass: String, octave: Int) -> Int? {
        guard let semi = semitone(of: pitchClass) else { return nil }
        return (octave + 1) * 12 + semi
    }

    /// Clamp MIDI into the bundled sample range A1…C5.
    static func clampMIDI(_ midi: Int) -> Int {
        min(max(midi, minMidi), maxMidi)
    }

    /// Convert MIDI to a sample key without the `_bip` suffix (e.g. `Cs3`).
    static func sampleKey(midi: Int) -> String {
        let m = clampMIDI(midi)
        let octave = m / 12 - 1
        let semi = m % 12
        let sharp = sharpNames[semi]
        let fileStem = sharp.replacingOccurrences(of: "#", with: "s")
        return "\(fileStem)\(octave)"
    }

    /// Pitch class + octave → sample key, applying Canon-style enharmonic octave adjustments
    /// (B# crosses up, Cb crosses down). Result is always inside A1–C5 when possible.
    static func sampleKey(pitchClass: String, octave: Int) -> String? {
        let pc = normalizePitchClass(pitchClass)
        guard !pc.isEmpty else { return nil }

        let (keyStem, octaveAdjust) = sampleStemAndOctaveAdjust(for: pc)
        let resolvedOctave = octave + octaveAdjust
        // Build MIDI from resolved sharp spelling to clamp correctly.
        let sharpPC = keyStem.replacingOccurrences(of: "s", with: "#")
        guard let midi = midi(pitchClass: sharpPC, octave: resolvedOctave) else {
            // Fallback: if stem is like "Cs", map via known sharp names.
            if let semi = sharpNames.firstIndex(of: sharpPC) {
                let m = clampMIDI((resolvedOctave + 1) * 12 + semi)
                return sampleKey(midi: m)
            }
            return nil
        }
        return sampleKey(midi: midi)
    }

    /// Canon `note_to_sample_key` equivalent: returns (`Cs` style stem, octave delta).
    static func sampleStemAndOctaveAdjust(for pitchClass: String) -> (String, Int) {
        let pc = normalizePitchClass(pitchClass)
        switch pc {
        case "Db": return ("Cs", 0)
        case "Eb": return ("Ds", 0)
        case "Gb": return ("Fs", 0)
        case "Ab": return ("Gs", 0)
        case "Bb": return ("As", 0)
        case "E#": return ("F", 0)
        case "Fb": return ("E", 0)
        case "B#": return ("C", 1)
        case "Cb": return ("B", -1)
        case "C##", "Cx": return ("D", 0)
        case "D##", "Dx": return ("E", 0)
        case "E##", "Ex": return ("Fs", 0)
        case "F##", "Fx": return ("G", 0)
        case "G##", "Gx": return ("A", 0)
        case "A##", "Ax": return ("B", 0)
        case "B##", "Bx": return ("Cs", 1)
        case "Cbb": return ("As", -1)
        case "Dbb": return ("C", 0)
        case "Ebb": return ("D", 0)
        case "Fbb": return ("Ds", -1)
        case "Gbb": return ("F", 0)
        case "Abb": return ("G", 0)
        case "Bbb": return ("A", 0)
        default:
            let stem = pc.replacingOccurrences(of: "#", with: "s")
            return (stem, 0)
        }
    }

    /// Resource filename for a sample key: `Cs3` → `Cs3_bip`.
    static func resourceBaseName(sampleKey: String) -> String {
        "\(sampleKey)_bip"
    }
}
