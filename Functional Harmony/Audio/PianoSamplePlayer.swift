//
//  PianoSamplePlayer.swift
//  Functional Harmony
//
//  Simple sample player for Canon-derived piano CAF files.
//  Uses AVAudioPlayer (not AVAudioEngine) so one-shot chords/scales do not
//  trip engine-graph Initialize crashes on Simulator.
//
//  Audio strategy (from Canon docs/DSP-learnings + click-debug-analysis):
//  - Samples bake a short fade-in + peak headroom (volume automation is NOT
//    sample-accurate on AVAudioPlayer — ramping set_volume causes clicks).
//  - Blocked chords use correlation-aware gain, not plain 1/√n.
//  - Every public play hard-kills all live audio first so each start is clean.
//

import AVFoundation
import Foundation

/// Plays block chords and ascending scale sequences from bundled piano samples.
@MainActor
final class PianoSamplePlayer: ObservableObject {

    static let shared = PianoSamplePlayer()

    /// UserDefaults key shared with the result-panel sound toggle.
    static let soundEnabledKey = "resultAudio.soundEnabled"

    /// Samples are peak-limited with baked attack; play near full without extra ramps.
    private static let fullNoteGain: Float = 1.0

    /// How long a single-note highlight stays after attack.
    private static let singleNoteHighlightNanos: UInt64 = 450_000_000

    /// Hold time for every sequenced scale degree (including the last).
    /// Same duration for each note so the run feels even — no long final ring-out.
    private static let scaleNoteHold: TimeInterval = 0.30

    @Published private(set) var isPlaying = false

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

    /// Every player that might still be audible (active or mid-release).
    private var livePlayers: [AVAudioPlayer] = []
    private var sequenceTask: Task<Void, Never>?
    private var lifecycleTask: Task<Void, Never>?
    private var didConfigureSession = false
    /// Bumped on every fresh start so in-flight tasks cannot touch new playback.
    private var playGeneration = 0

    private init() {}

    // MARK: - Public API

    func playChord(pitchClasses: [String]) {
        guard isSoundEnabled else { return }
        let keys = NoteVoicing.chordSampleKeys(pitchClasses: pitchClasses)
        guard !keys.isEmpty else { return }
        beginFreshPlayback()
        playSimultaneous(sampleKeys: keys, highlightPitchClass: nil)
    }

    /// Ascending sequence; each step is a clean sample start (no residual voices).
    /// Every note (including the last) is held for the same `noteHold` duration.
    /// Octaves match full-scale voicing.
    func playSequence(pitchClasses: [String], noteHold: TimeInterval = scaleNoteHold) {
        guard isSoundEnabled else { return }
        let cleaned = NoteVoicing.cleanedPitchClasses(pitchClasses)
        let keys = NoteVoicing.scaleSampleKeys(pitchClasses: cleaned)
        guard !cleaned.isEmpty, cleaned.count == keys.count else { return }

        beginFreshPlayback()
        let generation = playGeneration
        isPlaying = true
        sequenceTask = Task { [weak self] in
            guard let self else { return }
            await self.playSequenced(
                pitchClasses: cleaned,
                sampleKeys: keys,
                noteHold: max(0.05, noteHold),
                generation: generation
            )
        }
    }

    /// One pitch with octave from full chord/scale context. Always audible.
    func playNote(
        pitchClass: String,
        at index: Int? = nil,
        among context: [String],
        style: NoteVoicing.Style
    ) {
        let cleaned = MusicPitch.normalizePitchClass(pitchClass)
        guard !cleaned.isEmpty else { return }

        if let key = NoteVoicing.sampleKey(
            at: index,
            pitchClass: cleaned,
            among: context,
            style: style
        ) {
            beginFreshPlayback()
            playSimultaneous(sampleKeys: [key], highlightPitchClass: cleaned)
            return
        }

        let keys = NoteVoicing.scaleSampleKeys(pitchClasses: [cleaned])
        guard !keys.isEmpty else { return }
        beginFreshPlayback()
        playSimultaneous(sampleKeys: keys, highlightPitchClass: cleaned)
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

    /// Hard-stop everything and clear UI play state.
    func stop() {
        beginFreshPlayback()
    }

    // MARK: - Fresh start

    /// Cancel tasks, stop every live player, bump generation. Next audio starts clean.
    private func beginFreshPlayback() {
        playGeneration += 1

        sequenceTask?.cancel()
        sequenceTask = nil
        lifecycleTask?.cancel()
        lifecycleTask = nil

        killAllLivePlayers()

        isPlaying = false
        highlightedPitchClass = nil
    }

    private func killAllLivePlayers() {
        for player in livePlayers {
            player.stop()
            player.currentTime = 0
        }
        livePlayers.removeAll()
    }

    // MARK: - Playback

    private func ensureSession() {
        guard !didConfigureSession else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            didConfigureSession = true
        } catch {
            #if DEBUG
            print("[PianoSamplePlayer] session setup failed: \(error)")
            #endif
        }
    }

