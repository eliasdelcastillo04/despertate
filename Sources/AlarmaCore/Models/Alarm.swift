import Foundation

/// Core alarm domain aggregate root.
public struct Alarm: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var label: String {
        get { title }
        set { title = newValue }
    }
    public var time: AlarmTime
    public var repeatDays: WeekdaySet
    public var isEnabled: Bool
    public var sound: SoundAsset
    public var volume: Float
    public var allowsSnooze: Bool
    public var isSnoozeEnabled: Bool {
        get { allowsSnooze }
        set { allowsSnooze = newValue }
    }
    public var snoozeDurationMinutes: Int
    public var challengeConfig: ChallengeConfiguration
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String = "Alarma",
        time: AlarmTime,
        repeatDays: WeekdaySet = .none,
        isEnabled: Bool = true,
        sound: SoundAsset = .radar,
        volume: Float = 1.0,
        allowsSnooze: Bool = true,
        snoozeDurationMinutes: Int = 9,
        challengeConfig: ChallengeConfiguration = .standardMath,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.sound = sound
        self.volume = min(max(volume, 0.0), 1.0)
        self.allowsSnooze = allowsSnooze
        self.snoozeDurationMinutes = max(1, snoozeDurationMinutes)
        self.challengeConfig = challengeConfig
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Convenience initializer supporting `label` and `isSnoozeEnabled` parameter names.
    public init(
        id: UUID = UUID(),
        label: String,
        time: AlarmTime,
        repeatDays: WeekdaySet = .none,
        isEnabled: Bool = true,
        sound: SoundAsset = .radar,
        volume: Float = 1.0,
        isSnoozeEnabled: Bool = true,
        snoozeDurationMinutes: Int = 9,
        challengeConfig: ChallengeConfiguration = .standardMath,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.init(
            id: id,
            title: label,
            time: time,
            repeatDays: repeatDays,
            isEnabled: isEnabled,
            sound: sound,
            volume: volume,
            allowsSnooze: isSnoozeEnabled,
            snoozeDurationMinutes: snoozeDurationMinutes,
            challengeConfig: challengeConfig,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Standard starter default alarm for new installs.
    public static var defaultStarterAlarm: Alarm {
        Alarm(
            title: "Despertar Productivo ☀️",
            time: AlarmTime(clampingHour: 7, minute: 0),
            repeatDays: .weekdays,
            isEnabled: true,
            sound: .radar,
            volume: 1.0,
            allowsSnooze: true,
            snoozeDurationMinutes: 9,
            challengeConfig: ChallengeConfiguration(type: .math, difficulty: .medium, problemCount: 3)
        )
    }

    /// Computes next firing date. Returns nil if the alarm is disabled.
    public func nextTriggerDate(after referenceDate: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard isEnabled else { return nil }
        return repeatDays.nextTriggerDate(for: time, after: referenceDate, calendar: calendar)
    }
}
