import AVFoundation
import Observation

/// Generates spatial audio tones tied to cell birth/death activity.
/// Uses AVAudioEngine with an environment node for 3D positioned sound.
@Observable
@MainActor
final class SpatialAudioEngine {
    var isMuted: Bool = true
    var volume: Float = 0.5 // 0.0 - 1.0

    private var audioEngine: AVAudioEngine?
    private var environmentNode: AVAudioEnvironmentNode?
    private var birthPlayers: [AVAudioPlayerNode] = []
    private var deathPlayers: [AVAudioPlayerNode] = []
    private var birthBuffer: AVAudioPCMBuffer?
    private var deathBuffer: AVAudioPCMBuffer?
    private var nextBirthPlayer: Int = 0
    private var nextDeathPlayer: Int = 0
    private var isSetup = false

    private static let poolSize = 8
    private static let sampleRate: Double = 44100
    private static let baseToneDuration: Double = 0.15 // seconds at ≤5 gen/s

    // Birth: bright ascending tone (C5 to E5)
    private static let birthFreqStart: Float = 523.25  // C5
    private static let birthFreqEnd: Float = 659.25    // E5

    // Death: somber descending tone (A4 to E4)
    private static let deathFreqStart: Float = 440.0   // A4
    private static let deathFreqEnd: Float = 329.63    // E4

    /// Current speed for tone duration scaling. Cached to avoid regenerating buffers every frame.
    private var currentSpeed: Double = 5.0

    func setup() {
        guard !isSetup else { return }

        let engine = AVAudioEngine()
        let envNode = AVAudioEnvironmentNode()

        engine.attach(envNode)
        engine.connect(envNode, to: engine.mainMixerNode, format: nil)

        // Set listener at origin (user position)
        envNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)

