import Foundation
import AVFoundation

/// Contract for playing and stopping persistent alarm ringing audio.
public protocol AudioPlayerServiceProtocol: AnyObject, Sendable {
    var isRinging: Bool { get }
    var currentSound: SoundAsset? { get }
    var currentVolume: Float { get }
    func playRinging(sound: SoundAsset, volume: Float, looping: Bool) throws
    func stopRinging()
}

/// Production audio service utilizing `AVAudioPlayer` with real-time PCM wave synthesis fallback
/// and `AVAudioSession.Category.playback` on iOS to override the hardware silent switch.
public final class AVAudioRingingService: NSObject, AudioPlayerServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var audioPlayer: AVAudioPlayer?
    private var isPlayingInternal: Bool = false
    private var currentSoundInternal: SoundAsset? = nil
    private var currentVolumeInternal: Float = 0.0

    public var isRinging: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isPlayingInternal
    }

    public var currentSound: SoundAsset? {
        lock.lock()
        defer { lock.unlock() }
        return currentSoundInternal
    }

    public var currentVolume: Float {
        lock.lock()
        defer { lock.unlock() }
        return currentVolumeInternal
    }

    public override init() {
        super.init()
        configureAudioSession()
    }

    private func configureAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
        } catch {
            // Non-fatal in simulator / headless test runner
        }
        #endif
    }

    public func playRinging(sound: SoundAsset, volume: Float, looping: Bool = true) throws {
        lock.lock()
        defer { lock.unlock() }

        let clampedVolume = min(max(volume, 0.0), 1.0)
        currentSoundInternal = sound
        currentVolumeInternal = clampedVolume

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        if let url = Bundle.main.url(forResource: sound.fileName, withExtension: sound.fileExtension) {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = looping ? -1 : 0
            player.volume = clampedVolume
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player
        } else if let wavData = Self.synthesizeToneWAV(for: sound) {
            if let player = try? AVAudioPlayer(data: wavData) {
                player.numberOfLoops = looping ? -1 : 0
                player.volume = clampedVolume
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
            }
        }

        isPlayingInternal = true
    }

    public func stopRinging() {
        lock.lock()
        defer { lock.unlock() }

        audioPlayer?.stop()
        audioPlayer = nil
        isPlayingInternal = false
        currentSoundInternal = nil
        currentVolumeInternal = 0.0

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    /// Synthesizes an in-memory 16-bit PCM WAV buffer tailored to each `SoundAsset` frequency profile.
    public static func synthesizeToneWAV(for sound: SoundAsset, durationSeconds: Double = 1.2) -> Data? {
        let sampleRate = 44100
        let totalSamples = Int(Double(sampleRate) * durationSeconds)
        guard totalSamples > 0 else { return nil }

        let baseFreq: Double
        let modFreq: Double
        switch sound {
        case .radar:       baseFreq = 880.0; modFreq = 4.0
        case .beacon:      baseFreq = 660.0; modFreq = 2.5
        case .chimes:      baseFreq = 528.0; modFreq = 1.5
        case .circuit:     baseFreq = 987.77; modFreq = 6.0
        case .classicBell: baseFreq = 784.0; modFreq = 8.0
        case .digital:     baseFreq = 1046.5; modFreq = 5.0
        case .gentleRise:    baseFreq = 440.0; modFreq = 1.0
        case .systemDefault: baseFreq = 740.0; modFreq = 3.0
        case .apex:          baseFreq = 830.61; modFreq = 4.5
        case .breeze:        baseFreq = 587.33; modFreq = 2.0
        case .cosmic:        baseFreq = 659.25; modFreq = 3.5
        }

        var pcmData = Data(capacity: totalSamples * 2)
        for i in 0..<totalSamples {
            let t = Double(i) / Double(sampleRate)
            let envelope = sin(Double.pi * modFreq * t) > 0 ? 1.0 : 0.15
            let carrier = sin(2.0 * Double.pi * baseFreq * t) + 0.3 * sin(4.0 * Double.pi * baseFreq * t)
            let sampleValue = max(-1.0, min(1.0, carrier * envelope * 0.5))
            var intSample = Int16(sampleValue * Double(Int16.max)).littleEndian
            withUnsafeBytes(of: &intSample) { pcmData.append(contentsOf: $0) }
        }

        var wav = Data()
        let dataSize = UInt32(pcmData.count)
        let fileSize = UInt32(36 + dataSize)
        wav.append("RIFF".data(using: .ascii)!)
        wav.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        wav.append("WAVEfmt ".data(using: .ascii)!)
        let fmtChunkSize: UInt32 = 16
        let audioFormat: UInt16 = 1 // PCM
        let numChannels: UInt16 = 1
        let sRate = UInt32(sampleRate)
        let byteRate = UInt32(sampleRate * 2)
        let blockAlign: UInt16 = 2
        let bitsPerSample: UInt16 = 16
        wav.append(withUnsafeBytes(of: fmtChunkSize.littleEndian) { Data($0) })
        wav.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        wav.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        wav.append(withUnsafeBytes(of: sRate.littleEndian) { Data($0) })
        wav.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        wav.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        wav.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        wav.append("data".data(using: .ascii)!)
        wav.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        wav.append(pcmData)
        return wav
    }
}

/// Deterministic mock audio player for unit and E2E tests.
public final class MockAudioPlayerService: AudioPlayerServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    public private(set) var isRinging: Bool = false
    public private(set) var currentSound: SoundAsset? = nil
    public private(set) var currentVolume: Float = 0.0
    public private(set) var playCount: Int = 0
    public private(set) var stopCount: Int = 0
    public private(set) var lastLooping: Bool = false

    public init() {}

    public func playRinging(sound: SoundAsset, volume: Float, looping: Bool) throws {
        lock.lock()
        defer { lock.unlock() }
        isRinging = true
        currentSound = sound
        currentVolume = min(max(volume, 0.0), 1.0)
        lastLooping = looping
        playCount += 1
    }

    public func stopRinging() {
        lock.lock()
        defer { lock.unlock() }
        isRinging = false
        currentSound = nil
        currentVolume = 0.0
        stopCount += 1
    }
}