    private func playSimultaneous(sampleKeys: [String], highlightPitchClass: String?) {
        // Caller must have already called `beginFreshPlayback()`.
        ensureSession()
        let generation = playGeneration

        // Build players first, then set gain from the *actual* voice count that loaded.
        var players: [AVAudioPlayer] = []
        for key in sampleKeys {
            guard let player = makeFreshPlayer(sampleKey: key, volume: 1) else { continue }
            players.append(player)
        }
        guard !players.isEmpty else { return }

        // Chord / multi-note: scale per voice so summed level stays even as N grows.
        // Single-note (highlight path) uses full level.
        let gain = Self.chordMixGain(noteCount: players.count)
        for player in players {
            player.volume = gain
            player.currentTime = 0
        }

        livePlayers.append(contentsOf: players)
        isPlaying = true
        highlightedPitchClass = highlightPitchClass
        for player in players {
            player.play()
        }

        let highlightClear = highlightPitchClass != nil ? Self.singleNoteHighlightNanos : 2_200_000_000
        lifecycleTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: highlightClear)
            await MainActor.run {
                guard let self, self.playGeneration == generation else { return }
                if highlightPitchClass != nil {
                    self.highlightedPitchClass = nil
                }
            }
            if highlightPitchClass != nil {
                let remaining = 2_200_000_000 > highlightClear ? 2_200_000_000 - highlightClear : 0
                if remaining > 0 {
                    try? await Task.sleep(nanoseconds: remaining)
                }
            }
            await MainActor.run {
                guard let self, self.playGeneration == generation else { return }
                self.killAllLivePlayers()
                self.isPlaying = false
                self.highlightedPitchClass = nil
            }
        }
    }

    private func playSequenced(
        pitchClasses: [String],
        sampleKeys: [String],
        noteHold: TimeInterval,
        generation: Int
    ) async {
        ensureSession()
        let gain = Self.fullNoteGain
        let count = min(pitchClasses.count, sampleKeys.count)
        let holdNanos = UInt64(noteHold * 1_000_000_000)

        for index in 0..<count {
            if Task.isCancelled || playGeneration != generation { return }

            // Clean start for every scale degree: kill anything still sounding.
            killAllLivePlayers()
            highlightedPitchClass = nil

            let pitchClass = pitchClasses[index]
            let key = sampleKeys[index]
            guard let player = makeFreshPlayer(sampleKey: key, volume: gain) else {
                // Still consume the same hold so timing stays even if a sample is missing.
                try? await Task.sleep(nanoseconds: holdNanos)
                continue
            }

            highlightedPitchClass = pitchClass
            isPlaying = true
            livePlayers.append(player)
            player.currentTime = 0
            player.play()

            // Equal duration for every note — including the last (no special long ring-out).
            try? await Task.sleep(nanoseconds: holdNanos)
            if Task.isCancelled || playGeneration != generation { return }
            killAllLivePlayers()
            highlightedPitchClass = nil
        }

        guard playGeneration == generation else { return }
        isPlaying = false
        highlightedPitchClass = nil
    }

    /// Public helper for tests / UI: sequenced notes always share this hold length.
    nonisolated static var equalScaleNoteHold: TimeInterval { scaleNoteHold }

    /// Per-voice linear gain for a blocked chord with `noteCount` sounding notes.
    ///
    /// - 1 note → full level
    /// - More notes → each quieter so overall loudness stays even
    /// - Coherent piano attacks don't clip (blend of 1/√n and Canon correlation)
    nonisolated static func chordMixGain(noteCount: Int) -> Float {
        let n = max(noteCount, 1)
        if n == 1 { return 1.0 }

        let energy = Float(1.0 / sqrt(Double(n)))
        // Canon uses ~0.8 for fully blocked chords; 0.6 keeps lines a bit louder.
        let correlation: Float = 0.6
        let correlated = 1.0 / (1.0 + Float(n - 1) * correlation)
        let blended = 0.6 * energy + 0.4 * correlated
        // Never louder than mono; keep dense chords audible on phone speakers.
        return min(1.0, max(0.30, blended))
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

    // MARK: - Samples

    /// Always a new player at buffer start — never reuse a mid-stream instance.
    private func makeFreshPlayer(sampleKey: String, volume: Float) -> AVAudioPlayer? {
        guard let url = sampleURL(for: sampleKey) else {
            #if DEBUG
            print("[PianoSamplePlayer] missing sample: \(sampleKey)")
            #endif
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = min(max(volume, 0), 1)
            player.currentTime = 0
            player.prepareToPlay()
            return player
        } catch {
            #if DEBUG
            print("[PianoSamplePlayer] failed to load \(sampleKey): \(error)")
            #endif
            return nil
        }
    }

    private func sampleURL(for sampleKey: String) -> URL? {
        let base = MusicPitch.resourceBaseName(sampleKey: sampleKey)
        if let url = Bundle.main.url(forResource: base, withExtension: "caf", subdirectory: "Samples") {
            return url
        }
        return Bundle.main.url(forResource: base, withExtension: "caf")
    }
}
