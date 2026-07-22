//
//  NoteVoicing.swift
//  Functional Harmony
//
//  Pitch classes → concrete sample keys in the A1–C5 piano range.
//

import Foundation

/// Places chord and scale pitch classes into playable octaves.
enum NoteVoicing {

    /// How a multi-note set is stacked into A1–C5.
    enum Style {
        /// Close-position chord (bass low, upper voices ascending).
        case chord
        /// Ascending scale degrees (step up an octave when needed).
        case scale
    }

    /// Normalize and drop empty / unknown spellings (keeps order).
    static func cleanedPitchClasses(_ pitchClasses: [String]) -> [String] {
        pitchClasses
            .map { MusicPitch.normalizePitchClass($0) }
            .filter { !$0.isEmpty && MusicPitch.semitone(of: $0) != nil }
    }

    /// Sample keys for a full set, preserving relative octaves within the set.
    static func sampleKeys(pitchClasses: [String], style: Style) -> [String] {
        switch style {
        case .chord: return chordSampleKeys(pitchClasses: pitchClasses)
        case .scale: return scaleSampleKeys(pitchClasses: pitchClasses)
        }
    }

    /// Sample key for one member of a set, using the same voicing as playing the whole set.
    /// Prefer `index` when provided (handles duplicate pitch classes).
    static func sampleKey(
        at index: Int? = nil,
        pitchClass: String,
        among pitchClasses: [String],
        style: Style
    ) -> String? {
        let cleaned = cleanedPitchClasses(pitchClasses)
        let keys = sampleKeys(pitchClasses: cleaned, style: style)
        guard !cleaned.isEmpty, cleaned.count == keys.count else { return nil }

        if let index, cleaned.indices.contains(index) {
            return keys[index]
        }

        let target = MusicPitch.normalizePitchClass(pitchClass)
        if let match = cleaned.firstIndex(of: target) {
            return keys[match]
        }
        // Enharmonic fallback (e.g. Db card vs stored C#).
        if let targetSemi = MusicPitch.semitone(of: target),
           let match = cleaned.firstIndex(where: { MusicPitch.semitone(of: $0) == targetSemi }) {
            return keys[match]
        }
        return nil
    }

    /// Close-position block chord: bass near octave 2–3, upper voices ascending above the bass.
    static func chordSampleKeys(pitchClasses: [String]) -> [String] {
        let cleaned = cleanedPitchClasses(pitchClasses)
        guard !cleaned.isEmpty else { return [] }

        var midis: [Int] = []
        // Bass preference: octave 2, clamped into range.
        if let bass = place(pitchClass: cleaned[0], above: MusicPitch.minMidi - 1, preferredMinOctave: 2) {
            midis.append(bass)
        } else {
            return []
        }

        var last = midis[0]
        for pc in cleaned.dropFirst() {
            if let m = place(pitchClass: pc, above: last, preferredMinOctave: 2) {
                midis.append(m)
                last = m
            }
        }
        return midis.map { MusicPitch.sampleKey(midi: $0) }
    }

    /// Ascending scale: start near octave 3–4 and step up when the next degree is not higher.
    static func scaleSampleKeys(pitchClasses: [String]) -> [String] {
        let cleaned = cleanedPitchClasses(pitchClasses)
        guard !cleaned.isEmpty else { return [] }

        var midis: [Int] = []
        // Prefer starting around C3–C4 (midi ~48–60).
        if let first = place(pitchClass: cleaned[0], above: 47, preferredMinOctave: 3) {
            midis.append(first)
        } else {
            return []
        }

        var last = midis[0]
        for pc in cleaned.dropFirst() {
            if let m = place(pitchClass: pc, above: last, preferredMinOctave: 3) {
                midis.append(m)
                last = m
            }
        }
        return midis.map { MusicPitch.sampleKey(midi: $0) }
    }

    /// Lowest MIDI for `pitchClass` that is strictly above `aboveMIDI` and inside the sample range.
    static func place(pitchClass: String, above aboveMIDI: Int, preferredMinOctave: Int) -> Int? {
        guard MusicPitch.semitone(of: pitchClass) != nil else { return nil }

        // Search octaves from low to high; pick first legal placement above the prior voice.
        for octave in preferredMinOctave...5 {
            guard let raw = MusicPitch.midi(pitchClass: pitchClass, octave: octave) else { continue }
            let m = MusicPitch.clampMIDI(raw)
            // If clamping collapsed a high note, still require it to be above prior when possible.
            if m > aboveMIDI && m >= MusicPitch.minMidi && m <= MusicPitch.maxMidi {
                // Prefer the unclamped match when still in range.
                if raw >= MusicPitch.minMidi && raw <= MusicPitch.maxMidi && raw > aboveMIDI {
                    return raw
                }
                if m > aboveMIDI {
                    return m
                }
            }
        }

        // Fallback: any in-range MIDI for this pitch class closest above previous.
        var best: Int?
        for octave in 1...5 {
            guard let raw = MusicPitch.midi(pitchClass: pitchClass, octave: octave) else { continue }
            guard raw >= MusicPitch.minMidi && raw <= MusicPitch.maxMidi else { continue }
            if raw > aboveMIDI {
                if best == nil || raw < best! {
                    best = raw
                }
            }
        }
        if let best { return best }

        // Last resort: same pitch class clamped (may equal previous for unison stacks).
        if let raw = MusicPitch.midi(pitchClass: pitchClass, octave: preferredMinOctave) {
            return MusicPitch.clampMIDI(raw)
        }
        return nil
    }
}
