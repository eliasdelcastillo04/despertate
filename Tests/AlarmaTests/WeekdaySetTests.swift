import XCTest
@testable import AlarmaCore

final class WeekdaySetTests: XCTestCase {
    func testPredefinedSets() {
        XCTAssertTrue(WeekdaySet.none.isEmpty)
        XCTAssertTrue(WeekdaySet.none.isOneShot)
        XCTAssertFalse(WeekdaySet.none.isRepeating)
        XCTAssertEqual(WeekdaySet.none.count, 0)

        XCTAssertEqual(WeekdaySet.all.count, 7)
        XCTAssertTrue(WeekdaySet.all.isRepeating)

        XCTAssertEqual(WeekdaySet.weekdays.count, 5)
        XCTAssertEqual(WeekdaySet.weekends.count, 2)
    }

    func testCalendarWeekdayMappings() {
        XCTAssertEqual(WeekdaySet(calendarWeekday: 1), .sunday)
        XCTAssertEqual(WeekdaySet(calendarWeekday: 2), .monday)
        XCTAssertEqual(WeekdaySet(calendarWeekday: 3), .tuesday)
        XCTAssertEqual(WeekdaySet(calendarWeekday: 4), .wednesday)
        XCTAssertEqual(WeekdaySet(calendarWeekday: 5), .thursday)
        XCTAssertEqual(WeekdaySet(calendarWeekday: 6), .friday)
        XCTAssertEqual(WeekdaySet(calendarWeekday: 7), .saturday)
        XCTAssertNil(WeekdaySet(calendarWeekday: 0))
        XCTAssertNil(WeekdaySet(calendarWeekday: 8))
    }

    func testCalendarWeekdaysArray() {
        let set: WeekdaySet = [.monday, .wednesday, .friday]
        XCTAssertEqual(set.calendarWeekdays, [2, 4, 6])
        XCTAssertEqual(WeekdaySet.weekends.calendarWeekdays, [1, 7])
    }

    func testHumanReadableDescriptions() {
        XCTAssertEqual(WeekdaySet.none.description, "Never")
        XCTAssertEqual(WeekdaySet.all.description, "Every day")
        XCTAssertEqual(WeekdaySet.weekdays.description, "Weekdays")
        XCTAssertEqual(WeekdaySet.weekends.description, "Weekends")
        let custom: WeekdaySet = [.monday, .wednesday, .friday]
        XCTAssertEqual(custom.description, "Mon, Wed, Fri")
    }

    func testNextTriggerDateRecurringCalculations() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        // Reference: 2026-10-30 is a Friday (weekday 6) at 12:00 GMT
        var comp = DateComponents()
        comp.year = 2026
        comp.month = 10
        comp.day = 30
        comp.hour = 12
        comp.minute = 0
        comp.second = 0
        let fridayNoon = calendar.date(from: comp)!
        XCTAssertEqual(calendar.component(.weekday, from: fridayNoon), 6)

        // Case 1: Friday 14:00 (future today)
        let futureToday = AlarmTime(hour: 14, minute: 0)!
        let next1 = WeekdaySet.weekdays.nextTriggerDate(for: futureToday, after: fridayNoon, calendar: calendar)
        let comp1 = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: next1)
        XCTAssertEqual(comp1.day, 30)
        XCTAssertEqual(comp1.hour, 14)
        XCTAssertEqual(comp1.minute, 0)

        // Case 2: Friday 08:00 (past today) -> Next weekday is Monday Nov 2!
        let pastToday = AlarmTime(hour: 8, minute: 0)!
        let next2 = WeekdaySet.weekdays.nextTriggerDate(for: pastToday, after: fridayNoon, calendar: calendar)
        let comp2 = calendar.dateComponents([.year, .month, .day, .weekday, .hour, .minute], from: next2)
        XCTAssertEqual(comp2.weekday, 2) // Monday
        XCTAssertEqual(comp2.month, 11)
        XCTAssertEqual(comp2.day, 2)
        XCTAssertEqual(comp2.hour, 8)

        // Case 3: Weekend alarm from Friday noon -> Saturday Oct 31!
        let next3 = WeekdaySet.weekends.nextTriggerDate(for: pastToday, after: fridayNoon, calendar: calendar)
        let comp3 = calendar.dateComponents([.year, .month, .day, .weekday], from: next3)
        XCTAssertEqual(comp3.weekday, 7) // Saturday
        XCTAssertEqual(comp3.day, 31)
    }

    func testCodableRoundtrip() throws {
        let original: WeekdaySet = [.tuesday, .thursday]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WeekdaySet.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
