import Foundation

// MARK: - 1. Shake Challenge Engine

/// Pure state engine for the physical device shake challenge.
public struct ShakeChallengeEngine: Equatable, Sendable {
    public let requiredShakes: Int
    public let accelerationThresholdG: Double
    public let debounceInterval: TimeInterval

    public private(set) var currentShakes: Int = 0
    public private(set) var lastShakeTimestamp: TimeInterval? = nil
    public private(set) var isCompleted: Bool = false

    public var progress: Double {
        guard requiredShakes > 0 else { return 1.0 }
        return min(1.0, Double(currentShakes) / Double(requiredShakes))
    }

    public init(
        requiredShakes: Int = 30,
        accelerationThresholdG: Double = 2.2,
        debounceInterval: TimeInterval = 0.20
    ) {
        self.requiredShakes = max(1, requiredShakes)
        self.accelerationThresholdG = max(1.1, accelerationThresholdG)
        self.debounceInterval = max(0.05, debounceInterval)
    }

    public init(difficulty: ChallengeDifficulty) {
        switch difficulty {
        case .easy:
            self.init(requiredShakes: 20)
        case .medium:
            self.init(requiredShakes: 35)
        case .hard:
            self.init(requiredShakes: 50)
        }
    }

    /// Processes a 3-axis accelerometer reading (in G-units) at a given timestamp.
    /// Returns `true` if a valid shake increment was recorded.
    @discardableResult
    public mutating func processAcceleration(
        x: Double,
        y: Double,
        z: Double,
        timestamp: TimeInterval
    ) -> Bool {
        guard !isCompleted else { return false }
        let magnitude = (x * x + y * y + z * z).squareRoot()
        guard magnitude >= accelerationThresholdG else { return false }
        return registerShake(at: timestamp)
    }

    /// Registers a discrete shake event (from sensor threshold or simulator shake action),
    /// respecting the debounce interval.
    @discardableResult
    public mutating func registerShake(at timestamp: TimeInterval) -> Bool {
        guard !isCompleted else { return false }

        if let last = lastShakeTimestamp, (timestamp - last) < debounceInterval {
            return false
        }

        lastShakeTimestamp = timestamp
        currentShakes += 1
        if currentShakes >= requiredShakes {
            currentShakes = requiredShakes
            isCompleted = true
        }
        return true
    }

    public mutating func reset() {
        currentShakes = 0
        lastShakeTimestamp = nil
        isCompleted = false
    }
}

// MARK: - 2. Memory Pattern Recall Challenge Engine

public enum MemoryTileColor: Int, Codable, CaseIterable, Sendable, Identifiable {
    case red = 0
    case blue = 1
    case green = 2
    case yellow = 3

    public var id: Int { rawValue }

    public var displayName: String {
        switch self {
        case .red: return "Rojo"
        case .blue: return "Azul"
        case .green: return "Verde"
        case .yellow: return "Amarillo"
        }
    }
}

public enum MemoryTapResult: Equatable, Sendable {
    case correctStep(currentIndex: Int, totalSteps: Int)
    case completed
    case wrongTile(expected: MemoryTileColor, submitted: MemoryTileColor)
}

/// Pure state engine for the 2x2 Simon-style memory sequence recall challenge.
public struct MemoryPatternChallengeEngine: Equatable, Sendable {
    public let patternLength: Int
    public private(set) var targetPattern: [MemoryTileColor]
    public private(set) var currentInputIndex: Int = 0
    public private(set) var failedAttempts: Int = 0
    public private(set) var isCompleted: Bool = false

    public var progress: Double {
        guard patternLength > 0 else { return 1.0 }
        return min(1.0, Double(currentInputIndex) / Double(patternLength))
    }

    public init(patternLength: Int = 5, seed: UInt64? = nil) {
        let length = max(3, patternLength)
        self.patternLength = length
        if let seed = seed {
            var rng = SeededRandomNumberGenerator(seed: seed)
            self.targetPattern = Self.generatePattern(length: length, using: &rng)
        } else {
            var rng = SystemRandomNumberGenerator()
            self.targetPattern = Self.generatePattern(length: length, using: &rng)
        }
    }

    public init(difficulty: ChallengeDifficulty, seed: UInt64? = nil) {
        let length: Int
        switch difficulty {
        case .easy: length = 3
        case .medium: length = 5
        case .hard: length = 7
        }
        self.init(patternLength: length, seed: seed)
    }

    public init(explicitPattern: [MemoryTileColor]) {
        precondition(!explicitPattern.isEmpty, "Pattern must not be empty")
        self.patternLength = explicitPattern.count
        self.targetPattern = explicitPattern
    }

    public static func generatePattern<R: RandomNumberGenerator>(
        length: Int,
        using rng: inout R
    ) -> [MemoryTileColor] {
        let allTiles = MemoryTileColor.allCases
        return (0..<max(1, length)).map { _ in
            let index = Int.random(in: 0..<allTiles.count, using: &rng)
            return allTiles[index]
        }
    }

