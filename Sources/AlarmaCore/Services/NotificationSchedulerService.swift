import Foundation
import UserNotifications

/// Platform-agnostic descriptor of a scheduled local notification trigger for inspection & testing.
public struct ScheduledNotificationDescriptor: Equatable, Hashable, Codable, Sendable {
    public let identifier: String
    public let alarmId: UUID
    public let title: String
    public let body: String
    public let soundName: String
    public let hour: Int
    public let minute: Int
    public let weekday: Int?
    public let repeats: Bool

    public init(
        identifier: String,
        alarmId: UUID,
        title: String,
        body: String,
        soundName: String,
        hour: Int,
        minute: Int,
        weekday: Int?,
        repeats: Bool
    ) {
        self.identifier = identifier
        self.alarmId = alarmId
        self.title = title
        self.body = body
        self.soundName = soundName
        self.hour = hour
        self.minute = minute
        self.weekday = weekday
        self.repeats = repeats
    }
}

/// Contract for scheduling, cancelling, and inspecting local alarm notifications.
public protocol NotificationSchedulerProtocol: Sendable {
    func requestAuthorization() async throws -> Bool
    func scheduleAlarm(_ alarm: Alarm) async throws
    func cancelAlarm(id: UUID) async throws
    func rescheduleAll(alarms: [Alarm]) async throws
    func buildDescriptors(for alarm: Alarm) -> [ScheduledNotificationDescriptor]
}

extension NotificationSchedulerProtocol {
    /// Generates notification descriptors for an alarm (one-shot or per-weekday repeating).
    public func buildDescriptors(for alarm: Alarm) -> [ScheduledNotificationDescriptor] {
        guard alarm.isEnabled else { return [] }
        let title = alarm.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Alarma" : alarm.title
        let body = "¡Hora de despertar! Resuelve el reto (\(alarm.challengeConfig.type.displayName)) para desactivar."
        let soundName = "\(alarm.sound.fileName).\(alarm.sound.fileExtension)"

        if !alarm.repeatDays.isRepeating {
            let identifier = "alarm_\(alarm.id.uuidString)"
            return [
                ScheduledNotificationDescriptor(
                    identifier: identifier,
                    alarmId: alarm.id,
                    title: title,
                    body: body,
                    soundName: soundName,
                    hour: alarm.time.hour,
                    minute: alarm.time.minute,
                    weekday: nil,
                    repeats: false
                )
            ]
        } else {
            return alarm.repeatDays.calendarWeekdays.map { weekday in
                ScheduledNotificationDescriptor(
                    identifier: "alarm_\(alarm.id.uuidString)_\(weekday)",
                    alarmId: alarm.id,
                    title: title,
                    body: body,
                    soundName: soundName,
                    hour: alarm.time.hour,
                    minute: alarm.time.minute,
                    weekday: weekday,
                    repeats: true
                )
            }
        }
    }
}

/// Production notification scheduler backed by `UNUserNotificationCenter` with a 48-notification sliding window cap.
public final class UNNotificationScheduler: NotificationSchedulerProtocol, @unchecked Sendable {
    public static let categoryIdentifier = "ALARM_RING_CATEGORY"
    public static let maxScheduledNotifications = 48

    public init() {}

    public func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func scheduleAlarm(_ alarm: Alarm) async throws {
        try await cancelAlarm(id: alarm.id)
        guard alarm.isEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let descriptors = buildDescriptors(for: alarm)
        for desc in descriptors {
            let req = makeUNRequest(from: desc)
            try await center.add(req)
        }
    }

    public func cancelAlarm(id: UUID) async throws {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let prefix = "alarm_\(id.uuidString)"
        let toRemove = pending.map(\.identifier).filter { $0 == prefix || $0.hasPrefix(prefix + "_") }
        if !toRemove.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    public func rescheduleAll(alarms: [Alarm]) async throws {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        var allDescriptors: [ScheduledNotificationDescriptor] = []
        for alarm in alarms where alarm.isEnabled {
            allDescriptors.append(contentsOf: buildDescriptors(for: alarm))
        }

        let capped = Array(allDescriptors.prefix(Self.maxScheduledNotifications))
        for desc in capped {
            try await center.add(makeUNRequest(from: desc))
        }
    }

    private func makeUNRequest(from descriptor: ScheduledNotificationDescriptor) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = descriptor.title
        content.body = descriptor.body
        content.categoryIdentifier = Self.categoryIdentifier
        content.sound = UNNotificationSound(named: UNNotificationSoundName(descriptor.soundName))
        content.userInfo = ["alarmId": descriptor.alarmId.uuidString]

        var components = DateComponents()
        components.hour = descriptor.hour
        components.minute = descriptor.minute
        components.second = 0
        if let weekday = descriptor.weekday {
            components.weekday = weekday
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: descriptor.repeats)
        return UNNotificationRequest(identifier: descriptor.identifier, content: content, trigger: trigger)
    }
}

/// Thread-safe mock notification scheduler for deterministic headless unit and E2E testing.
public actor MockNotificationScheduler: NotificationSchedulerProtocol {
    public static let maxScheduledNotifications = 48

    public private(set) var scheduledDescriptors: [ScheduledNotificationDescriptor] = []
    public private(set) var cancelledAlarmIDs: [UUID] = []
    public var authorizationGranted: Bool = true

    public init(authorizationGranted: Bool = true) {
        self.authorizationGranted = authorizationGranted
    }

    public func requestAuthorization() async throws -> Bool {
        return authorizationGranted
    }

    public func scheduleAlarm(_ alarm: Alarm) async throws {
        try await cancelAlarm(id: alarm.id)
        guard alarm.isEnabled else { return }
        let descriptors = buildDescriptors(for: alarm)
        let remainingSlots = max(0, Self.maxScheduledNotifications - scheduledDescriptors.count)
        scheduledDescriptors.append(contentsOf: descriptors.prefix(remainingSlots))
    }

    public func cancelAlarm(id: UUID) async throws {
        cancelledAlarmIDs.append(id)
        scheduledDescriptors.removeAll { $0.alarmId == id }
    }

    public func rescheduleAll(alarms: [Alarm]) async throws {
        scheduledDescriptors.removeAll()
        var all: [ScheduledNotificationDescriptor] = []
        for alarm in alarms where alarm.isEnabled {
            all.append(contentsOf: buildDescriptors(for: alarm))
        }
        scheduledDescriptors = Array(all.prefix(Self.maxScheduledNotifications))
    }
}
