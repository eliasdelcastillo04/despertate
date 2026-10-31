import Foundation

public enum DeactivationState: Equatable, Sendable {
    case idle
    case ringing(alarmId: UUID)
    case challengeActive(alarmId: UUID, progress: Double, step: Int, totalSteps: Int)
    case challengeEvaluating(alarmId: UUID)
    case challengePenalty(alarmId: UUID, reason: String, cooldownRemaining: TimeInterval)
    case challengeCompleted(alarmId: UUID)
    case deactivated(alarmId: UUID)

    public var isLockedIn: Bool {
        switch self {
        case .ringing, .challengeActive, .challengeEvaluating, .challengePenalty:
            return true
        case .idle, .challengeCompleted, .deactivated:
            return false
        }
    }

    public var canDeactivate: Bool {
        if case .challengeCompleted = self {
            return true
        }
        return false
    }

    public var activeAlarmId: UUID? {
        switch self {
        case .idle:
            return nil
        case .ringing(let id),
             .challengeActive(let id, _, _, _),
             .challengeEvaluating(let id),
             .challengePenalty(let id, _, _),
             .challengeCompleted(let id),
             .deactivated(let id):
            return id
        }
    }
}

public enum DeactivationEvent: Equatable, Sendable {
    case alarmTriggered(alarmId: UUID)
    case startChallenge
    case beginEvaluation
    case updateProgress(step: Int, totalSteps: Int)
    case recordPenalty(reason: String, cooldown: TimeInterval)
    case cooldownTick(remaining: TimeInterval)
    case cooldownElapsed
    case challengeSuccess
    case requestDeactivation
    case resetToIdle
}

public enum DeactivationError: Error, LocalizedError, Equatable, Sendable {
    case invalidTransition(from: String, on: String)
    case deactivationBlocked(reason: String)

    public var errorDescription: String? {
        switch self {
        case .invalidTransition(let from, let on):
            return "Invalid state transition from \(from) on event \(on)."
        case .deactivationBlocked(let reason):
            return reason
        }
    }
}

/// Finite State Machine enforcing the security boundary that an active alarm
/// cannot be dismissed or silenced until its assigned challenge is completed.
public final class AlarmDeactivationStateMachine: @unchecked Sendable {
    private let lock = NSLock()
    private var stateInternal: DeactivationState

    public var currentState: DeactivationState {
        lock.lock()
        defer { lock.unlock() }
        return stateInternal
    }

    public init(initialState: DeactivationState = .idle) {
        self.stateInternal = initialState
    }

    public func transition(event: DeactivationEvent) throws {
        lock.lock()
        defer { lock.unlock() }

        switch (stateInternal, event) {
        case (.idle, .alarmTriggered(let alarmId)):
            stateInternal = .ringing(alarmId: alarmId)

        case (.ringing(let alarmId), .startChallenge):
            stateInternal = .challengeActive(alarmId: alarmId, progress: 0.0, step: 0, totalSteps: 1)

        case (.challengeActive(let alarmId, _, _, _), .beginEvaluation):
            stateInternal = .challengeEvaluating(alarmId: alarmId)

        case (.challengeActive(let alarmId, _, _, _), .updateProgress(let step, let total)),
             (.challengeEvaluating(let alarmId), .updateProgress(let step, let total)):
            let clampedTotal = max(1, total)
            let clampedStep = min(max(0, step), clampedTotal)
            let progress = Double(clampedStep) / Double(clampedTotal)
            stateInternal = .challengeActive(
                alarmId: alarmId,
                progress: progress,
                step: clampedStep,
                totalSteps: clampedTotal
            )

        case (.challengeActive(let alarmId, _, _, _), .recordPenalty(let reason, let cooldown)),
             (.challengeEvaluating(let alarmId), .recordPenalty(let reason, let cooldown)):
            stateInternal = .challengePenalty(
                alarmId: alarmId,
                reason: reason,
                cooldownRemaining: max(0.0, cooldown)
            )

        case (.challengePenalty(let alarmId, let reason, _), .cooldownTick(let remaining)):
            if remaining <= 0.0 {
                stateInternal = .challengeActive(alarmId: alarmId, progress: 0.0, step: 0, totalSteps: 1)
            } else {
                stateInternal = .challengePenalty(
                    alarmId: alarmId,
                    reason: reason,
                    cooldownRemaining: remaining
                )
            }

        case (.challengePenalty(let alarmId, _, _), .cooldownElapsed):
            stateInternal = .challengeActive(alarmId: alarmId, progress: 0.0, step: 0, totalSteps: 1)

        case (.challengeActive(let alarmId, _, _, _), .challengeSuccess),
             (.challengeEvaluating(let alarmId), .challengeSuccess),
             (.ringing(let alarmId), .challengeSuccess):
            stateInternal = .challengeCompleted(alarmId: alarmId)

        case (.challengeCompleted(let alarmId), .requestDeactivation):
            stateInternal = .deactivated(alarmId: alarmId)

        case (.deactivated, .resetToIdle):
            stateInternal = .idle

        // SECURITY INVARIANT: Deactivation cannot occur unless challenge is completed!
        case (.ringing, .requestDeactivation),
             (.challengeActive, .requestDeactivation),
             (.challengeEvaluating, .requestDeactivation),
             (.challengePenalty, .requestDeactivation):
            throw DeactivationError.deactivationBlocked(
                reason: "Active challenge must be solved before silencing alarm."
            )

        default:
            throw DeactivationError.invalidTransition(
                from: "\(stateInternal)",
                on: "\(event)"
            )
        }
    }
}
