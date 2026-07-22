//
//  PianoSamplePlayer.swift
//  Functional Harmony
//
//  Public piano playback API for result panels and note taps.
//  Delegates to PianoEngine (AVAudioEngine voice pool + PeakLimiter).
//
//  - Chords: all voices scheduled at one shared AVAudioTime (no flam).
//  - Scales: every note pre-scheduled on the host-time grid (sample-accurate).
//  - Loop mode: sticky toggle; play runs up-and-back once when on (not continuous).
//  - UI state (`isPlaying`, highlights) is delayed to the same host-time grid as audio.
//  - Note taps: polyphonic — new taps allocate a voice without killing ring-out.
//  - stop(): soft-releases all voices for click-free silence.
//

import AVFoundation
import Foundation

/// Plays block chords and ascending scale sequences from bundled piano samples.
@MainActor
final class PianoSamplePlayer: ObservableObject {

    static let shared = PianoSamplePlayer()

    /// UserDefaults key shared with the result-panel sound toggle.
    static let soundEnabledKey = "resultAudio.soundEnabled"

    /// Hold time for every sequenced scale degree (including the last).
    private static let scaleNoteHold: TimeInterval = 0.30

    /// How long a mid-sequence note rings past its step before soft note-off.
    /// Slightly past the hold for light legato without a muddy wash.
    private static let sequenceSustain: TimeInterval = 0.42

    /// Last note of a phrase: short ring, then release.
    private static let phraseFinalSustain: TimeInterval = 0.75

    /// Soft release length for scheduled note-offs / phrase ends.
    private static let releaseDuration: TimeInterval = 0.060

    /// Block chords and single taps: audible ring after onset before release.
    private static let chordRingDuration: TimeInterval = 1.25
    private static let singleNoteRingDuration: TimeInterval = 0.95

    @Published private(set) var isPlaying = false

    /// Sticky UI mode: when true, `playScale` runs up-and-back once; when false, ascending only.
    /// Toggling this never starts or stops audio — only the play surface does.
    @Published var isLoopEnabled = false

    /// Pitch class currently emphasized in the result banner during separate-note playback.
    @Published private(set) var highlightedPitchClass: String?

