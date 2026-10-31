import XCTest
@testable import AlarmaCore

final class MathValidationAndPenaltyTests: XCTestCase {
    func testMathProblemValidationAndEvaluation() {
        let problem = MathProblem(expression: "15 + 27", solution: 42, difficulty: .medium)

        XCTAssertTrue(problem.validate(input: "42"))
        XCTAssertTrue(problem.validate(input: "  42 \n\t "))
        XCTAssertFalse(problem.validate(input: "41"))
        XCTAssertFalse(problem.validate(input: ""))
        XCTAssertFalse(problem.validate(input: "   "))
        XCTAssertFalse(problem.validate(input: "42.0"))
        XCTAssertFalse(problem.validate(input: "abc"))

        XCTAssertEqual(problem.evaluate(input: "42"), .correct)
        XCTAssertEqual(problem.evaluate(input: "99"), .incorrect(submitted: 99, expected: 42))
        XCTAssertEqual(problem.evaluate(input: ""), .invalidInput(reason: .empty))
        XCTAssertEqual(problem.evaluate(input: "xyz"), .invalidInput(reason: .nonNumeric))
    }

    func testSessionStreakProgressionToCompletion() {
        var session = MathChallengeSessionState(
            difficulty: .easy,
            targetStreak: 3,
            penaltyCooldownDuration: 2.0,
            seed: 42
        )

        XCTAssertEqual(session.currentStreak, 0)
        XCTAssertFalse(session.isCompleted)

        // Solve 1
        let r1 = session.submit(answer: "\(session.currentProblem.solution)")
        XCTAssertEqual(r1, .correct(newStreak: 1, remaining: 2))
        XCTAssertEqual(session.currentStreak, 1)

        // Solve 2
        let r2 = session.submit(answer: "\(session.currentProblem.solution)")
        XCTAssertEqual(r2, .correct(newStreak: 2, remaining: 1))
        XCTAssertEqual(session.currentStreak, 2)

        // Solve 3 -> Completed!
        let r3 = session.submit(answer: "\(session.currentProblem.solution)")
        XCTAssertEqual(r3, .completed(totalSolved: 3, totalAttempts: 3))
        XCTAssertTrue(session.isCompleted)
        XCTAssertEqual(session.progress, 1.0)
    }

    func testSessionWrongAnswerResetsStreakAndTriggersLockout() {
        var session = MathChallengeSessionState(
            difficulty: .medium,
            targetStreak: 3,
            penaltyCooldownDuration: 2.0,
            seed: 77
        )

        // Solve 1 correctly
        _ = session.submit(answer: "\(session.currentProblem.solution)")
        XCTAssertEqual(session.currentStreak, 1)

        // Submit wrong answer
        let wrongVal = session.currentProblem.solution + 10
        let expectedVal = session.currentProblem.solution
        let wrongResult = session.submit(answer: "\(wrongVal)")
        XCTAssertEqual(wrongResult, .incorrect(submitted: wrongVal, expected: expectedVal, cooldown: 2.0))
        XCTAssertEqual(session.currentStreak, 0)
        XCTAssertTrue(session.isLockedOut)
        XCTAssertEqual(session.cooldownRemaining, 2.0)

        // Submissions during cooldown must be blocked
        let blocked = session.submit(answer: "\(session.currentProblem.solution)")
        XCTAssertEqual(blocked, .blockedByCooldown(remaining: 2.0))

        // Tick cooldown partially
        session.tickCooldown(delta: 1.0)
        XCTAssertTrue(session.isLockedOut)
        XCTAssertEqual(session.cooldownRemaining, 1.0)

        // Tick cooldown to 0
        session.tickCooldown(delta: 1.0)
        XCTAssertFalse(session.isLockedOut)
        XCTAssertEqual(session.cooldownRemaining, 0.0)

        // Now valid submission succeeds
        let rNext = session.submit(answer: "\(session.currentProblem.solution)")
        XCTAssertEqual(rNext, .correct(newStreak: 1, remaining: 2))
    }

    func testInvalidInputDoesNotPenalizeStreak() {
        var session = MathChallengeSessionState(
            difficulty: .easy,
            targetStreak: 3,
            penaltyCooldownDuration: 2.0,
            seed: 123
        )

        _ = session.submit(answer: "\(session.currentProblem.solution)")
        XCTAssertEqual(session.currentStreak, 1)

        let res = session.submit(answer: "not_a_number")
        XCTAssertEqual(res, .invalidInput(reason: .nonNumeric))
        XCTAssertEqual(session.currentStreak, 1)
        XCTAssertFalse(session.isLockedOut)
    }
}
