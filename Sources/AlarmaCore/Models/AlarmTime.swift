import Foundation

/// Represents a specific time of day (hour and minute) decoupled from calendar date and timezone drift.
public struct AlarmTime: Hashable, Equatable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let hour: Int
    public let minute: Int

    /// Failable initializer. Returns nil if hour is not within 0...23 or minute is not within 0...59.
    public init?(hour: Int, minute: Int) {
        guard hour >= 0, hour <= 23, minute >= 0, minute <= 59 else {
            return nil
        }
        self.hour = hour
        self.minute = minute
    }

    /// Clamping initializer ensuring hour is bounded within 0...23 and minute within 0...59.
    public init(clampingHour hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    /// Initializes AlarmTime from a Date using the specified Calendar.
    public init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        self.hour = components.hour ?? 0
        self.minute = components.minute ?? 0
    }

    /// Total minutes elapsed since midnight (0...1439).
    public var totalMinutes: Int {
        hour * 60 + minute
    }

    public static func < (lhs: AlarmTime, rhs: AlarmTime) -> Bool {
        lhs.totalMinutes < rhs.totalMinutes
    }

    public var description: String {
        formatted(is24Hour: true)
    }

    /// Formats the time as a 24-hour string ("07:05", "23:59").
    public var formatted24Hour: String {
        formatted(is24Hour: true)
    }

    /// Returns a formatted string in either 24-hour ("07:05") or 12-hour ("7:05 AM") format.
    public func formatted(is24Hour: Bool) -> String {
        if is24Hour {
            return String(format: "%02d:%02d", hour, minute)
        } else {
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour % 12 == 0 ? 12 : hour % 12
            return String(format: "%d:%02d %@", displayHour, minute, period)
        }
    }

    /// Localized or custom format helper.
    public func formattedLocalized(is24Hour: Bool) -> String {
        formatted(is24Hour: is24Hour)
    }

    /// Calculates the next occurrence Date for this AlarmTime on or after the referenceDate.
    public func nextDate(after referenceDate: Date = Date(), calendar: Calendar = .current) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let targetDate = calendar.date(from: components) else {
            return referenceDate
        }

        if targetDate > referenceDate {
            return targetDate
        } else {
            return calendar.date(byAdding: .day, value: 1, to: targetDate) ?? targetDate
        }
    }
}
