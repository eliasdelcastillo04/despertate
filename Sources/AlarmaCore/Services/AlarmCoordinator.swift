import Foundation

/// High-level domain coordinator linking alarm persistence, notification scheduling,
/// audio playback, and the anti-bypass challenge deactivation state machine.
public actor AlarmCoordinator {
    private let repository: AlarmRepositoryProtocol
    private let scheduler: NotificationSchedulerProtocol
    private let audioService: AudioPlayerServiceProtocol
    public let stateMachine: AlarmDeactivationStateMachine
    private let activeStateFileURL: URL?

    public private(set) var alarms: [Alarm] = []
    public private(set) var activeRingingAlarm: Alarm? = nil

    public init(
        repository: AlarmRepositoryProtocol,
        scheduler: NotificationSchedulerProtocol,
        audioService: AudioPlayerServiceProtocol,
        stateMachine: AlarmDeactivationStateMachine = AlarmDeactivationStateMachine(),
        activeStateFileURL: URL? = nil
    ) {
        self.repository = repository
        self.scheduler = scheduler
        self.audioService = audioService
        self.stateMachine = stateMachine
        self.activeStateFileURL = activeStateFileURL
    }

    // MARK: - Lifecycle & Persistence

    @discardableResult
    public func bootstrap() async throws -> [Alarm] {
        let loaded = try await repository.loadAlarms()
        self.alarms = loaded.sorted { $0.time < $1.time }
        try await scheduler.rescheduleAll(alarms: self.alarms)

        if let persistedActiveId = loadPersistedActiveAlarmId(),
           let matchingAlarm = self.alarms.first(where: { $0.id == persistedActiveId }) {
            try? triggerAlarm(matchingAlarm)
        }
        return self.alarms
    }

    public func createOrUpdateAlarm(_ alarm: Alarm) async throws {
        var updated = alarm
        updated.updatedAt = Date()
        try await repository.upsertAlarm(updated)
        if updated.isEnabled {
            try await scheduler.scheduleAlarm(updated)
        } else {
            try await scheduler.cancelAlarm(id: updated.id)
        }
        let loaded = try await repository.loadAlarms()
        self.alarms = loaded.sorted { $0.time < $1.time }
    }

    public func toggleAlarm(id: UUID, isEnabled: Bool? = nil) async throws {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        var alarm = alarms[index]
        alarm.isEnabled = isEnabled ?? !alarm.isEnabled
        alarm.updatedAt = Date()
        try await createOrUpdateAlarm(alarm)
    }

    public func deleteAlarm(id: UUID) async throws {
        try await repository.deleteAlarm(id: id)
        try await scheduler.cancelAlarm(id: id)
        let loaded = try await repository.loadAlarms()
        self.alarms = loaded.sorted { $0.time < $1.time }
    }

    // MARK: - Trigger & Deactivation Lock-In Flow

    /// Triggers an alarm into the active ringing state, starts audio, and locks in the challenge.
    public func triggerAlarm(_ alarm: Alarm) throws {
        if stateMachine.currentState != .idle {
            try? stateMachine.transition(event: .resetToIdle)
        }
        try stateMachine.transition(event: .alarmTriggered(alarmId: alarm.id))
        try stateMachine.transition(event: .startChallenge)
        try audioService.playRinging(sound: alarm.sound, volume: alarm.volume, looping: true)
        activeRingingAlarm = alarm
        persistActiveAlarmId(alarm.id)

        // If the alarm has no challenge (.none), mark challenge completed immediately so user can dismiss
        if alarm.challengeConfig.type == .none {
            try stateMachine.transition(event: .challengeSuccess)
        }
    }

    /// Evaluates whether any enabled alarm matches the current clock hour & minute.
    public func checkAndTriggerDueAlarms(at date: Date, calendar: Calendar = .current) throws -> Alarm? {
        guard activeRingingAlarm == nil else { return nil }
        let currentTime = AlarmTime(date: date, calendar: calendar)
        let weekdayInt = calendar.component(.weekday, from: date)
        let currentWeekday = WeekdaySet(calendarWeekday: weekdayInt)

        for alarm in alarms where alarm.isEnabled && alarm.time == currentTime {
            if alarm.repeatDays.isOneShot {
                try triggerAlarm(alarm)
                return alarm
            } else if let todayBit = currentWeekday, alarm.repeatDays.contains(todayBit) {
                try triggerAlarm(alarm)
                return alarm
            }
        }
        return nil
    }

    /// Updates challenge progress in the lock-in state machine.
    public func recordChallengeProgress(step: Int, totalSteps: Int) throws {
        try stateMachine.transition(event: .updateProgress(step: step, totalSteps: totalSteps))
        if step >= totalSteps && totalSteps > 0 {
            try stateMachine.transition(event: .challengeSuccess)
        }
    }

    /// Marks the active challenge as solved, unlocking the ability to deactivate the alarm.
    public func markChallengeCompleted() throws {
        try stateMachine.transition(event: .challengeSuccess)
    }

    /// Attempts to silence and deactivate the active alarm.
    /// Throws `DeactivationError.deactivationBlocked` if the assigned challenge has NOT been completed.
    public func deactivateActiveAlarm() async throws {
        try stateMachine.transition(event: .requestDeactivation)
        audioService.stopRinging()
        clearPersistedActiveAlarmId()

        if let ringing = activeRingingAlarm {
            // Auto-disable one-shot alarms after firing and completing
            if ringing.repeatDays.isOneShot {
                var disabled = ringing
                disabled.isEnabled = false
                try await createOrUpdateAlarm(disabled)
            }
        }

        activeRingingAlarm = nil
        try stateMachine.transition(event: .resetToIdle)
    }

    // MARK: - Fast Lock-In Crash/Kill Recovery Persistence

    private func persistActiveAlarmId(_ id: UUID) {
        guard let url = activeStateFileURL else { return }
        try? id.uuidString.data(using: .utf8)?.write(to: url, options: .atomic)
    }

    private func loadPersistedActiveAlarmId() -> UUID? {
        guard let url = activeStateFileURL,
              let data = try? Data(contentsOf: url),
              let str = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return nil
        }
        return UUID(uuidString: str)
    }

    private func clearPersistedActiveAlarmId() {
        guard let url = activeStateFileURL else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
