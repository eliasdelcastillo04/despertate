import XCTest
@testable import AlarmaCore

final class InteractiveChallengesAndFSMTests: XCTestCase {
    // MARK: - Shake Challenge Tests

    func testShakeEngineAccumulationAndDebounce() {
        var engine = ShakeChallengeEngine(requiredShakes: 5, accelerationThresholdG: 2.2, debounceInterval: 0.20)
        XCTAssertEqual(engine.currentShakes, 0)
        XCTAssertFalse(engine.isCompleted)

        // Below threshold (1.0g) -> ignored
        XCTAssertFalse(engine.processAcceleration(x: 0.0, y: 1.0, z: 0.0, timestamp: 1.0))
        XCTAssertEqual(engine.currentShakes, 0)

        // Valid shake at t = 1.0 (magnitude = 3.0g)
        XCTAssertTrue(engine.processAcceleration(x: 3.0, y: 0.0, z: 0.0, timestamp: 1.0))
        XCTAssertEqual(engine.currentShakes, 1)

        // Debounced spike at t = 1.05 (< 0.20s) -> rejected
        XCTAssertFalse(engine.processAcceleration(x: 3.5, y: 0.0, z: 0.0, timestamp: 1.05))
        XCTAssertEqual(engine.currentShakes, 1)

        // Complete remaining 4 shakes spaced by 0.25s
        for i in 1...4 {
            let t = 1.0 + Double(i) * 0.25
            XCTAssertTrue(engine.registerShake(at: t))
        }

        XCTAssertEqual(engine.currentShakes, 5)
        XCTAssertTrue(engine.isCompleted)
        XCTAssertEqual(engine.progress, 1.0)
    }

    // MARK: - Memory Pattern Challenge Tests

    func testMemoryPatternSuccessAndResetOnMistake() {
        var engine = MemoryPatternChallengeEngine(explicitPattern: [.red, .blue, .green, .yellow])
        XCTAssertEqual(engine.patternLength, 4)
        XCTAssertFalse(engine.isCompleted)

        // Correct step 1 & 2
        XCTAssertEqual(engine.submitTap(.red), .correctStep(currentIndex: 1, totalSteps: 4))
        XCTAssertEqual(engine.submitTap(.blue), .correctStep(currentIndex: 2, totalSteps: 4))

        // Mistake on step 3 -> resets index to 0
        XCTAssertEqual(engine.submitTap(.red), .wrongTile(expected: .green, submitted: .red))
        XCTAssertEqual(engine.currentInputIndex, 0)
        XCTAssertEqual(engine.failedAttempts, 1)

        // Full correct recall
        _ = engine.submitTap(.red)
        _ = engine.submitTap(.blue)
        _ = engine.submitTap(.green)
        let finalRes = engine.submitTap(.yellow)
        XCTAssertEqual(finalRes, .completed)
        XCTAssertTrue(engine.isCompleted)
    }

    // MARK: - Rapid Taps Challenge Tests

    func testRapidTapsProgressionAndIdleDecay() {
        var engine = RapidTapsChallengeEngine(targetTaps: 10, idleGracePeriodSeconds: 1.5, decayRatePerSecond: 2.0)

        for i in 0..<5 {
            engine.registerTap(at: Double(i) * 0.2)
        }
        XCTAssertEqual(engine.currentTaps, 5)

        // Within grace period (last tap at 0.8s, check at 2.0s -> 1.2s idle <= 1.5s) -> no decay
        engine.tickDecay(currentTime: 2.0, deltaSeconds: 0.5)
        XCTAssertEqual(engine.currentTaps, 5)

        // Past grace period (check at 3.0s -> 2.2s idle > 1.5s) -> decays
        engine.tickDecay(currentTime: 3.0, deltaSeconds: 1.0)
        XCTAssertLessThan(engine.currentTaps, 5)

        // Tap until completion
        while !engine.isCompleted {
            engine.registerTap(at: 4.0)
        }
        XCTAssertEqual(engine.currentTaps, 10)
        XCTAssertTrue(engine.isCompleted)
    }

    // MARK: - Hold Countdown Challenge Tests

    func testHoldCountdownContinuousVsEarlyRelease() {
        var engine = HoldCountdownChallengeEngine(targetDurationSeconds: 5.0)
        engine.beginHold()
        engine.tickHold(deltaSeconds: 3.0)
        XCTAssertEqual(engine.elapsedSeconds, 3.0, accuracy: 0.001)
        XCTAssertFalse(engine.isCompleted)

        // Release early -> instant reset to 0!
        engine.endHold()
        XCTAssertEqual(engine.elapsedSeconds, 0.0)
        XCTAssertEqual(engine.releaseResetCount, 1)
        XCTAssertFalse(engine.isCompleted)

        // Continuous hold for 5.0s -> completes!
        engine.beginHold()
        engine.tickHold(deltaSeconds: 2.5)
        engine.tickHold(deltaSeconds: 2.5)
        XCTAssertTrue(engine.isCompleted)
        XCTAssertEqual(engine.progress, 1.0)
    }

    // MARK: - Anti-Bypass Deactivation State Machine Tests

    func testStateMachineBlocksDeactivationUntilChallengeCompleted() throws {
        let fsm = AlarmDeactivationStateMachine()
        let alarmId = UUID()

        XCTAssertEqual(fsm.currentState, .idle)

        try fsm.transition(event: .alarmTriggered(alarmId: alarmId))
        XCTAssertEqual(fsm.currentState, .ringing(alarmId: alarmId))

        // Attempt direct deactivation while ringing -> MUST THROW deactivationBlocked!
        XCTAssertThrowsError(try fsm.transition(event: .requestDeactivation)) { error in
            XCTAssertEqual(
                error as? DeactivationError,
                .deactivationBlocked(reason: "Active challenge must be solved before silencing alarm.")
            )
        }

        try fsm.transition(event: .startChallenge)
        XCTAssertTrue(fsm.currentState.isLockedIn)
        XCTAssertFalse(fsm.currentState.canDeactivate)

        // Attempt deactivation while challengeActive -> MUST THROW!
        XCTAssertThrowsError(try fsm.transition(event: .requestDeactivation))

        // Record penalty -> still blocked!
        try fsm.transition(event: .recordPenalty(reason: "Wrong answer", cooldown: 2.0))
        XCTAssertThrowsError(try fsm.transition(event: .requestDeactivation))

        // Cooldown elapsed -> back to challengeActive
        try fsm.transition(event: .cooldownElapsed)
        try fsm.transition(event: .updateProgress(step: 2, totalSteps: 3))
        XCTAssertThrowsError(try fsm.transition(event: .requestDeactivation))

        // Complete challenge -> now deactivation is allowed!
        try fsm.transition(event: .challengeSuccess)
        XCTAssertEqual(fsm.currentState, .challengeCompleted(alarmId: alarmId))
        XCTAssertTrue(fsm.currentState.canDeactivate)

        try fsm.transition(event: .requestDeactivation)
        XCTAssertEqual(fsm.currentState, .deactivated(alarmId: alarmId))

        try fsm.transition(event: .resetToIdle)
        XCTAssertEqual(fsm.currentState, .idle)
    }
}
