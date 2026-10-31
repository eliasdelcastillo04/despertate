import Foundation

/// Represents a set of recurring weekdays for an alarm using a compact 7-bit mask representation.
public struct WeekdaySet: OptionSet, Codable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    // Individual day bit flags matching Apple Calendar weekday indices (Sunday = 1 ... Saturday = 7)
    public static let sunday    = WeekdaySet(rawValue: 1 << 0) // Calendar weekday 1
    public static let monday    = WeekdaySet(rawValue: 1 << 1) // Calendar weekday 2
    public static let tuesday   = WeekdaySet(rawValue: 1 << 2) // Calendar weekday 3
    public static let wednesday = WeekdaySet(rawValue: 1 << 3) // Calendar weekday 4
    public static let thursday  = WeekdaySet(rawValue: 1 << 4) // Calendar weekday 5
    public static let friday    = WeekdaySet(rawValue: 1 << 5) // Calendar weekday 6
    public static let saturday  = WeekdaySet(rawValue: 1 << 6) // Calendar weekday 7

    // Canonical Presets
    public static let none: WeekdaySet = []
    public static let never: WeekdaySet = []
    public static let all: WeekdaySet = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    public static let allDays: WeekdaySet = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
    public static let weekdays: WeekdaySet = [.monday, .tuesday, .wednesday, .thursday, .friday]
    public static let weekends: WeekdaySet = [.saturday, .sunday]

    /// True if the alarm recurs on one or more days.
    public var isRepeating: Bool {
        !isEmpty
    }

    /// True if the alarm is a non-repeating one-shot alarm.
    public var isOneShot: Bool {
        isEmpty
    }

    /// Count of active repeating days.
    public var count: Int {
        rawValue.nonzeroBitCount
    }

    /// Initializes from an Apple Calendar weekday integer (1 = Sunday ... 7 = Saturday).
    public init?(calendarWeekday: Int) {
        switch calendarWeekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: return nil
        }
    }

    /// Sorted array of Calendar weekday integers (1...7) for UserNotifications scheduling.
    public var calendarWeekdays: [Int] {
        var days: [Int] = []
        if contains(.sunday) { days.append(1) }
        if contains(.monday) { days.append(2) }
        if contains(.tuesday) { days.append(3) }
        if contains(.wednesday) { days.append(4) }
        if contains(.thursday) { days.append(5) }
        if contains(.friday) { days.append(6) }
        if contains(.saturday) { days.append(7) }
        return days
    }

    public var description: String {
        if isEmpty {
            return "Never"
        }
        if self == .all {
            return "Every day"
        }
        if self == .weekdays {
            return "Weekdays"
        }
        if self == .weekends {
            return "Weekends"
        }

        let dayNames: [(WeekdaySet, String)] = [
            (.sunday, "Sun"),
            (.monday, "Mon"),
            (.tuesday, "Tue"),
            (.wednesday, "Wed"),
            (.thursday, "Thu"),
            (.friday, "Fri"),
            (.saturday, "Sat")
        ]
        let names = dayNames.filter { contains($0.0) }.map { $0.1 }
        return names.joined(separator: ", ")
    }

    /// Computes the exact next trigger date for the specified AlarmTime.
    public func nextTriggerDate(
        for time: AlarmTime,
        after referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        if isOneShot {
            return time.nextDate(after: referenceDate, calendar: calendar)
        }

        let refWeekday = calendar.component(.weekday, from: referenceDate)

        // If today matches recurring days, check if the time is strictly in the future today
        if let currentDaySet = WeekdaySet(calendarWeekday: refWeekday), contains(currentDaySet) {
            var todayComponents = calendar.dateComponents([.year, .month, .day], from: referenceDate)
            todayComponents.hour = time.hour
            todayComponents.minute = time.minute
            todayComponents.second = 0
            if let candidate = calendar.date(from: todayComponents), candidate > referenceDate {
                return candidate
            }
        }

        // Look forward across the next 1...7 days
        for offset in 1...7 {
            guard let nextDay = calendar.date(byAdding: .day, value: offset, to: referenceDate) else { continue }
            let nextWeekday = calendar.component(.weekday, from: nextDay)
            if let daySet = WeekdaySet(calendarWeekday: nextWeekday), contains(daySet) {
                var components = calendar.dateComponents([.year, .month, .day], from: nextDay)
                components.hour = time.hour
                components.minute = time.minute
                components.second = 0
                if let candidate = calendar.date(from: components) {
                    return candidate
                }
            }
        }

        return time.nextDate(after: referenceDate, calendar: calendar)
    }
}
