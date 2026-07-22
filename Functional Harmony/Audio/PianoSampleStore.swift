//
//  PianoSampleStore.swift
//  Functional Harmony
//
//  Decodes bundled mono piano CAF samples into float32 PCM buffers.
//  Preloads on a background task; lookups block only until the requested key is ready.
//

import AVFoundation
import Foundation

/// Thread-safe cache of decoded piano sample buffers keyed by sample stem (e.g. `Cs3`).
final class PianoSampleStore: @unchecked Sendable {

    static let shared = PianoSampleStore()

    /// Mono float32 48 kHz — matches the bundled CAF sample rate.
    static let processingFormat: AVAudioFormat = {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48_000,
            channels: 1,
            interleaved: false
        ) else {
            fatalError("Failed to create mono float32 48 kHz format")
        }
        return format
    }()

    private let lock = NSLock()
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var loadErrors: Set<String> = []
    private var preloadStarted = false
    /// Signaled when a specific key finishes loading (success or failure).
    private var waiters: [String: [DispatchSemaphore]] = [:]

    private init() {}

    // MARK: - Public

    /// Kick off background preload of every bundled `*_pno.caf` sample (idempotent).
    func startPreloadIfNeeded() {
        lock.lock()
        if preloadStarted {
            lock.unlock()
            return
        }
        preloadStarted = true
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.preloadAll()
        }
    }

    /// Returns a decoded buffer for `sampleKey` (e.g. `C4`), waiting if still loading.
    /// First tap is never silent: decodes that key immediately if preload has not finished it yet.
    func buffer(for sampleKey: String) -> AVAudioPCMBuffer? {
        startPreloadIfNeeded()

        lock.lock()
        if let existing = buffers[sampleKey] {
            lock.unlock()
            return existing
        }
        if loadErrors.contains(sampleKey) {
            lock.unlock()
            return nil
        }
        lock.unlock()

        // Lazy fallback: decode the requested key now so the first tap is never silent.
        if let decoded = decodeSample(sampleKey: sampleKey) {
            store(buffer: decoded, for: sampleKey, failed: false)
            return decoded
        }

        // Another path may be mid-decode; wait briefly.
        waitUntilReady(sampleKey, timeoutSeconds: 2.0)

        lock.lock()
        let result = buffers[sampleKey]
        lock.unlock()
        return result
    }

    /// Snapshot of currently loaded keys (tests / diagnostics).
    var loadedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return buffers.count
    }

    // MARK: - Preload

    private func preloadAll() {
        let keys = discoverSampleKeys()
        for key in keys {
            lock.lock()
            let already = buffers[key] != nil || loadErrors.contains(key)
            lock.unlock()
            if already { continue }

            if let buffer = decodeSample(sampleKey: key) {
                store(buffer: buffer, for: key, failed: false)
            } else {
                store(buffer: nil, for: key, failed: true)
            }
        }
    }

    private func store(buffer: AVAudioPCMBuffer?, for sampleKey: String, failed: Bool) {
        lock.lock()
        if let buffer {
            buffers[sampleKey] = buffer
        } else if failed {
            loadErrors.insert(sampleKey)
        }
        let pending = waiters.removeValue(forKey: sampleKey) ?? []
        lock.unlock()
        for semaphore in pending {
            semaphore.signal()
        }
    }

    private func waitUntilReady(_ sampleKey: String, timeoutSeconds: TimeInterval) {
        let semaphore = DispatchSemaphore(value: 0)

        lock.lock()
        if buffers[sampleKey] != nil || loadErrors.contains(sampleKey) {
            lock.unlock()
            return
        }
        waiters[sampleKey, default: []].append(semaphore)
        lock.unlock()

        _ = semaphore.wait(timeout: .now() + timeoutSeconds)
    }

    private func discoverSampleKeys() -> [String] {
        var found = Set<String>()

        if let urls = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: "Samples") {
            for url in urls {
                if let key = sampleKey(fromResourceURL: url) {
                    found.insert(key)
                }
            }
        }
        if let urls = Bundle.main.urls(forResourcesWithExtension: "caf", subdirectory: nil) {
            for url in urls {
                if let key = sampleKey(fromResourceURL: url) {
                    found.insert(key)
                }
            }
        }

        // Safety net if resource enumeration is empty (e.g. certain test hosts).
        if found.isEmpty {
            let stems = ["C", "Cs", "D", "Ds", "E", "F", "Fs", "G", "Gs", "A", "As", "B"]
            for octave in 1...5 {
                for stem in stems {
                    let key = "\(stem)\(octave)"
                    if sampleURL(for: key) != nil {
                        found.insert(key)
                    }
                }
            }
        }
        return found.sorted()
    }

    private func sampleKey(fromResourceURL url: URL) -> String? {
        let base = url.deletingPathExtension().lastPathComponent
        guard base.hasSuffix("_pno") else { return nil }
        return String(base.dropLast(4))
    }

    // MARK: - Decode

    private func decodeSample(sampleKey: String) -> AVAudioPCMBuffer? {
        guard let url = sampleURL(for: sampleKey) else {
            #if DEBUG
            print("[PianoSampleStore] missing sample: \(sampleKey)")
            #endif
            return nil
        }
        do {
            let file = try AVAudioFile(forReading: url)
            let sourceFormat = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)
            guard frameCount > 0 else { return nil }

            guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
                return nil
            }
            try file.read(into: sourceBuffer)
            guard sourceBuffer.frameLength > 0 else { return nil }

            let target = Self.processingFormat
            let floatBuffer: AVAudioPCMBuffer
            // Already mono float32 48 kHz — use as-is.
            if sourceFormat.sampleRate == target.sampleRate,
               sourceFormat.channelCount == target.channelCount,
               sourceFormat.commonFormat == target.commonFormat {
                floatBuffer = sourceBuffer
            } else {
                // Convert Int16 / other layouts → mono float32 48 kHz for the voice graph.
                guard let converter = AVAudioConverter(from: sourceFormat, to: target) else {
                    #if DEBUG
                    print("[PianoSampleStore] converter failed for \(sampleKey) \(sourceFormat) → \(target)")
                    #endif
                    return nil
                }

                let ratio = target.sampleRate / max(sourceFormat.sampleRate, 1)
                let destFrames = AVAudioFrameCount(Double(sourceBuffer.frameLength) * ratio) + 32
                guard let dest = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: destFrames) else {
                    return nil
                }

                var error: NSError?
                var inputProvided = false
                let status = converter.convert(to: dest, error: &error) { _, outStatus in
                    if inputProvided {
                        outStatus.pointee = .endOfStream
                        return nil
                    }
                    inputProvided = true
                    outStatus.pointee = .haveData
                    return sourceBuffer
                }
                if status == .error || error != nil {
                    #if DEBUG
                    print("[PianoSampleStore] convert error for \(sampleKey): \(String(describing: error)) status=\(status.rawValue)")
                    #endif
                    return nil
                }
                guard dest.frameLength > 0 else {
                    #if DEBUG
                    print("[PianoSampleStore] zero frames after convert for \(sampleKey)")
                    #endif
                    return nil
                }
                floatBuffer = dest
            }

            // Steinway samples already include a short pre-attack and a natural decay tail.
            // Only force the final sample to zero so a natural buffer end never clicks —
            // never re-fade the attack (that ducks every chord/scale onset).
            forceTerminalSilence(on: floatBuffer)
            return floatBuffer
        } catch {
            #if DEBUG
            print("[PianoSampleStore] failed to load \(sampleKey): \(error)")
            #endif
            return nil
        }
    }

    /// Ensure the last few frames reach exact silence (click-free natural ends only).
    private func forceTerminalSilence(on buffer: AVAudioPCMBuffer) {
        guard buffer.format.commonFormat == .pcmFormatFloat32,
              buffer.format.channelCount >= 1,
              let channels = buffer.floatChannelData
        else { return }

        let frameCount = Int(buffer.frameLength)
        guard frameCount > 8 else { return }

        let data = channels[0]
        let tail = min(8, frameCount)
        let start = frameCount - tail
        for i in 0..<tail {
            let t = Float(i + 1) / Float(tail)
            data[start + i] *= (1 - t)
        }
        data[frameCount - 1] = 0
    }

    private func sampleURL(for sampleKey: String) -> URL? {
        let base = MusicPitch.resourceBaseName(sampleKey: sampleKey)
        if let url = Bundle.main.url(forResource: base, withExtension: "caf", subdirectory: "Samples") {
            return url
        }
        return Bundle.main.url(forResource: base, withExtension: "caf")
    }
}