    /// Evaluates a user tile tap against the current position in `targetPattern`.
    public mutating func submitTap(_ tile: MemoryTileColor) -> MemoryTapResult {
        guard !isCompleted else { return .completed }
        let expected = targetPattern[currentInputIndex]

        if tile == expected {
            currentInputIndex += 1
            if currentInputIndex >= targetPattern.count {
                isCompleted = true
                return .completed
            }
            return .correctStep(currentIndex: currentInputIndex, totalSteps: targetPattern.count)
        } else {
            failedAttempts += 1
            currentInputIndex = 0
            return .wrongTile(expected: expected, submitted: tile)
        }
    }

    public mutating func resetProgress() {
        currentInputIndex = 0
        isCompleted = false
    }
}

// MARK: - 3. Rapid Button Taps Challenge Engine

/// Pure state engine for the rapid button tapping challenge with idle decay.
public struct RapidTapsChallengeEngine: Equatable, Sendable {
    public let targetTaps: Int
    public let idleGracePeriodSeconds: TimeInterval
    public let decayRatePerSecond: Double

    public private(set) var currentTaps: Int = 0
    public private(set) var lastTapTimestamp: TimeInterval? = nil
    public private(set) var isCompleted: Bool = false

    public var progress: Double {
        guard targetTaps > 0 else { return 1.0 }
        return min(1.0, Double(currentTaps) / Double(targetTaps))
    }

    public init(
        targetTaps: Int = 50,
        idleGracePeriodSeconds: TimeInterval = 1.5,
        decayRatePerSecond: Double = 2.0
    ) {
        self.targetTaps = max(5, targetTaps)
        self.idleGracePeriodSeconds = max(0.5, idleGracePeriodSeconds)
        self.decayRatePerSecond = max(0.0, decayRatePerSecond)
    }

    public init(difficulty: ChallengeDifficulty) {
        switch difficulty {
        case .easy:
            self.init(targetTaps: 30)
        case .medium:
            self.init(targetTaps: 50)
        case .hard:
            self.init(targetTaps: 80)
        }
    }

    /// Records a single user tap at the given timestamp.
    public mutating func registerTap(at timestamp: TimeInterval = Date().timeIntervalSinceReferenceDate) {
        guard !isCompleted else { return }
        lastTapTimestamp = timestamp
        currentTaps += 1
        if currentTaps >= targetTaps {
            currentTaps = targetTaps
            isCompleted = true
        }
    }

    /// Applies idle decay if time since `lastTapTimestamp` exceeds `idleGracePeriodSeconds`.
    public mutating func tickDecay(currentTime: TimeInterval, deltaSeconds: TimeInterval) {
        guard !isCompleted, currentTaps > 0, let lastTap = lastTapTimestamp else { return }
        let idleTime = currentTime - lastTap
        guard idleTime > idleGracePeriodSeconds else { return }

        let decayAmount = max(1, Int((decayRatePerSecond * max(0.5, deltaSeconds)).rounded(.up)))
        currentTaps = max(0, currentTaps - decayAmount)
    }

    public mutating func reset() {
        currentTaps = 0
        lastTapTimestamp = nil
        isCompleted = false
    }
}

// MARK: - 4. Hold Countdown Challenge Engine

/// Pure state engine for the continuous press-and-hold countdown challenge.
public struct HoldCountdownChallengeEngine: Equatable, Sendable {
    public let targetDurationSeconds: TimeInterval

    public private(set) var isHolding: Bool = false
    public private(set) var elapsedSeconds: TimeInterval = 0.0
    public private(set) var releaseResetCount: Int = 0
    public private(set) var isCompleted: Bool = false

    public var progress: Double {
        guard targetDurationSeconds > 0 else { return 1.0 }
        return min(1.0, elapsedSeconds / targetDurationSeconds)
    }

    public var remainingSeconds: TimeInterval {
        max(0.0, targetDurationSeconds - elapsedSeconds)
    }

    public init(targetDurationSeconds: TimeInterval = 10.0) {
        self.targetDurationSeconds = max(1.0, targetDurationSeconds)
    }

    public init(difficulty: ChallengeDifficulty) {
        switch difficulty {
        case .easy:
            self.init(targetDurationSeconds: 5.0)
        case .medium:
            self.init(targetDurationSeconds: 10.0)
        case .hard:
            self.init(targetDurationSeconds: 15.0)
        }
    }

    public mutating func beginHold() {
        guard !isCompleted else { return }
        isHolding = true
    }

    /// Advances the continuous hold timer while `isHolding == true`.
    public mutating func tickHold(deltaSeconds: TimeInterval) {
        guard isHolding, !isCompleted, deltaSeconds > 0 else { return }
        elapsedSeconds += deltaSeconds
        if elapsedSeconds >= targetDurationSeconds {
            elapsedSeconds = targetDurationSeconds
            isCompleted = true
            isHolding = false
        }
    }

    /// Releases the hold. If not yet completed, progress immediately resets to 0.0!
    public mutating func endHold() {
        guard !isCompleted else {
            isHolding = false
            return
        }
        if isHolding && elapsedSeconds > 0 {
            releaseResetCount += 1
        }
        isHolding = false
        elapsedSeconds = 0.0
    }
}
