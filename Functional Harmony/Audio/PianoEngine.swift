//
//  PianoEngine.swift
//  Functional Harmony
//
//  AVAudioEngine piano with a 32-voice pool, master reverb + PeakLimiter, and session lifecycle.
//

import AVFoundation
import Foundation

/// Owns the audio graph and voice pool. Call from the main actor via `PianoSamplePlayer`.
final class PianoEngine {

    static let shared = PianoEngine()

    /// Sequences pre-schedule every note upfront (a voice is busy from schedule time),
    /// so the pool must cover the longest up-and-back run plus ringing prior audio.
    static let voiceCount = 32
    static let sampleRate: Double = 48_000

    /// Default lead time for scheduled onsets. Must exceed one render quantum
    /// (~10 ms at 512 frames / 48 kHz) so every chord voice waits for the same host time.
    static let defaultAnchorOffset: TimeInterval = 0.040

    /// Master headroom when the PeakLimiter is not installed (Simulator / fallback):
    /// coherent chord sums can exceed full scale without it.
    private static let noLimiterHeadroom: Float = 0.85

    /// Light room on the master bus — dry mono Iowa samples otherwise sound anechoic.
    /// 0…100 wet/dry mix on `AVAudioUnitReverb`.
    private static let reverbWetDryMix: Float = 28

    private let store = PianoSampleStore.shared
    private let processingFormat = PianoSampleStore.processingFormat

    private var engine = AVAudioEngine()
    private var voices: [PianoVoice] = []
    private var reverb: AVAudioUnitReverb?
    private var peakLimiter: AVAudioUnitEffect?
    private var nextOrdinal: UInt64 = 1
    private var roundRobinIndex = 0
    private var isGraphReady = false
    private var didConfigureSession = false

    private var interruptionObserver: NSObjectProtocol?
    private var routeObserver: NSObjectProtocol?
    private var mediaResetObserver: NSObjectProtocol?

    private let lock = NSLock()

    private init() {
        store.startPreloadIfNeeded()
        registerSessionObservers()
    }

    deinit {
        if let interruptionObserver {
            NotificationCenter.default.removeObserver(interruptionObserver)
        }
        if let routeObserver {
            NotificationCenter.default.removeObserver(routeObserver)
        }
        if let mediaResetObserver {
            NotificationCenter.default.removeObserver(mediaResetObserver)
        }
    }

    // MARK: - Session + graph

    /// Ensure the audio session and engine graph are running (idempotent).
    func prepare() {
        lock.lock()
        defer { lock.unlock() }
        configureSessionIfNeededLocked()
        buildGraphIfNeededLocked()
        startEngineIfNeededLocked()
    }

