import XCTest
@testable import AlarmaCore

final class JSONFileAlarmRepositoryTests: XCTestCase {
    var tempDirectoryURL: URL!
    var fileURL: URL!
    var repository: JSONFileAlarmRepository!

    override func setUp() async throws {
        tempDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AlarmaTests-\(UUID().uuidString)", isDirectory: true)
        fileURL = tempDirectoryURL.appendingPathComponent("alarms.json")
        repository = JSONFileAlarmRepository(fileURL: fileURL)
    }

    override func tearDown() async throws {
        if let dir = tempDirectoryURL {
            try? FileManager.default.removeItem(at: dir)
        }
    }

    func testInitialLoadFromNonExistentFileReturnsEmpty() async throws {
        let alarms = try await repository.loadAlarms()
        XCTAssertTrue(alarms.isEmpty)
    }

    func testSaveAndLoadAlarms() async throws {
        let alarm1 = Alarm(
            title: "Morning Alarm",
            time: AlarmTime(hour: 7, minute: 0)!,
            repeatDays: .weekdays,
            sound: .radar,
            challengeConfig: .standardMath
        )
        let alarm2 = Alarm(
            title: "Weekend Jog",
            time: AlarmTime(hour: 9, minute: 30)!,
            repeatDays: .weekends,
            sound: .beacon,
            challengeConfig: .standardShake
        )

        try await repository.saveAlarms([alarm1, alarm2])
        let loaded = try await repository.loadAlarms()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, alarm1.id)
        XCTAssertEqual(loaded[0].title, "Morning Alarm")
        XCTAssertEqual(loaded[1].id, alarm2.id)
        XCTAssertEqual(loaded[1].sound, .beacon)
    }

    func testUpsertNewAndExistingAlarm() async throws {
        let alarm = Alarm(
            title: "Original",
            time: AlarmTime(hour: 8, minute: 0)!,
            repeatDays: .none
        )

        try await repository.upsertAlarm(alarm)
        var loaded = try await repository.loadAlarms()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Original")

        var modified = alarm
        modified.title = "Modified"
        modified.isEnabled = false
        try await repository.upsertAlarm(modified)

        loaded = try await repository.loadAlarms()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Modified")
        XCTAssertEqual(loaded.first?.isEnabled, false)
    }

    func testDeleteAlarm() async throws {
        let alarm1 = Alarm(time: AlarmTime(hour: 7, minute: 0)!)
        let alarm2 = Alarm(time: AlarmTime(hour: 8, minute: 0)!)
        try await repository.saveAlarms([alarm1, alarm2])

        try await repository.deleteAlarm(id: alarm1.id)
        let loaded = try await repository.loadAlarms()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, alarm2.id)

        try await repository.deleteAlarm(id: UUID())
        let loadedAgain = try await repository.loadAlarms()
        XCTAssertEqual(loadedAgain.count, 1)
    }

    func testPersistenceAcrossRepositoryInstances() async throws {
        let alarm = Alarm(title: "Persistent", time: AlarmTime(hour: 6, minute: 30)!)
        try await repository.saveAlarms([alarm])

        let repo2 = JSONFileAlarmRepository(fileURL: fileURL)
        let loaded = try await repo2.loadAlarms()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "Persistent")
    }

    func testDeepDirectoryCreation() async throws {
        let deepURL = tempDirectoryURL
            .appendingPathComponent("nested", isDirectory: true)
            .appendingPathComponent("subfolder", isDirectory: true)
            .appendingPathComponent("alarms.json")

        let deepRepo = JSONFileAlarmRepository(fileURL: deepURL)
        let alarm = Alarm(time: AlarmTime(hour: 10, minute: 0)!)
        try await deepRepo.saveAlarms([alarm])

        let loaded = try await deepRepo.loadAlarms()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: deepURL.path))
    }

    func testCorruptionRecoverySelfHealing() async throws {
        try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)
        let corruptData = "INVALID CORRUPTED JSON BYTE SEQUENCE 12345 {[[".data(using: .utf8)!
        try corruptData.write(to: fileURL, options: .atomic)

        let recovered = try await repository.loadAlarms()
        XCTAssertTrue(recovered.isEmpty)

        let files = try FileManager.default.contentsOfDirectory(atPath: tempDirectoryURL.path)
        let backupExists = files.contains { $0.contains("corrupted") }
        XCTAssertTrue(backupExists, "Corrupted backup file must be preserved on disk")
    }

    func testConcurrentUpsertsActorThreadSafety() async throws {
        let repo = self.repository!
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<20 {
                group.addTask {
                    let alarm = Alarm(
                        title: "Concurrent Alarm \(index)",
                        time: AlarmTime(hour: index % 24, minute: index % 60)!
                    )
                    try? await repo.upsertAlarm(alarm)
                }
            }
        }

        let loaded = try await repository.loadAlarms()
        XCTAssertEqual(loaded.count, 20)
    }
}
