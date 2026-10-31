import Foundation
import AVFoundation
import AlarmaCore

@MainActor
public final class SoundEngine {
    public static let shared = SoundEngine()

    private let coreRingingService = AVAudioRingingService()
    private var audioEngine: AVAudioEngine?
    public private(set) var isPlaying = false
    private var timer: Timer?

    private init() {}

    public func preview(sound: AlarmSound, volume: Double = 0.8) {
        stop()
        isPlaying = true
        try? coreRingingService.playRinging(sound: sound.coreSoundAsset, volume: Float(volume), looping: true)

        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.stop()
            }
        }
    }

    public func startAlarmLoop(sound: AlarmSound, volume: Double = 1.0) {
        stop()
        isPlaying = true
        try? coreRingingService.playRinging(sound: sound.coreSoundAsset, volume: Float(volume), looping: true)
    }

    public func stop() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        coreRingingService.stopRinging()

        if let engine = audioEngine, engine.isRunning {
            engine.stop()
            engine.reset()
        }
        audioEngine = nil
    }
}
