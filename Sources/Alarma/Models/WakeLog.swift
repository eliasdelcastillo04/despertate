import Foundation

public enum LogStatus: String, Codable, CaseIterable, Identifiable {
    case perfect = "A tiempo"
    case snoozed = "Postergada"
    case delayed = "Retraso"
    case missed = "Perdida"

    public var id: String { rawValue }
}

public struct WakeLog: Identifiable, Codable, Hashable {
    public var id: UUID
    public var alarmId: UUID
    public var alarmLabel: String
    public var scheduledTime: String
    public var wakeTime: String
    public var date: Date
    public var snoozeCount: Int
    public var missionCompleted: Bool
    public var sleepDurationHours: Double
    public var consistencyScore: Int // 0 to 100
    public var status: LogStatus
    public var notes: String?

    public init(
        id: UUID = UUID(),
        alarmId: UUID,
        alarmLabel: String,
        scheduledTime: String,
        wakeTime: String,
        date: Date,
        snoozeCount: Int,
        missionCompleted: Bool,
        sleepDurationHours: Double,
        consistencyScore: Int,
        status: LogStatus,
        notes: String? = nil
    ) {
        self.id = id
        self.alarmId = alarmId
        self.alarmLabel = alarmLabel
        self.scheduledTime = scheduledTime
        self.wakeTime = wakeTime
        self.date = date
        self.snoozeCount = snoozeCount
        self.missionCompleted = missionCompleted
        self.sleepDurationHours = sleepDurationHours
        self.consistencyScore = consistencyScore
        self.status = status
        self.notes = notes
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }

    public var fullFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "es_ES")
        return formatter.string(from: date)
    }
}
