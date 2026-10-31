import XCTest
@testable import AlarmaCore

final class AlarmTimeTests: XCTestCase {
    func testValidInitialization() {
        let t1 = AlarmTime(hour: 0, minute: 0)
        XCTAssertNotNil(t1)
        XCTAssertEqual(t1?.hour, 0)
        XCTAssertEqual(t1?.minute, 0)

        let t2 = AlarmTime(hour: 23, minute: 59)
        XCTAssertNotNil(t2)
        XCTAssertEqual(t2?.hour, 23)
        XCTAssertEqual(t2?.minute, 59)

        let t3 = AlarmTime(hour: 12, minute: 30)
        XCTAssertNotNil(t3)
        XCTAssertEqual(t3?.hour, 12)
        XCTAssertEqual(t3?.minute, 30)
    }

    func testInvalidInitializationFails() {
        XCTAssertNil(AlarmTime(hour: -1, minute: 0))
        XCTAssertNil(AlarmTime(hour: 24, minute: 0))
        XCTAssertNil(AlarmTime(hour: 12, minute: -1))
        XCTAssertNil(AlarmTime(hour: 12, minute: 60))
    }

    func testClampingInitialization() {
        let under = AlarmTime(clampingHour: -5, minute: -10)
        XCTAssertEqual(under.hour, 0)
        XCTAssertEqual(under.minute, 0)

        let over = AlarmTime(clampingHour: 50, minute: 100)
        XCTAssertEqual(over.hour, 23)
        XCTAssertEqual(over.minute, 59)
    }

    func testTotalMinutes() {
        XCTAssertEqual(AlarmTime(hour: 0, minute: 0)?.totalMinutes, 0)
        XCTAssertEqual(AlarmTime(hour: 1, minute: 15)?.totalMinutes, 75)
        XCTAssertEqual(AlarmTime(hour: 12, minute: 0)?.totalMinutes, 720)
        XCTAssertEqual(AlarmTime(hour: 23, minute: 59)?.totalMinutes, 1439)
    }

    func testComparableOrdering() {
        let t1 = AlarmTime(hour: 7, minute: 0)!
        let t2 = AlarmTime(hour: 7, minute: 30)!
        let t3 = AlarmTime(hour: 8, minute: 0)!

        XCTAssertTrue(t1 < t2)
        XCTAssertTrue(t2 < t3)
        XCTAssertTrue(t1 < t3)
        XCTAssertFalse(t2 < t1)
        XCTAssertEqual(t1, AlarmTime(hour: 7, minute: 0)!)
    }

    func testFormatting24Hour() {
        XCTAssertEqual(AlarmTime(hour: 0, minute: 5)?.formatted(is24Hour: true), "00:05")
        XCTAssertEqual(AlarmTime(hour: 12, minute: 0)?.formatted(is24Hour: true), "12:00")
        XCTAssertEqual(AlarmTime(hour: 14, minute: 30)?.formatted(is24Hour: true), "14:30")
        XCTAssertEqual(AlarmTime(hour: 23, minute: 59)?.formatted(is24Hour: true), "23:59")
    }

    func testFormatting12Hour() {
        XCTAssertEqual(AlarmTime(hour: 0, minute: 5)?.formatted(is24Hour: false), "12:05 AM")
        XCTAssertEqual(AlarmTime(hour: 11, minute: 59)?.formatted(is24Hour: false), "11:59 AM")
        XCTAssertEqual(AlarmTime(hour: 12, minute: 0)?.formatted(is24Hour: false), "12:00 PM")
        XCTAssertEqual(AlarmTime(hour: 14, minute: 30)?.formatted(is24Hour: false), "2:30 PM")
        XCTAssertEqual(AlarmTime(hour: 23, minute: 59)?.formatted(is24Hour: false), "11:59 PM")
    }

    func testNextDateCalculation() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 30
        components.hour = 10
        components.minute = 0
        components.second = 0
        let refDate = calendar.date(from: components)!

        // Future today at 10:30
        let future = AlarmTime(hour: 10, minute: 30)!
        let nextFuture = future.nextDate(after: refDate, calendar: calendar)
        let futureComp = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextFuture)
        XCTAssertEqual(futureComp.day, 30)
        XCTAssertEqual(futureComp.hour, 10)
        XCTAssertEqual(futureComp.minute, 30)

        // Past today at 09:30 -> fires tomorrow Oct 31
        let past = AlarmTime(hour: 9, minute: 30)!
        let nextPast = past.nextDate(after: refDate, calendar: calendar)
        let pastComp = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextPast)
        XCTAssertEqual(pastComp.day, 31)
        XCTAssertEqual(pastComp.hour, 9)
        XCTAssertEqual(pastComp.minute, 30)
    }

    func testCodableRoundtrip() throws {
        let original = AlarmTime(hour: 18, minute: 45)!
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AlarmTime.self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
