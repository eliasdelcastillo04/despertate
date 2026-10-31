import XCTest
@testable import AlarmaCore

final class ServicesAndCoordinatorTests: XCTestCase {
    var tempDir: URL!
    var repoURL: URL!
    var activeStateURL: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AlarmaCoordinatorTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        repoURL = tempDir.appendingPathComponent("alarms.json")
        activeStateURL = tempDir.appendingPathComponent("active_alarm.txt")
    }

    override func tearDown() async throws {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    func testNotificationSchedulerMultiDayAndSlidingWindowCap() async throws {
        let scheduler = MockNotificationScheduler()
        let weekdayAlarm = Alarm(
            title: "Workday",
            time: AlarmTime(hour: 7, minute: 15)!,
            repeatDays: .weekdays,
            isEnabled: true
        )

        try await scheduler.scheduleAlarm(weekdayAlarm)
        let scheduled = await scheduler.scheduledDescriptors
        XCTAssertEqual(scheduled.count, 5, "Weekdays alarm must schedule 5 weekday triggers (Mon-Fri)")
        XCTAssertEqual(scheduled.map { $0.weekday }, [2, 3, 4, 5, 6])

        // Test 48-notification sliding window cap (15 all-day alarms = 105 descriptors -> capped at 48)
        let manyAlarms = (0..<15).map { i in
            Alarm(
                title: "Alarm \(i)",
                time: AlarmTime(hour: i % 24, minute: 0)!,
                repeatDays: .all,
                isEnabled: true
            )
        }
        try await scheduler.rescheduleAll(alarms: manyAlarms)
        let capped = await scheduler.scheduledDescriptors
        XCTAssertEqual(capped.count, 48, "Must cap notifications at 48 to stay safely under iOS 64 limit")
    }

    func testAudioServiceSynthesizesValidWAVAndPlays() throws {
        for sound in SoundAsset.allCases {
            let wav = AVAudioRingingService.synthesizeToneWAV(for: sound, durationSeconds: 0.25)
            XCTAssertNotNil(wav, "Must synthesize non-nil WAV for \(sound)")
            XCTAssertGreaterThan(wav?.count ?? 0, 44, "WAV must contain header + PCM samples")
        }

        let mockAudio = MockAudioPlayerService()
        try mockAudio.playRinging(sound: .radar, volume: 0.9, looping: true)
        XCTAssertTrue(mockAudio.isRinging)
        XCTAssertEqual(mockAudio.currentSound, .radar)
        XCTAssertEqual(mockAudio.currentVolume, 0.9, accuracy: 0.001)

        mockAudio.stopRinging()
        XCTAssertFalse(mockAudio.isRinging)
        XCTAssertNil(mockAudio.currentSound)
    }

    func testCoordinatorEndToEndLifecycleAndKillRecovery() async throws {
        let repo = JSONFileAlarmRepository(fileURL: repoURL)
        let scheduler = MockNotificationScheduler()
        let audio = MockAudioPlayerService()

        let coordinator = AlarmCoordinator(
            repository: repo,
            scheduler: scheduler,
            audioService: audio,
            activeStateFileURL: activeStateURL
        )

        let oneShotAlarm = Alarm(
            title: "Morning Math",
            time: AlarmTime(hour: 6, minute: 30)!,
            repeatDays: .none,
            isEnabled: true,
            sound: .radar,
            volume: 0.85,
            challengeConfig: ChallengeConfiguration(type: .math, difficulty: .medium, problemCount: 3)
        )

        try await coordinator.createOrUpdateAlarm(oneShotAlarm)
        let all = await coordinator.alarms
        XCTAssertEqual(all.count, 1)

        // Trigger alarm
        try await coordinator.triggerAlarm(oneShotAlarm)
        XCTAssertTrue(audio.isRinging)

        // Attempt premature deactivation -> must fail and keep ringing!
        do {
            try await coordinator.deactivateActiveAlarm()
            XCTFail("Expected deactivationBlocked error")
        } catch let error as DeactivationError {
            XCTAssertEqual(
                error,
                .deactivationBlocked(reason: "Active challenge must be solved before silencing alarm.")
            )
        }
        XCTAssertTrue(audio.isRinging)

        // Simulate app termination and relaunch while alarm is still unresolved!
        let relaunchedAudio = MockAudioPlayerService()
        let relaunchedCoordinator = AlarmCoordinator(
            repository: repo,
            scheduler: scheduler,
            audioService: relaunchedAudio,
            activeStateFileURL: activeStateURL
        )
        _ = try await relaunchedCoordinator.bootstrap()
        let recoveredActive = await relaunchedCoordinator.activeRingingAlarm
        XCTAssertEqual(recoveredActive?.id, oneShotAlarm.id, "Must recover active ringing alarm after relaunch")
        XCTAssertTrue(relaunchedAudio.isRinging, "Audio must resume immediately on relaunch")

        // Solve challenge -> deactivate succeeds and auto-disables one-shot alarm!
        try await relaunchedCoordinator.markChallengeCompleted()
        try await relaunchedCoordinator.deactivateActiveAlarm()
        XCTAssertFalse(relaunchedAudio.isRinging)
        let postActive = await relaunchedCoordinator.activeRingingAlarm
        XCTAssertNil(postActive)

        let updatedAlarms = await relaunchedCoordinator.alarms
        XCTAssertEqual(updatedAlarms.first?.isEnabled, false, "One-shot alarm must auto-disable after completion")
    }
}
