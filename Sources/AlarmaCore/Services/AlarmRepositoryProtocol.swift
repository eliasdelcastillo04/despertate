import Foundation

/// Contract for thread-safe, asynchronous alarm persistence operations.
public protocol AlarmRepositoryProtocol: Sendable {
    func loadAlarms() async throws -> [Alarm]
    func saveAlarms(_ alarms: [Alarm]) async throws
    func upsertAlarm(_ alarm: Alarm) async throws
    func deleteAlarm(id: UUID) async throws
}
