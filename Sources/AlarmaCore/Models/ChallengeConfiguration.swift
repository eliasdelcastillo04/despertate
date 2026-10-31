import Foundation

public enum ChallengeType: String, Codable, CaseIterable, Sendable, Identifiable {
    case none = "none"
    case math = "math"
    case shake = "shake"
    case memory = "memory"
    case rapidTaps = "rapid_taps"
    case holdCountdown = "hold_countdown"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .math: return "Math Problems"
        case .shake: return "Shake Phone"
        case .memory: return "Memory Sequence"
        case .rapidTaps: return "Rapid Taps"
        case .holdCountdown: return "Hold Countdown"
        }
    }
}

public enum ChallengeDifficulty: String, Codable, CaseIterable, Sendable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        }
    }
}

public struct ChallengeConfiguration: Codable, Equatable, Hashable, Sendable {
    public var type: ChallengeType
    public var difficulty: ChallengeDifficulty
    public var problemCount: Int {
        get { requiredCount }
        set { requiredCount = max(1, newValue) }
    }
    public var requiredCount: Int
    public var penaltyCooldownSeconds: TimeInterval
    public var maxWrongAttemptsBeforeCooldown: Int
    public var shakeCountRequired: Int
    public var memoryPatternLength: Int
    public var tapCountRequired: Int
    public var holdDurationSeconds: TimeInterval

    public init(
        type: ChallengeType = .math,
        difficulty: ChallengeDifficulty = .medium,
        problemCount: Int = 3,
        penaltyCooldownSeconds: TimeInterval = 15.0,
        maxWrongAttemptsBeforeCooldown: Int = 3,
        shakeCountRequired: Int = 30,
        memoryPatternLength: Int = 5,
        tapCountRequired: Int = 50,
        holdDurationSeconds: TimeInterval = 15.0
    ) {
        self.type = type
        self.difficulty = difficulty
        self.requiredCount = max(1, problemCount)
        self.penaltyCooldownSeconds = max(0, penaltyCooldownSeconds)
        self.maxWrongAttemptsBeforeCooldown = max(1, maxWrongAttemptsBeforeCooldown)
        self.shakeCountRequired = max(5, shakeCountRequired)
        self.memoryPatternLength = max(3, memoryPatternLength)
        self.tapCountRequired = max(10, tapCountRequired)
        self.holdDurationSeconds = max(3.0, holdDurationSeconds)
    }

    public init(
        type: ChallengeType = .math,
        difficulty: ChallengeDifficulty = .medium,
        requiredCount: Int
    ) {
        self.init(type: type, difficulty: difficulty, problemCount: requiredCount)
    }

    public static let standardMath = ChallengeConfiguration(type: .math, difficulty: .medium, problemCount: 3)
    public static let standardShake = ChallengeConfiguration(type: .shake, shakeCountRequired: 30)
    public static let standardMemory = ChallengeConfiguration(type: .memory, memoryPatternLength: 5)
    public static let standardTaps = ChallengeConfiguration(type: .rapidTaps, tapCountRequired: 50)
    public static let standardHold = ChallengeConfiguration(type: .holdCountdown, holdDurationSeconds: 15.0)
    public static let none = ChallengeConfiguration(type: .none)
}
