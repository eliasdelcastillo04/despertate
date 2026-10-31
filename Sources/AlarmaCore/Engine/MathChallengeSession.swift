import Foundation

/// Outcome returned upon submitting an answer to `MathChallengeSessionState`.
public enum MathSubmissionResult: Equatable, Sendable {
    /// The answer was correct; challenge continues with updated streak.
    case correct(newStreak: Int, remaining: Int)
    /// The challenge target streak has been reached; challenge is finished.
    case completed(totalSolved: Int, totalAttempts: Int)
    /// The answer was incorrect; streak reset to 0, penalty lockout initiated.
    case incorrect(submitted: Int, expected: Int, cooldown: TimeInterval)
    /// Input string could not be parsed; no streak penalty applied.
    case invalidInput(reason: InvalidInputReason)
    /// Submission rejected because session is currently locked out in penalty cooldown.
    case blockedByCooldown(remaining: TimeInterval)
}

/// Pure state machine governing streak progression, answer evaluation, and penalty lockout.
public struct MathChallengeSessionState: Equatable, Sendable {
    public let difficulty: ChallengeDifficulty
    public let targetStreak: Int
    public let penaltyCooldownDuration: TimeInterval

    public private(set) var currentProblem: MathProblem
    public private(set) var currentStreak: Int = 0
    public private(set) var cooldownRemaining: TimeInterval = 0.0
    public private(set) var isCompleted: Bool = false
    public private(set) var totalAttempts: Int = 0
    public private(set) var failedAttempts: Int = 0

    private var rng: SeededRandomNumberGenerator?

    public var isLockedOut: Bool {
        cooldownRemaining > 0.0
    }

    public var progress: Double {
        guard targetStreak > 0 else { return 1.0 }
        return min(1.0, Double(currentStreak) / Double(targetStreak))
    }

    public init(
        difficulty: ChallengeDifficulty = .medium,
        targetStreak: Int = 3,
        penaltyCooldownDuration: TimeInterval = 2.0,
        generator: MathProblemGenerating = DefaultMathProblemGenerator(),
        seed: UInt64? = nil
    ) {
        self.difficulty = difficulty
        self.targetStreak = max(1, targetStreak)
        self.penaltyCooldownDuration = max(0.5, penaltyCooldownDuration)

        if let seed = seed {
            var seededRNG = SeededRandomNumberGenerator(seed: seed)
            self.currentProblem = generator.generateProblem(difficulty: difficulty, using: &seededRNG)
            self.rng = seededRNG
        } else {
            self.currentProblem = generator.generateProblem(difficulty: difficulty)
            self.rng = nil
        }
    }

    /// Evaluates user answer submission against current problem.
    public mutating func submit(
        answer: String,
        generator: MathProblemGenerating = DefaultMathProblemGenerator()
    ) -> MathSubmissionResult {
        // 1. Guard against submissions during active cooldown lockout
        if isLockedOut {
            return .blockedByCooldown(remaining: cooldownRemaining)
        }

        // 2. Guard against submission after completion
        if isCompleted {
            return .completed(totalSolved: currentStreak, totalAttempts: totalAttempts)
        }

        // 3. Evaluate input
        let eval = currentProblem.evaluate(input: answer)
        switch eval {
        case .invalidInput(let reason):
            // No penalty for malformed input (e.g. empty or non-digit)
            return .invalidInput(reason: reason)

        case .correct:
            totalAttempts += 1
            currentStreak += 1
            if currentStreak >= targetStreak {
                isCompleted = true
                return .completed(totalSolved: currentStreak, totalAttempts: totalAttempts)
            } else {
                advanceToNextProblem(generator: generator)
                return .correct(newStreak: currentStreak, remaining: targetStreak - currentStreak)
            }

        case .incorrect(let submitted, let expected):
            totalAttempts += 1
            failedAttempts += 1
            currentStreak = 0 // Streak reset to 0
            cooldownRemaining = penaltyCooldownDuration
            advanceToNextProblem(generator: generator)
            return .incorrect(
                submitted: submitted,
                expected: expected,
                cooldown: penaltyCooldownDuration
            )
        }
    }

    /// Advances the penalty lockout cooldown timer by a given time interval.
    public mutating func tickCooldown(delta: TimeInterval) {
        guard delta > 0, cooldownRemaining > 0.0 else { return }
        cooldownRemaining = max(0.0, cooldownRemaining - delta)
    }

    /// Generates a new problem for the next round.
    private mutating func advanceToNextProblem(generator: MathProblemGenerating) {
        if var activeRNG = self.rng {
            self.currentProblem = generator.generateProblem(difficulty: difficulty, using: &activeRNG)
            self.rng = activeRNG
        } else {
            self.currentProblem = generator.generateProblem(difficulty: difficulty)
        }
    }
}
