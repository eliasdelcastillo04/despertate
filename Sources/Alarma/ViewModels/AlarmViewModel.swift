import Foundation
import SwiftUI
import Observation
import AlarmaCore

@Observable
@MainActor
public final class AlarmViewModel {
    public var alarms: [Alarm] = [] {
        didSet {
            StorageService.shared.saveAlarms(alarms)
            recalculateMetrics()
            syncNotifications()
        }
    }

    public var logs: [WakeLog] = [] {
        didSet {
            StorageService.shared.saveLogs(logs)
            recalculateMetrics()
        }
    }

    public var metrics: AlarmMetrics = AlarmMetrics()

    // Active Ringing & Challenge Lock-In State
    public var activeRingingAlarm: Alarm? = nil
    public let deactivationStateMachine = AlarmDeactivationStateMachine()
    public var snoozeCountForCurrentSession: Int = 0

    // UI state
    public var selectedAlarm: Alarm?
    public var selectedLog: WakeLog?
    public var isShowingEditSheet: Bool = false
    public var isShowingChatSheet: Bool = false
    public var isShowingNewAlarmSheet: Bool = false
    public var isSoundPlaying: Bool = false

    // Theme & Appearance
    public var selectedTheme: AppTheme = StorageService.shared.loadTheme() {
        didSet {
            StorageService.shared.saveTheme(selectedTheme)
            HapticManager.triggerImpact(.light)
        }
    }