    /// When false, chord/scale result play is ignored. Single-note taps still play.
    var isSoundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: Self.soundEnabledKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Self.soundEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.soundEnabledKey)
            if !newValue {
                stop()
            }
            objectWillChange.send()
        }
    }

    private let engine = PianoEngine.shared
    private var sequenceTask: Task<Void, Never>?
    private var highlightTask: Task<Void, Never>?
    /// Bumped on every fresh chord/sequence/stop so in-flight UI tasks cannot clobber state.
    private var playGeneration = 0

    private init() {
        PianoSampleStore.shared.startPreloadIfNeeded()
    }

    // MARK: - Public API

    func playChord(pitchClasses: [String]) {
        guard isSoundEnabled else { return }
        let keys = NoteVoicing.chordSampleKeys(pitchClasses: pitchClasses)
        guard !keys.isEmpty else { return }

        cancelUITasks(clearHighlight: true)
        // Do not releaseAll() here — that fades prior audio during the pre-schedule gap
        // and reads as ducking before every new chord (Notes autoplay, quality changes).

        let clockBase = ContinuousClock.now
        let anchorOffset = PianoEngine.defaultAnchorOffset
        let when = engine.scheduleAnchor(offset: anchorOffset)
        let priorCutoff = engine.nextStartOrdinal
        let gain = Self.chordMixGain(noteCount: keys.count)
        let started = engine.playChord(sampleKeys: keys, at: when, gainPerVoice: gain)
        guard started > 0 else { return }

        highlightedPitchClass = nil
        let generation = playGeneration
        // Fade the previous phrase at the same instant the new chord speaks.
        schedulePriorRelease(
            generation: generation,
            clockBase: clockBase,
            at: anchorOffset,
            startedBefore: priorCutoff
        )
        // isPlaying flips at audio onset, off after ring + release (same clock as audio).
        highlightTask = Task { [weak self] in
            guard let self else { return }
            await self.runPhraseUI(
                generation: generation,
                clockBase: clockBase,
                onset: anchorOffset,
                ringEnd: anchorOffset + Self.chordRingDuration,
                releaseDuration: Self.releaseDuration
            )
        }
    }

    /// Ascending sequence; all notes pre-scheduled on a fixed time grid (no drift).
    func playSequence(pitchClasses: [String], noteHold: TimeInterval = scaleNoteHold) {
        guard isSoundEnabled else { return }
        let cleaned = NoteVoicing.cleanedPitchClasses(pitchClasses)
        let keys = NoteVoicing.scaleSampleKeys(pitchClasses: cleaned)
        startSequence(pitchClasses: cleaned, sampleKeys: keys, noteHold: noteHold)
    }

    /// Ascend, hit the top tonic once, then descend — a single pass (not continuous).
    func playSequenceUpAndBack(pitchClasses: [String], noteHold: TimeInterval = scaleNoteHold) {
        guard isSoundEnabled else { return }
        let pair = NoteVoicing.scaleUpAndBack(pitchClasses: pitchClasses)
        startSequence(pitchClasses: pair.pitchClasses, sampleKeys: pair.sampleKeys, noteHold: noteHold)
    }

    /// Scale result play: respects `isLoopEnabled` (up-and-back once vs ascending once).
    func playScale(pitchClasses: [String], noteHold: TimeInterval = scaleNoteHold) {
        if isLoopEnabled {
            playSequenceUpAndBack(pitchClasses: pitchClasses, noteHold: noteHold)
        } else {
            playSequence(pitchClasses: pitchClasses, noteHold: noteHold)
        }
    }

    /// Flip the sticky loop mode. Does not start or stop playback.
    func toggleLoopEnabled() {
        isLoopEnabled.toggle()
    }

    /// Shared one-shot scheduler (ascending or a single up-and-back pass).
    private func startSequence(
        pitchClasses: [String],
        sampleKeys: [String],
        noteHold: TimeInterval
    ) {
        let cleaned = pitchClasses
            .map { MusicPitch.normalizePitchClass($0) }
            .filter { !$0.isEmpty }
        guard !cleaned.isEmpty, cleaned.count == sampleKeys.count else { return }

        cancelUITasks(clearHighlight: true)
        // Do not releaseAll() here — same pre-onset duck as playChord.

        let gap = max(0.05, noteHold)
        let generation = playGeneration
        // Do not set isPlaying here — wait for first audio onset on the shared clock.

        let anchorOffset = PianoEngine.defaultAnchorOffset
        let clockBase = ContinuousClock.now
        let priorCutoff = engine.nextStartOrdinal
        let anchor = engine.scheduleAnchor(offset: anchorOffset)
        let count = cleaned.count

        guard schedulePass(
            sampleKeys: sampleKeys,
            anchor: anchor,
            gap: gap,
            generation: generation,
            clockBase: clockBase,
            anchorOffset: anchorOffset
        ) > 0 else {
            return
        }

        schedulePriorRelease(
            generation: generation,
            clockBase: clockBase,
            at: anchorOffset,
            startedBefore: priorCutoff
        )

        // Highlights and isPlaying follow absolute deadlines on the same grid as audio.
        sequenceTask = Task { [weak self] in
            guard let self else { return }

            for index in 0..<count {
                if Task.isCancelled || self.playGeneration != generation { return }

                // Wait until this degree's scheduled onset, then light UI.
                let onset = clockBase.advanced(
                    by: .seconds(anchorOffset + gap * Double(index))
                )
                try? await Task.sleep(until: onset, clock: .continuous)
                if Task.isCancelled || self.playGeneration != generation { return }

                self.highlightedPitchClass = cleaned[index]
                self.isPlaying = true

                // Hold UI on this degree until the next onset (or end of last hold).
                let holdEnd = clockBase.advanced(
                    by: .seconds(anchorOffset + gap * Double(index + 1))
                )
                try? await Task.sleep(until: holdEnd, clock: .continuous)
            }

            if Task.isCancelled || self.playGeneration != generation { return }

            // Last note still rings past its step; keep play icon until release completes.
            let lastOnset = anchorOffset + gap * Double(count - 1)
            let audioEnd = lastOnset + Self.phraseFinalSustain + Self.releaseDuration
            try? await Task.sleep(
                until: clockBase.advanced(by: .seconds(audioEnd)),
                clock: .continuous
            )
            if Task.isCancelled || self.playGeneration != generation { return }

            self.highlightedPitchClass = nil
            self.isPlaying = false
            self.sequenceTask = nil
        }
    }

    /// Schedule one pass of notes, each with a soft note-off so long Steinway tails
    /// do not pile into an unmusical wash during fast scale runs.
    @discardableResult
    private func schedulePass(
        sampleKeys: [String],
        anchor: AVAudioTime,
        gap: TimeInterval,
        generation: Int,
        clockBase: ContinuousClock.Instant,
        anchorOffset: TimeInterval
    ) -> Int {
        var scheduled = 0
        let lastIndex = sampleKeys.count - 1
        for (index, key) in sampleKeys.enumerated() {
            let when = engine.time(byOffsetting: anchor, seconds: gap * Double(index))
            guard let voice = engine.play(sampleKey: key, at: when, gain: 1.0) else { continue }
            scheduled += 1

            let sustain: TimeInterval = (index == lastIndex)
                ? Self.phraseFinalSustain
                : Self.sequenceSustain

            // Bind note-off to this voice's ordinal — not playGeneration alone.
            // A later cancel still uses releaseAll(); ordinal guards against releasing a steal.
            let ordinal = voice.currentOrdinal
            let releaseAt = clockBase.advanced(
                by: .seconds(anchorOffset + gap * Double(index) + sustain)
            )
            Task { [weak self, weak voice] in
                try? await Task.sleep(until: releaseAt, clock: .continuous)
                // Skip only if a new phrase superseded this schedule (stop / new chord / new sequence).
                guard let self, self.playGeneration == generation, let voice else { return }
                voice.release(over: Self.releaseDuration, onlyIfOrdinal: ordinal)
            }
        }
        return scheduled
    }

    /// One pitch with octave from full chord/scale context. Always audible (ignores sound toggle).
    func playNote(
        pitchClass: String,
        at index: Int? = nil,
        among context: [String],
        style: NoteVoicing.Style
    ) {
        let cleaned = MusicPitch.normalizePitchClass(pitchClass)
        guard !cleaned.isEmpty else { return }

        let key: String?
        if let resolved = NoteVoicing.sampleKey(
            at: index,
            pitchClass: cleaned,
            among: context,
            style: style
        ) {
            key = resolved
        } else {
            key = NoteVoicing.scaleSampleKeys(pitchClasses: [cleaned]).first
        }
        guard let key else { return }

        // Interrupting a scale/sequence: cut that phrase.
        // Polyphonic single-note taps must NOT cancel each other's note-offs via
        // playGeneration — that left full 6 s sample tails hanging (over-sustain).
        if sequenceTask != nil {
            cancelUITasks(clearHighlight: true)
            engine.releaseAll()
        } else {
            // Keep prior single-note voices ringing; only refresh highlight UI generation.
            highlightTask?.cancel()
            highlightTask = nil
            playGeneration += 1
        }

        let clockBase = ContinuousClock.now
        let anchorOffset = PianoEngine.defaultAnchorOffset
        let when = engine.scheduleAnchor(offset: anchorOffset)
        guard let voice = engine.play(sampleKey: key, at: when, gain: 1.0) else { return }

        let generation = playGeneration
        let ordinal = voice.currentOrdinal
        // Soft note-off bound to this voice ordinal — survives later UI generation bumps
        // and will not release a voice that has since been stolen for a new note.
        Task { [weak voice] in
            let releaseAt = clockBase.advanced(
                by: .seconds(anchorOffset + Self.singleNoteRingDuration)
            )
            try? await Task.sleep(until: releaseAt, clock: .continuous)
            guard let voice else { return }
            voice.release(over: Self.releaseDuration, onlyIfOrdinal: ordinal)
        }

        highlightTask = Task { [weak self] in
            guard let self else { return }
            // Delay highlight + play icon to the same onset as the sample.
            try? await Task.sleep(
                until: clockBase.advanced(by: .seconds(anchorOffset)),
                clock: .continuous
            )
            if Task.isCancelled || self.playGeneration != generation { return }
            self.highlightedPitchClass = cleaned
            self.isPlaying = true

            await self.runPhraseUI(
                generation: generation,
                clockBase: clockBase,
                onset: anchorOffset,
                ringEnd: anchorOffset + Self.singleNoteRingDuration,
                releaseDuration: Self.releaseDuration,
                clearHighlightPitch: cleaned,
                alreadyShowing: true
            )
        }
    }

    func playNote(pitchClass: String) {
        playNote(pitchClass: pitchClass, at: nil, among: [pitchClass], style: .scale)
    }

    func isHighlighting(pitchClass: String) -> Bool {
        guard let active = highlightedPitchClass else { return false }
        let a = MusicPitch.normalizePitchClass(pitchClass)
        let b = MusicPitch.normalizePitchClass(active)
        if a == b { return true }
        guard let sa = MusicPitch.semitone(of: a), let sb = MusicPitch.semitone(of: b) else {
            return false
        }
        return sa == sb
    }

    /// Soft-stop everything (click-free) and clear UI play state. Does not clear loop mode.
    func stop() {
        cancelUITasks(clearHighlight: true)
        engine.releaseAll()
        isPlaying = false
        highlightedPitchClass = nil
    }

    // MARK: - Gain (tests + chord balance)

    /// Public helper for tests / UI: sequenced notes always share this hold length.
    nonisolated static var equalScaleNoteHold: TimeInterval { scaleNoteHold }

    /// Per-voice linear pre-gain for a blocked chord with `noteCount` sounding notes.
    /// Gentle `1/√n` only — samples already carry peak headroom.
    nonisolated static func chordMixGain(noteCount: Int) -> Float {
        PianoEngine.chordPreGain(noteCount: noteCount)
    }

    /// Back-compat alias.
    nonisolated static func mixGain(voiceCount: Int, simultaneous: Bool = true) -> Float {
        if simultaneous {
            return chordMixGain(noteCount: voiceCount)
        }
        let n = max(voiceCount, 1)
        if n == 1 { return 1.0 }
        return Float(1.0 / sqrt(Double(n)))
    }

    // MARK: - Private

    /// Soft-release an earlier phrase at `at` on the shared clock (normally the new onset).
    /// Never fades before the new material is scheduled to speak.
    private func schedulePriorRelease(
        generation: Int,
        clockBase: ContinuousClock.Instant,
        at offset: TimeInterval,
        startedBefore ordinal: UInt64
    ) {
        guard ordinal > 1 else { return }
        Task { [weak self] in
            try? await Task.sleep(
                until: clockBase.advanced(by: .seconds(offset)),
                clock: .continuous
            )
            guard let self, self.playGeneration == generation else { return }
            self.engine.releaseVoices(startedBefore: ordinal, over: Self.releaseDuration)
        }
    }

    /// Drive `isPlaying` (and optional highlight clear) on the same ContinuousClock
    /// grid used for host-time audio: on at `onset`, release at `ringEnd`, off after fade.
    private func runPhraseUI(
        generation: Int,
        clockBase: ContinuousClock.Instant,
        onset: TimeInterval,
        ringEnd: TimeInterval,
        releaseDuration: TimeInterval,
        clearHighlightPitch: String? = nil,
        alreadyShowing: Bool = false
    ) async {
        if !alreadyShowing {
            try? await Task.sleep(
                until: clockBase.advanced(by: .seconds(onset)),
                clock: .continuous
            )
            if Task.isCancelled || playGeneration != generation { return }
            isPlaying = true
        }

        try? await Task.sleep(
            until: clockBase.advanced(by: .seconds(ringEnd)),
            clock: .continuous
        )
        if Task.isCancelled || playGeneration != generation { return }

        // Chord path: fade all voices here. Single-note path already scheduled its own release.
        if clearHighlightPitch == nil {
            engine.releaseAll(over: releaseDuration)
        }

        try? await Task.sleep(
            until: clockBase.advanced(by: .seconds(ringEnd + releaseDuration)),
            clock: .continuous
        )
        if Task.isCancelled || playGeneration != generation { return }

        if let pitch = clearHighlightPitch, highlightedPitchClass == pitch {
            highlightedPitchClass = nil
        }
        if sequenceTask == nil {
            isPlaying = false
        }
    }

    private func cancelUITasks(clearHighlight: Bool) {
        playGeneration += 1
        sequenceTask?.cancel()
        sequenceTask = nil
        highlightTask?.cancel()
        highlightTask = nil
        // Intentionally leave isLoopEnabled alone — it is a mode, not playback state.
        if clearHighlight {
            highlightedPitchClass = nil
        }
    }
}