        let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1)!

        // Create player pools
        for _ in 0..<Self.poolSize {
            let birthPlayer = AVAudioPlayerNode()
            engine.attach(birthPlayer)
            engine.connect(birthPlayer, to: envNode, format: format)
            birthPlayer.renderingAlgorithm = .HRTFHQ
            birthPlayer.sourceMode = .pointSource
            birthPlayers.append(birthPlayer)

            let deathPlayer = AVAudioPlayerNode()
            engine.attach(deathPlayer)
            engine.connect(deathPlayer, to: envNode, format: format)
            deathPlayer.renderingAlgorithm = .HRTFHQ
            deathPlayer.sourceMode = .pointSource
            deathPlayers.append(deathPlayer)
        }

        // Generate tone buffers at default speed
        regenerateToneBuffers(forSpeed: 5.0)

        do {
            try engine.start()
            for player in birthPlayers { player.play() }
            for player in deathPlayers { player.play() }
            audioEngine = engine
            environmentNode = envNode
            isSetup = true
        } catch {
            print("SpatialAudioEngine: failed to start: \(error)")
        }
    }

    /// Computes tone duration scaled to simulation speed.
    /// At ≤5 gen/s, use full base duration. At higher speeds, shorten proportionally
    /// so tones don't overlap between generations.
    private static func toneDuration(forSpeed speed: Double) -> Double {
        let effectiveSpeed = max(speed, 1.0)
        if effectiveSpeed <= 5.0 { return baseToneDuration }
        // Scale inversely: at 10 gen/s → 75ms, at 20 gen/s → 50ms, at 30 gen/s → 40ms
        // Floor at 40ms to keep tones audible
        return max(0.04, baseToneDuration * (5.0 / effectiveSpeed))
    }

    /// Regenerates tone buffers when speed changes enough to matter.
    private func regenerateToneBuffers(forSpeed speed: Double) {
        let duration = Self.toneDuration(forSpeed: speed)
        birthBuffer = Self.generateTone(
            startFreq: Self.birthFreqStart,
            endFreq: Self.birthFreqEnd,
            duration: duration,
            sampleRate: Self.sampleRate,
            envelope: .bellCurve
        )
        deathBuffer = Self.generateTone(
            startFreq: Self.deathFreqStart,
            endFreq: Self.deathFreqEnd,
            duration: duration * 1.5, // death tones slightly longer
            sampleRate: Self.sampleRate,
            envelope: .fadeOut
        )
        currentSpeed = speed
    }

    /// Updates tone buffers if the simulation speed has changed significantly.
    func updateSpeed(_ speed: Double) {
        // Only regenerate if speed changed by more than 20% to avoid constant buffer churn
        let ratio = speed / max(currentSpeed, 0.1)
        if ratio < 0.8 || ratio > 1.25 {
            regenerateToneBuffers(forSpeed: speed)
        }
    }

    /// Triggers spatial tones at birth/death positions.
    /// Positions are in grid local space (meters, centered at origin).
    func triggerTones(birthPositions: [SIMD3<Float>], deathPositions: [SIMD3<Float>]) {
        guard isSetup, !isMuted else { return }

        // Scale activity to volume — busier regions play more tones
        let birthCount = min(birthPositions.count, Self.poolSize)
        let deathCount = min(deathPositions.count, Self.poolSize)

        // Sample positions evenly
        let birthSample = samplePositions(birthPositions, count: birthCount)
        let deathSample = samplePositions(deathPositions, count: deathCount)

        // Scale volume by activity density (more activity = slightly louder)
        let activityScale = min(1.0, Float(birthPositions.count + deathPositions.count) / 200.0)
        let effectiveVolume = volume * (0.3 + 0.7 * activityScale)

        for pos in birthSample {
            playTone(players: birthPlayers, buffer: birthBuffer, position: pos,
                    playerIndex: &nextBirthPlayer, volume: effectiveVolume)
        }

        for pos in deathSample {
            playTone(players: deathPlayers, buffer: deathBuffer, position: pos,
                    playerIndex: &nextDeathPlayer, volume: effectiveVolume * 0.6) // death tones quieter
        }
    }

    func stop() {
        audioEngine?.stop()
        isSetup = false
    }

    // MARK: - Private

    private func playTone(players: [AVAudioPlayerNode], buffer: AVAudioPCMBuffer?,
                          position: SIMD3<Float>, playerIndex: inout Int, volume: Float) {
        guard let buffer else { return }
        let player = players[playerIndex]
        playerIndex = (playerIndex + 1) % players.count

        // Position the player in 3D space (scale up for audible separation)
        player.position = AVAudio3DPoint(x: position.x * 5, y: position.y * 5, z: position.z * 5)
        player.volume = volume

        // Schedule the tone (non-overlapping: interrupts previous if still playing)
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }

    private func samplePositions(_ positions: [SIMD3<Float>], count: Int) -> [SIMD3<Float>] {
        guard !positions.isEmpty, count > 0 else { return [] }
        if positions.count <= count { return Array(positions.prefix(count)) }
        let step = positions.count / count
        return (0..<count).map { positions[$0 * step] }
    }

    // MARK: - Tone Generation

    private enum Envelope {
        case bellCurve   // smooth attack and decay
        case fadeOut      // sharp attack, gradual decay
    }

    private static func generateTone(startFreq: Float, endFreq: Float, duration: Double,
                                      sampleRate: Double, envelope: Envelope) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount

        guard let data = buffer.floatChannelData?[0] else { return nil }

        let totalSamples = Float(frameCount)
        for i in 0..<Int(frameCount) {
            let t = Float(i) / totalSamples // 0.0 to 1.0
            let freq = startFreq + (endFreq - startFreq) * t
            let phase = 2.0 * Float.pi * freq * Float(i) / Float(sampleRate)
            var sample = sinf(phase)

            // Apply envelope
            let envelopeValue: Float
            switch envelope {
            case .bellCurve:
                // Gaussian-ish bell: peaks at 0.3, smooth attack and decay
                let peak: Float = 0.3
                let width: Float = 0.25
                envelopeValue = expf(-((t - peak) * (t - peak)) / (2 * width * width))
            case .fadeOut:
                // Quick attack (first 10%), linear fade
                if t < 0.1 {
                    envelopeValue = t / 0.1
                } else {
                    envelopeValue = 1.0 - ((t - 0.1) / 0.9)
                }
            }

            sample *= envelopeValue * 0.3 // 0.3 master volume to keep tones subtle
            data[i] = sample
        }

        return buffer
    }
}