    public var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }

    // Filter and search
    public var searchQuery: String = ""
    public var statusFilter: LogStatus? = nil

    private let notificationScheduler = UNNotificationScheduler()
    private var clockTimer: Timer?
    private var lastTriggeredMinuteKey: String = ""

    public init() {
        self.alarms = StorageService.shared.loadAlarms()
        self.logs = StorageService.shared.loadLogs()
        recalculateMetrics()
        requestNotificationPermissionsAndSync()
        startClockObserver()
    }

    // MARK: - Clock Monitor & Notification Sync

    private func requestNotificationPermissionsAndSync() {
        let scheduler = self.notificationScheduler
        let coreAlarms = self.alarms.map { $0.toCoreAlarm() }
        Task {
            _ = try? await scheduler.requestAuthorization()
            try? await scheduler.rescheduleAll(alarms: coreAlarms)
        }
    }

    private func syncNotifications() {
        let scheduler = self.notificationScheduler
        let coreAlarms = self.alarms.map { $0.toCoreAlarm() }
        Task {
            try? await scheduler.rescheduleAll(alarms: coreAlarms)
        }
    }

    private func startClockObserver() {
        clockTimer?.invalidate()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateClockTick()
            }
        }
    }

    public func evaluateClockTick(now: Date = Date()) {
        guard activeRingingAlarm == nil else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let weekdayInt = calendar.component(.weekday, from: now)
        let currentHHMM = String(format: "%02d:%02d", hour, minute)
        let minuteKey = "\(calendar.component(.day, from: now))-\(currentHHMM)"

        guard minuteKey != lastTriggeredMinuteKey else { return }

        for alarm in alarms where alarm.isEnabled && alarm.timeString == currentHHMM {
            let matchesDay = alarm.repeatDays.isEmpty ||
                (Weekday(rawValue: weekdayInt).map { alarm.repeatDays.contains($0) } ?? false)
            if matchesDay {
                lastTriggeredMinuteKey = minuteKey
                triggerAlarm(alarm)
                break
            }
        }
    }

    // MARK: - Trigger & Deactivation Lock-In Actions

    public func triggerAlarm(_ alarm: Alarm) {
        if deactivationStateMachine.currentState != .idle {
            try? deactivationStateMachine.transition(event: .resetToIdle)
        }
        try? deactivationStateMachine.transition(event: .alarmTriggered(alarmId: alarm.id))
        try? deactivationStateMachine.transition(event: .startChallenge)
        if alarm.missionType == .none {
            try? deactivationStateMachine.transition(event: .challengeSuccess)
        }

        snoozeCountForCurrentSession = 0
        activeRingingAlarm = alarm
        isSoundPlaying = true
        SoundEngine.shared.startAlarmLoop(sound: alarm.sound, volume: alarm.volume)
        HapticManager.triggerNotification(.warning)
    }

    public func completeActiveAlarmChallenge() {
        guard let alarm = activeRingingAlarm else { return }

        try? deactivationStateMachine.transition(event: .challengeSuccess)
        try? deactivationStateMachine.transition(event: .requestDeactivation)

        SoundEngine.shared.stop()
        isSoundPlaying = false
        HapticManager.triggerNotification(.success)

        // If one-shot alarm, disable it after completion
        if alarm.repeatDays.isEmpty,
           let idx = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[idx].isEnabled = false
        }

        // Record WakeLog entry
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let wakeTimeStr = formatter.string(from: Date())
        let logStatus: LogStatus = snoozeCountForCurrentSession == 0 ? .perfect : .snoozed
        let score = max(65, 100 - (snoozeCountForCurrentSession * 10))
        let newLog = WakeLog(
            alarmId: alarm.id,
            alarmLabel: alarm.label,
            scheduledTime: alarm.timeString,
            wakeTime: wakeTimeStr,
            date: Date(),
            snoozeCount: snoozeCountForCurrentSession,
            missionCompleted: alarm.missionType != .none,
            sleepDurationHours: 7.5,
            consistencyScore: score,
            status: logStatus,
            notes: "Reto '\(alarm.missionType.rawValue)' (\(alarm.difficulty.rawValue)) completado con éxito."
        )
        logs.insert(newLog, at: 0)

        activeRingingAlarm = nil
        try? deactivationStateMachine.transition(event: .resetToIdle)
    }

    // MARK: - Alarm CRUD Actions

    public func toggleAlarm(_ alarm: Alarm) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isEnabled.toggle()
        HapticManager.triggerImpact(.light)
    }

    public func saveAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.insert(alarm, at: 0)
        }
        HapticManager.triggerNotification(.success)
    }

    public func deleteAlarm(_ alarm: Alarm) {
        alarms.removeAll(where: { $0.id == alarm.id })
        if selectedAlarm?.id == alarm.id {
            selectedAlarm = nil
        }
        HapticManager.triggerImpact(.medium)
    }

    public func duplicateAlarm(_ alarm: Alarm) {
        var copy = alarm
        copy.id = UUID()
        copy.label = "\(alarm.label) (Copia)"
        copy.createdAt = Date()
        alarms.insert(copy, at: 0)
        HapticManager.triggerNotification(.success)
    }

    public func updateLogStatus(logId: UUID, newStatus: LogStatus) {
        guard let index = logs.firstIndex(where: { $0.id == logId }) else { return }
        logs[index].status = newStatus
        if selectedLog?.id == logId {
            selectedLog?.status = newStatus
        }
        HapticManager.triggerNotification(.success)
    }

    public func previewSound(_ sound: AlarmSound, volume: Double = 0.8) {
        isSoundPlaying = true
        SoundEngine.shared.preview(sound: sound, volume: volume)
    }

    public func stopSound() {
        isSoundPlaying = false
        SoundEngine.shared.stop()
    }

    // MARK: - Filtered Logs
    public var filteredLogs: [WakeLog] {
        logs.filter { log in
            let matchesQuery = searchQuery.isEmpty ||
                log.alarmLabel.localizedCaseInsensitiveContains(searchQuery) ||
                log.scheduledTime.contains(searchQuery) ||
                log.wakeTime.contains(searchQuery)

            let matchesStatus = statusFilter == nil || log.status == statusFilter
            return matchesQuery && matchesStatus
        }
    }

    public var nextActiveAlarm: Alarm? {
        alarms.filter { $0.isEnabled }.sorted { $0.timeString < $1.timeString }.first
    }

    // MARK: - Metrics
    private func recalculateMetrics() {
        let activeCount = alarms.filter { $0.isEnabled }.count

        guard !logs.isEmpty else {
            metrics = AlarmMetrics(
                totalAlarms: alarms.count,
                activeAlarms: activeCount,
                averageWakeTimeString: "06:45",
                snoozeRatePercentage: 0,
                consistencyScoreAverage: 90,
                weeklyTrendPercentage: 2.0
            )
            return
        }

        var totalMinutes = 0
        var totalConsistency = 0
        var snoozedLogs = 0

        for log in logs {
            let parts = log.wakeTime.split(separator: ":").compactMap { Int($0) }
            if parts.count == 2 {
                totalMinutes += parts[0] * 60 + parts[1]
            }
            totalConsistency += log.consistencyScore
            if log.snoozeCount > 0 {
                snoozedLogs += 1
            }
        }

        let avgMinutes = totalMinutes / logs.count
        let avgH = String(format: "%02d", avgMinutes / 60)
        let avgM = String(format: "%02d", avgMinutes % 60)
        let snoozeRate = Int(Double(snoozedLogs) / Double(logs.count) * 100)
        let avgConsistency = totalConsistency / logs.count

        metrics = AlarmMetrics(
            totalAlarms: alarms.count,
            activeAlarms: activeCount,
            averageWakeTimeString: "\(avgH):\(avgM)",
            snoozeRatePercentage: snoozeRate,
            consistencyScoreAverage: avgConsistency,
            weeklyTrendPercentage: 4.8
        )
    }
}
