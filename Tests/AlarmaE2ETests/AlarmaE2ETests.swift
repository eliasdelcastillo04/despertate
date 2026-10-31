import XCTest
@testable import AlarmaCore

final class AlarmaE2ETests: XCTestCase {
    var tempDir: URL!
    var repoURL: URL!
    var activeStateURL: URL!

    override func setUp() async throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AlarmaE2E-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        repoURL = tempDir.appendingPathComponent("alarms.json")
        activeStateURL = tempDir.appendingPathComponent("active_alarm.txt")
    }

    override func tearDown() async throws {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    // MARK: - Tier 1: Feature Coverage Tests

    func testTier1_AlarmCRUDAndSorting() async throws {
        let repo = JSONFileAlarmRepository(fileURL: repoURL)
        let scheduler = MockNotificationScheduler()
        let audio = MockAudioPlayerService()
        let coordinator = AlarmCoordinator(repository: repo, scheduler: scheduler, audioService: audio)

        let lateAlarm = Alarm(title: "Late", time: AlarmTime(hour: 9, minute: 0)!)
        let earlyAlarm = Alarm(title: "Early", time: AlarmTime(hour: 6, minute: 15)!)

        try await coordinator.createOrUpdateAlarm(lateAlarm)
        try await coordinator.createOrUpdateAlarm(earlyAlarm)

        let list = await coordinator.alarms
        XCTAssertEqual(list.count, 2)
        XCTAssertEqual(list[0].title, "Early", "Alarms must be sorted chronologically")
        XCTAssertEqual(list[1].title, "Late")

        // Toggle off early alarm
        try await coordinator.toggleAlarm(id: earlyAlarm.id, isEnabled: false)
        let toggled = await coordinator.alarms
        XCTAssertFalse(toggled[0].isEnabled)

        // Delete late alarm
        try await coordinator.deleteAlarm(id: lateAlarm.id)
        let finalAlarms = await coordinator.alarms
        XCTAssertEqual(finalAlarms.count, 1)
        XCTAssertEqual(finalAlarms[0].id, earlyAlarm.id)
    }

    func testTier1_ClockTriggerAndMathChallengeCompletion() async throws {
        let repo = JSONFileAlarmRepository(fileURL: repoURL)
        let scheduler = MockNotificationScheduler()
        let audio = MockAudioPlayerService()
        let coordinator = AlarmCoordinator(repository: repo, scheduler: scheduler, audioService: audio)

        let alarm = Alarm(
            title: "7 AM Math",
            time: AlarmTime(hour: 7, minute: 0)!,
            repeatDays: .weekdays,
            isEnabled: true,
            sound: .radar,
            volume: 0.9,
            challengeConfig: ChallengeConfiguration(type: .math, difficulty: .medium, problemCount: 3)
        )
        try await coordinator.createOrUpdateAlarm(alarm)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        // Friday 2026-10-30 07:00 GMT
        let triggerDate = calendar.date(from: DateComponents(year: 2026, month: 10, day: 30, hour: 7, minute: 0))!

        let fired = try await coordinator.checkAndTriggerDueAlarms(at: triggerDate, calendar: calendar)
        XCTAssertEqual(fired?.id, alarm.id)
        XCTAssertTrue(audio.isRinging)

        // Solve 3 math problems via MathChallengeSessionState
        var mathSession = MathChallengeSessionState(difficulty: .medium, targetStreak: 3, seed: 555)
        while !mathSession.isCompleted {
            let answer = "\(mathSession.currentProblem.solution)"
            _ = mathSession.submit(answer: answer)
            try await coordinator.recordChallengeProgress(
                step: mathSession.currentStreak,
                totalSteps: mathSession.targetStreak
            )
        }

        XCTAssertTrue(mathSession.isCompleted)
        try await coordinator.deactivateActiveAlarm()
        XCTAssertFalse(audio.isRinging)
    }

    // MARK: - Tier 2: Boundary & Corner Cases

    func testTier2_BoundaryTimesMidnightAndEndOfDay() {
        let midnight = AlarmTime(hour: 0, minute: 0)!
        let endOfDay = AlarmTime(hour: 23, minute: 59)!

        XCTAssertEqual(midnight.formatted(is24Hour: true), "00:05".replacingOccurrences(of: "05", with: "00"))
        XCTAssertEqual(midnight.formatted(is24Hour: false), "12:00 AM")
        XCTAssertEqual(endOfDay.formatted(is24Hour: true), "23:59")
        XCTAssertEqual(endOfDay.formatted(is24Hour: false), "11:59 PM")
        XCTAssertLessThan(midnight, endOfDay)
    }

    func testTier2_MathOverflowAndMalformedInputs() {
        let p = MathProblem(expression: "10 + 10", solution: 20, difficulty: .easy)
        XCTAssertEqual(p.evaluate(input: "999999999999999999999999999999"), .invalidInput(reason: .overflow))
        XCTAssertEqual(p.evaluate(input: "   \n "), .invalidInput(reason: .empty))
        XCTAssertEqual(p.evaluate(input: "20.5"), .invalidInput(reason: .nonNumeric))
    }

    // MARK: - Tier 3: Pairwise Cross-Feature Interactions

    func testTier3_AllChallengeTypesWithLockInStateMachine() async throws {
        let repo = JSONFileAlarmRepository(fileURL: repoURL)
        let scheduler = MockNotificationScheduler()
        let audio = MockAudioPlayerService()
        let coordinator = AlarmCoordinator(repository: repo, scheduler: scheduler, audioService: audio)

        for challengeType in [ChallengeType.math, .shake, .memory, .rapidTaps, .holdCountdown] {
            let alarm = Alarm(
                title: "Challenge \(challengeType.rawValue)",
                time: AlarmTime(hour: 8, minute: 0)!,
                repeatDays: .all,
                isEnabled: true,
                challengeConfig: ChallengeConfiguration(type: challengeType, difficulty: .easy, problemCount: 3)
            )
            try await coordinator.triggerAlarm(alarm)
            XCTAssertTrue(audio.isRinging)

            // Verify direct deactivation is blocked for every challenge type
            do {
                try await coordinator.deactivateActiveAlarm()
                XCTFail("Deactivation should be blocked for \(challengeType)")
            } catch {
                // Expected
            }

            try await coordinator.markChallengeCompleted()
            try await coordinator.deactivateActiveAlarm()
            XCTAssertFalse(audio.isRinging)
        }
    }

    // MARK: - Tier 4: Real-World Scenarios

    func testTier4_HeavySleeperMultiAttemptMorningRoutine() async throws {
        let repo = JSONFileAlarmRepository(fileURL: repoURL, defaultStarterAlarms: [Alarm.defaultStarterAlarm])
        let scheduler = MockNotificationScheduler()
        let audio = MockAudioPlayerService()
        let coordinator = AlarmCoordinator(
            repository: repo,
            scheduler: scheduler,
            audioService: audio,
            activeStateFileURL: activeStateURL
        )

        // 1. First launch creates starter alarm
        let initial = try await coordinator.bootstrap()
        XCTAssertEqual(initial.count, 1)
        let starter = initial[0]

        // 2. Alarm triggers at 07:00
        try await coordinator.triggerAlarm(starter)
        XCTAssertTrue(audio.isRinging)

        // 3. Heavy sleeper enters 1 correct answer, then 1 wrong answer -> streak resets & lockout triggers
        var math = MathChallengeSessionState(difficulty: .medium, targetStreak: 3, penaltyCooldownDuration: 2.0, seed: 888)
        _ = math.submit(answer: "\(math.currentProblem.solution)")
        XCTAssertEqual(math.currentStreak, 1)

        _ = math.submit(answer: "-999")
        XCTAssertEqual(math.currentStreak, 0)
        XCTAssertTrue(math.isLockedOut)

        // 4. Wait out 2.0s penalty cooldown
        math.tickCooldown(delta: 2.0)
        XCTAssertFalse(math.isLockedOut)

        // 5. Solve 3 in a row
        for _ in 0..<3 {
            _ = math.submit(answer: "\(math.currentProblem.solution)")
        }
        XCTAssertTrue(math.isCompleted)

        // 6. Complete challenge and silence alarm
        try await coordinator.markChallengeCompleted()
        try await coordinator.deactivateActiveAlarm()
        XCTAssertFalse(audio.isRinging)

        // 7. Repeating weekday alarm stays enabled for tomorrow!
        let remaining = await coordinator.alarms
        XCTAssertTrue(remaining[0].isEnabled)
    }
}
