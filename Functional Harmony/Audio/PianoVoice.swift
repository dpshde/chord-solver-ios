//
//  PianoVoice.swift
//  Functional Harmony
//
//  One AVAudioPlayerNode + dedicated sub-mixer for per-voice gain and release fades.
//

import AVFoundation
import Foundation

/// A single polyphonic voice: player node feeding a private mixer for gain/release.
final class PianoVoice {

    let player = AVAudioPlayerNode()
    let mixer = AVAudioMixerNode()

    /// Monotonic counter assigned by the engine when a note starts (steal oldest).
    private(set) var startOrdinal: UInt64 = 0
    private(set) var isBusy = false
    private(set) var isReleasing = false

    /// Bumped on every start/forceReset so in-flight fades cannot clobber a new note.
    private var epoch: UInt64 = 0
    private var fadeTimer: DispatchSourceTimer?
    private let stateQueue = DispatchQueue(label: "com.functionalharmony.pianovoice")

    /// Soft release before an intentional stop (phrase change / user stop).
    /// Long enough to span several render quanta so the mixer actually ramps.
    static let defaultReleaseDuration: TimeInterval = 0.050

    /// Fade step interval; ~2 volume updates per typical 10 ms render quantum.
    private static let fadeStepInterval: TimeInterval = 0.005

    /// Attach player → sub-mixer inside `engine` and connect with `format`.
    func attach(to engine: AVAudioEngine, format: AVAudioFormat) {
        engine.attach(player)
        engine.attach(mixer)
        engine.connect(player, to: mixer, format: format)
        mixer.outputVolume = 1
    }

    /// Schedule `buffer` at an explicit `AVAudioTime` (nil = as soon as possible).
    /// `gain` is the sub-mixer level — applied at full target before the buffer is heard.
    func start(
        buffer: AVAudioPCMBuffer,
        at time: AVAudioTime?,
        gain: Float,
        ordinal: UInt64
    ) {
        stateQueue.sync {
            cancelFadeLocked()
            epoch &+= 1
            let startEpoch = epoch

            if player.isPlaying {
                player.stop()
            }

            mixer.outputVolume = max(0, min(gain, 1))
            startOrdinal = ordinal
            isBusy = true
            isReleasing = false

            player.scheduleBuffer(
                buffer,
                at: time,
                options: [],
                completionCallbackType: .dataPlayedBack
            ) { [weak self] _ in
                self?.handleBufferFinished(expectedEpoch: startEpoch)
            }
            player.play()
        }
    }

    /// Fade the sub-mixer to silence, then stop the player (click-free early cut).
    /// When `onlyIfOrdinal` is set, no-ops if this voice has been stolen or restarted
    /// (prevents a late Task from releasing a newer note on the same node).
    func release(
        over duration: TimeInterval = PianoVoice.defaultReleaseDuration,
        onlyIfOrdinal: UInt64? = nil
    ) {
        stateQueue.async { [weak self] in
            guard let self else { return }
            if let onlyIfOrdinal, self.startOrdinal != onlyIfOrdinal { return }
            guard self.isBusy, !self.isReleasing else { return }

            self.isReleasing = true
            self.cancelFadeLocked()
            let releaseEpoch = self.epoch
            let startVolume = self.mixer.outputVolume

            if duration <= 0 || startVolume <= 0.0001 {
                self.finishReleaseLocked(expectedEpoch: releaseEpoch)
                return
            }

            let interval = Self.fadeStepInterval
            let steps = max(2, Int((duration / interval).rounded()))
            var step = 0

            let timer = DispatchSource.makeTimerSource(queue: self.stateQueue)
            timer.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(1))
            timer.setEventHandler { [weak self] in
                guard let self else { return }
                guard self.epoch == releaseEpoch else {
                    self.cancelFadeLocked()
                    return
                }
                step += 1
                let t = Float(step) / Float(steps)
                let s = t * t * (3 - 2 * t)
                self.mixer.outputVolume = max(0, startVolume * (1 - s))
                if step >= steps {
                    self.cancelFadeLocked()
                    self.finishReleaseLocked(expectedEpoch: releaseEpoch)
                }
            }
            self.fadeTimer = timer
            timer.resume()
        }
    }

    /// Immediate stop before voice steal. Rare with a 32-voice pool; sequence note-offs
    /// free voices early, so steals mostly hit already-quiet tails.
    func prepareForReuse() {
        stateQueue.sync {
            hardStopLocked(resetOrdinal: false)
        }
    }

    /// Hard-reset for engine teardown / media-services rebuild (no fade).
    func forceReset() {
        stateQueue.sync {
            hardStopLocked(resetOrdinal: true)
        }
    }

    var isAvailable: Bool {
        stateQueue.sync { !isBusy }
    }

    /// Thread-safe ordinal read for steal-oldest selection.
    var currentOrdinal: UInt64 {
        stateQueue.sync { startOrdinal }
    }

    // MARK: - Private (all *Locked methods run on stateQueue)

    private func hardStopLocked(resetOrdinal: Bool) {
        cancelFadeLocked()
        epoch &+= 1
        mixer.outputVolume = 1
        if player.isPlaying {
            player.stop()
        }
        isBusy = false
        isReleasing = false
        if resetOrdinal {
            startOrdinal = 0
        }
    }

    private func cancelFadeLocked() {
        fadeTimer?.cancel()
        fadeTimer = nil
    }

    private func handleBufferFinished(expectedEpoch: UInt64) {
        stateQueue.async { [weak self] in
            guard let self else { return }
            guard self.epoch == expectedEpoch else { return }
            if self.isReleasing { return }
            self.cancelFadeLocked()
            self.mixer.outputVolume = 1
            self.isBusy = false
            self.isReleasing = false
        }
    }

    private func finishReleaseLocked(expectedEpoch: UInt64) {
        guard epoch == expectedEpoch else { return }
        mixer.outputVolume = 1
        if player.isPlaying {
            player.stop()
        }
        isBusy = false
        isReleasing = false
    }
}