    /// Whether the engine is currently running (diagnostics).
    var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return engine.isRunning
    }

    /// Schedule one sample key at `when` (nil = as soon as possible).
    @discardableResult
    func play(sampleKey: String, at when: AVAudioTime?, gain: Float) -> PianoVoice? {
        prepare()

        lock.lock()
        let running = engine.isRunning
        lock.unlock()
        guard running else {
            #if DEBUG
            print("[PianoEngine] play aborted — engine not running for \(sampleKey)")
            #endif
            return nil
        }

        guard let buffer = store.buffer(for: sampleKey) else {
            #if DEBUG
            print("[PianoEngine] missing buffer for \(sampleKey)")
            #endif
            return nil
        }

        lock.lock()
        let voice = allocateVoiceLocked()
        let ordinal = nextOrdinal
        nextOrdinal &+= 1
        lock.unlock()

        voice.start(buffer: buffer, at: when, gain: gain, ordinal: ordinal)
        return voice
    }

    /// Schedule several sample keys at the same `AVAudioTime` (true simultaneous chord onset).
    @discardableResult
    func playChord(sampleKeys: [String], at when: AVAudioTime?, gainPerVoice: Float) -> Int {
        prepare()
        let gain = min(1, max(0, gainPerVoice))
        var started = 0
        for key in sampleKeys {
            if play(sampleKey: key, at: when, gain: gain) != nil {
                started += 1
            }
        }
        return started
    }

    /// Host-time anchor in the future — beyond one render quantum so scheduled
    /// onsets are honored exactly (no per-voice "asap" fallback flam).
    func scheduleAnchor(offset: TimeInterval = PianoEngine.defaultAnchorOffset) -> AVAudioTime {
        prepare()
        let host = mach_absolute_time() + AVAudioTime.hostTime(forSeconds: max(0.001, offset))
        return AVAudioTime(hostTime: host)
    }

    /// Offset an anchor time by `seconds`, staying on the anchor's own timeline.
    func time(byOffsetting anchor: AVAudioTime, seconds: TimeInterval) -> AVAudioTime {
        if anchor.isHostTimeValid {
            let host = anchor.hostTime + AVAudioTime.hostTime(forSeconds: seconds)
            return AVAudioTime(hostTime: host)
        }
        if anchor.isSampleTimeValid {
            let rate = anchor.sampleRate > 0 ? anchor.sampleRate : Self.sampleRate
            let frames = AVAudioFramePosition((seconds * rate).rounded())
            return AVAudioTime(sampleTime: anchor.sampleTime + frames, atRate: rate)
        }
        return scheduleAnchor(offset: max(0.001, seconds))
    }

    /// Soft-release every busy voice (click-free stop).
    func releaseAll(over duration: TimeInterval = PianoVoice.defaultReleaseDuration) {
        lock.lock()
        let snapshot = voices
        lock.unlock()
        for voice in snapshot where !voice.isAvailable {
            voice.release(over: duration)
        }
    }

    /// Next start ordinal that will be assigned (capture before scheduling a new phrase).
    var nextStartOrdinal: UInt64 {
        lock.lock()
        defer { lock.unlock() }
        return nextOrdinal
    }

    /// Soft-release busy voices from an earlier phrase (`startOrdinal` < `ordinal`).
    /// Lets a new chord/scale start without ducking first — prior audio fades at the
    /// new onset (or later), not during the pre-schedule gap.
    func releaseVoices(startedBefore ordinal: UInt64, over duration: TimeInterval = PianoVoice.defaultReleaseDuration) {
        lock.lock()
        let snapshot = voices
        lock.unlock()
        for voice in snapshot {
            guard !voice.isAvailable else { continue }
            if voice.currentOrdinal < ordinal {
                voice.release(over: duration)
            }
        }
    }

    /// Per-voice linear pre-gain for a blocked chord (`1/√n`).
    /// Samples peak at -3 dBFS; the master limiter (or headroom trim) covers coherent sums.
    static func chordPreGain(noteCount: Int) -> Float {
        let n = max(noteCount, 1)
        if n == 1 { return 1.0 }
        return Float(1.0 / sqrt(Double(n)))
    }

    // MARK: - Voice allocation

    private func allocateVoiceLocked() -> PianoVoice {
        let count = voices.count
        if count == 0 {
            buildGraphIfNeededLocked()
            startEngineIfNeededLocked()
            precondition(!voices.isEmpty, "PianoEngine voice pool empty after build")
            return voices[0]
        }

        for offset in 0..<count {
            let index = (roundRobinIndex + offset) % count
            let voice = voices[index]
            if voice.isAvailable {
                roundRobinIndex = (index + 1) % count
                return voice
            }
        }

        // All busy: steal the oldest (lowest start ordinal).
        var oldest = voices[0]
        var oldestOrdinal = oldest.currentOrdinal
        var oldestIndex = 0
        for (index, voice) in voices.enumerated().dropFirst() {
            let ordinal = voice.currentOrdinal
            if ordinal < oldestOrdinal {
                oldest = voice
                oldestOrdinal = ordinal
                oldestIndex = index
            }
        }
        oldest.prepareForReuse()
        roundRobinIndex = (oldestIndex + 1) % count
        return oldest
    }

    // MARK: - Graph construction (call with `lock` held)

    private func configureSessionIfNeededLocked() {
        guard !didConfigureSession else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredSampleRate(Self.sampleRate)
            try session.setActive(true, options: [])
            didConfigureSession = true
        } catch {
            #if DEBUG
            print("[PianoEngine] session setup failed: \(error)")
            #endif
        }
    }

    private func buildGraphIfNeededLocked() {
        if isGraphReady, !voices.isEmpty, engine.isRunning {
            return
        }
        if isGraphReady, !voices.isEmpty, !engine.isRunning {
            // Graph exists but stopped — try restart without full rebuild first.
            startEngineIfNeededLocked()
            if engine.isRunning { return }
        }
        rebuildGraphLocked(useLimiter: true)
    }

    private func rebuildGraphLocked(useLimiter: Bool) {
        if engine.isRunning {
            engine.stop()
        }
        for voice in voices {
            voice.forceReset()
        }
        voices.removeAll()
        reverb = nil
        peakLimiter = nil
        engine = AVAudioEngine()

        let format = processingFormat
        let mainMixer = engine.mainMixerNode
        mainMixer.outputVolume = 1.0

        // Voice pool: player → sub-mix → main mixer (explicit mono 48 kHz for sample buffers).
        var newVoices: [PianoVoice] = []
        newVoices.reserveCapacity(Self.voiceCount)
        for _ in 0..<Self.voiceCount {
            let voice = PianoVoice()
            voice.attach(to: engine, format: format)
            engine.connect(voice.mixer, to: mainMixer, format: format)
            newVoices.append(voice)
        }
        voices = newVoices

        // Master bus: mainMixer → [reverb] → [peakLimiter?] → output.
        // Reverb first so the limiter sees wet tails and dense chords cannot clip.
        let outFormat = engine.outputNode.inputFormat(forBus: 0)
        let masterTail = installMasterEffectsLocked(
            from: mainMixer,
            outFormat: outFormat,
            useLimiter: useLimiter
        )
        if masterTail == .dryNoLimiter {
            mainMixer.outputVolume = Self.noLimiterHeadroom
            #if DEBUG
            print("[PianoEngine] using default mainMixer → output (no master effects)")
            #endif
        }

        engine.prepare()
        isGraphReady = true
        roundRobinIndex = 0
    }

    private enum MasterTail {
        case dryNoLimiter
        case reverbOnly
        case reverbAndLimiter
        case limiterOnly
    }

    /// Wire optional reverb + PeakLimiter on the master bus. Falls back cleanly.
    private func installMasterEffectsLocked(
        from mainMixer: AVAudioMixerNode,
        outFormat: AVAudioFormat,
        useLimiter: Bool
    ) -> MasterTail {
        let formatReady = outFormat.sampleRate > 0 && outFormat.channelCount > 0

        // Reverb is safe on device and usually fine on Simulator; keep dry if attach fails.
        let reverbNode = makeReverb()
        var hasReverb = false
        if formatReady {
            engine.attach(reverbNode)
            reverb = reverbNode
            hasReverb = true
        }

        #if targetEnvironment(simulator)
        // Simulator: skip PeakLimiter (common silent-graph source); reverb alone is fine.
        if hasReverb {
            engine.disconnectNodeOutput(mainMixer)
            engine.connect(mainMixer, to: reverbNode, format: outFormat)
            engine.connect(reverbNode, to: engine.outputNode, format: outFormat)
            return .reverbOnly
        }
        return .dryNoLimiter
        #else
        let wantLimiter = useLimiter && formatReady
        guard wantLimiter else {
            if hasReverb {
                engine.disconnectNodeOutput(mainMixer)
                engine.connect(mainMixer, to: reverbNode, format: outFormat)
                engine.connect(reverbNode, to: engine.outputNode, format: outFormat)
                return .reverbOnly
            }
            return .dryNoLimiter
        }

        let limiter = makePeakLimiter()
        engine.attach(limiter)
        configurePeakLimiter(limiter)
        peakLimiter = limiter

        engine.disconnectNodeOutput(mainMixer)
        if hasReverb {
            engine.connect(mainMixer, to: reverbNode, format: outFormat)
            engine.connect(reverbNode, to: limiter, format: outFormat)
            engine.connect(limiter, to: engine.outputNode, format: outFormat)
            return .reverbAndLimiter
        }
        engine.connect(mainMixer, to: limiter, format: outFormat)
        engine.connect(limiter, to: engine.outputNode, format: outFormat)
        return .limiterOnly
        #endif
    }

    private func makeReverb() -> AVAudioUnitReverb {
        let unit = AVAudioUnitReverb()
        // Medium room: space around mono samples without smearing chord voicings.
        unit.loadFactoryPreset(.mediumRoom)
        unit.wetDryMix = Self.reverbWetDryMix
        return unit
    }

    private func startEngineIfNeededLocked() {
        guard isGraphReady else { return }
        guard !engine.isRunning else { return }
        do {
            // Re-assert session right before start (Simulator often needs this).
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            #if DEBUG
            print("[PianoEngine] engine started (sr=\(engine.outputNode.inputFormat(forBus: 0).sampleRate))")
            #endif
        } catch {
            #if DEBUG
            print("[PianoEngine] engine.start failed: \(error)")
            #endif
            // Rebuild without limiter once — limiter AU is a common Simulator failure mode.
            isGraphReady = false
            rebuildGraphLocked(useLimiter: false)
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                try engine.start()
                isGraphReady = true
                #if DEBUG
                print("[PianoEngine] engine started after limiter-free rebuild")
                #endif
            } catch {
                isGraphReady = false
                #if DEBUG
                print("[PianoEngine] engine.start retry failed: \(error)")
                #endif
            }
        }
    }

    private func makePeakLimiter() -> AVAudioUnitEffect {
        let description = AudioComponentDescription(
            componentType: kAudioUnitType_Effect,
            componentSubType: kAudioUnitSubType_PeakLimiter,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0
        )
        return AVAudioUnitEffect(audioComponentDescription: description)
    }

    private func configurePeakLimiter(_ unit: AVAudioUnitEffect) {
        // AUPeakLimiter parameters are in SECONDS:
        // 0 AttackTime (0.001–0.03, default 0.012), 1 DecayTime (0.001–0.06, default 0.024),
        // 2 PreGain (dB).
        let au = unit.audioUnit
        AudioUnitSetParameter(au, 0, kAudioUnitScope_Global, 0, 0.012, 0)
        AudioUnitSetParameter(au, 1, kAudioUnitScope_Global, 0, 0.024, 0)
        AudioUnitSetParameter(au, 2, kAudioUnitScope_Global, 0, 0.0, 0)
    }

    // MARK: - Session lifecycle

    private func registerSessionObservers() {
        let center = NotificationCenter.default
        let session = AVAudioSession.sharedInstance()

        interruptionObserver = center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }

        routeObserver = center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }

        mediaResetObserver = center.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            self?.handleMediaServicesReset()
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
        case .began:
            lock.lock()
            if engine.isRunning {
                engine.pause()
            }
            lock.unlock()
        case .ended:
            let options = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map { AVAudioSession.InterruptionOptions(rawValue: $0) } ?? []
            if options.contains(.shouldResume) {
                resumeAfterSessionEvent()
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else { return }

        switch reason {
        case .oldDeviceUnavailable, .newDeviceAvailable, .categoryChange:
            resumeAfterSessionEvent()
        default:
            break
        }
    }

    private func handleMediaServicesReset() {
        lock.lock()
        didConfigureSession = false
        isGraphReady = false
        for voice in voices {
            voice.forceReset()
        }
        lock.unlock()
        prepare()
    }

    private func resumeAfterSessionEvent() {
        lock.lock()
        defer { lock.unlock() }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            #if DEBUG
            print("[PianoEngine] setActive after interruption failed: \(error)")
            #endif
        }
        if !engine.isRunning {
            if isGraphReady {
                do {
                    try engine.start()
                } catch {
                    #if DEBUG
                    print("[PianoEngine] restart after route/interruption failed: \(error)")
                    #endif
                    isGraphReady = false
                    rebuildGraphLocked(useLimiter: false)
                    try? engine.start()
                    isGraphReady = engine.isRunning
                }
            } else {
                rebuildGraphLocked(useLimiter: true)
                try? engine.start()
                isGraphReady = engine.isRunning
            }
        }
    }
}
