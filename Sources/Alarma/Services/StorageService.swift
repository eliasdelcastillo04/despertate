import Foundation

public enum AppTheme: String, CaseIterable, Identifiable, Codable {
    case dark = "Oscuro"
    case light = "Claro"
    case system = "Automático"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .system: return "circle.righthalf.filled"
        }
    }
}

public final class StorageService: @unchecked Sendable {
    public static let shared = StorageService()

    private let alarmsKey = "alarma_apple_ios_alarms_v1"
    private let logsKey = "alarma_apple_ios_logs_v1"
    private let themeKey = "alarma_apple_ios_theme_v1"
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func loadTheme() -> AppTheme {
        if let saved = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: saved) {
            return theme
        }
        return .dark // Default to dark mode as requested by user
    }

    public func saveTheme(_ theme: AppTheme) {
        userDefaults.set(theme.rawValue, forKey: themeKey)
    }

    public func loadAlarms() -> [Alarm] {
        guard let data = userDefaults.data(forKey: alarmsKey),
              let decoded = try? JSONDecoder().decode([Alarm].self, from: data) else {
            let defaults = defaultAlarms()
            saveAlarms(defaults)
            return defaults
        }
        return decoded
    }

    public func saveAlarms(_ alarms: [Alarm]) {
        if let encoded = try? JSONEncoder().encode(alarms) {
            userDefaults.set(encoded, forKey: alarmsKey)
        }
    }

    public func loadLogs() -> [WakeLog] {
        guard let data = userDefaults.data(forKey: logsKey),
              let decoded = try? JSONDecoder().decode([WakeLog].self, from: data) else {
            let defaults = defaultLogs()
            saveLogs(defaults)
            return defaults
        }
        return decoded
    }

    public func saveLogs(_ logs: [WakeLog]) {
        if let encoded = try? JSONEncoder().encode(logs) {
            userDefaults.set(encoded, forKey: logsKey)
        }
    }

    // MARK: - Initial Mock Seeds
    private func defaultAlarms() -> [Alarm] {
        [
            Alarm(
                timeString: "06:30",
                label: "Despertar Productivo 🚀",
                isEnabled: true,
                repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                sound: .radar,
                volume: 0.9,
                snoozeEnabled: true,
                snoozeDurationMinutes: 9,
                missionType: .math,
                difficulty: .medium,
                category: .wakeUp
            ),
            Alarm(
                timeString: "07:15",
                label: "Gimnasio & Movilidad 🏋️‍♂️",
                isEnabled: true,
                repeatDays: [.monday, .wednesday, .friday],
                sound: .apex,
                volume: 0.85,
                snoozeEnabled: false,
                snoozeDurationMinutes: 5,
                missionType: .shake,
                difficulty: .easy,
                category: .fitness
            ),
            Alarm(
                timeString: "08:45",
                label: "Daily Standup / Trabajo 💼",
                isEnabled: true,
                repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                sound: .chimes,
                volume: 0.75,
                snoozeEnabled: true,
                snoozeDurationMinutes: 9,
                missionType: .memory,
                difficulty: .medium,
                category: .work
            ),
            Alarm(
                timeString: "09:30",
                label: "Fin de Semana Relax ☕",
                isEnabled: false,
                repeatDays: [.saturday, .sunday],
                sound: .breeze,
                volume: 0.7,
                snoozeEnabled: true,
                snoozeDurationMinutes: 9,
                missionType: .rapidTaps,
                difficulty: .easy,
                category: .wakeUp
            ),
            Alarm(
                timeString: "23:00",
                label: "Desconectar Pantallas 🌙",
                isEnabled: true,
                repeatDays: Set(Weekday.allCases),
                sound: .cosmic,
                volume: 0.65,
                snoozeEnabled: false,
                snoozeDurationMinutes: 5,
                missionType: .holdCountdown,
                difficulty: .easy,
                category: .health
            )
        ]
    }

    private func defaultLogs() -> [WakeLog] {
        let calendar = Calendar.current
        let now = Date()

        return [
            WakeLog(
                alarmId: UUID(),
                alarmLabel: "Despertar Productivo 🚀",
                scheduledTime: "06:30",
                wakeTime: "06:32",
                date: calendar.date(byAdding: .day, value: 0, to: now) ?? now,
                snoozeCount: 0,
                missionCompleted: true,
                sleepDurationHours: 7.8,
                consistencyScore: 98,
                status: .perfect,
                notes: "Despertar rápido con reto de cálculo superado."
            ),
            WakeLog(
                alarmId: UUID(),
                alarmLabel: "Despertar Productivo 🚀",
                scheduledTime: "06:30",
                wakeTime: "06:39",
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                snoozeCount: 1,
                missionCompleted: true,
                sleepDurationHours: 7.2,
                consistencyScore: 88,
                status: .snoozed,
                notes: "1 snooze de 9 minutos utilizado."
            ),
            WakeLog(
                alarmId: UUID(),
                alarmLabel: "Despertar Productivo 🚀",
                scheduledTime: "06:30",
                wakeTime: "06:30",
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                snoozeCount: 0,
                missionCompleted: true,
                sleepDurationHours: 8.0,
                consistencyScore: 100,
                status: .perfect
            ),
            WakeLog(
                alarmId: UUID(),
                alarmLabel: "Despertar Productivo 🚀",
                scheduledTime: "06:30",
                wakeTime: "06:48",
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                snoozeCount: 2,
                missionCompleted: true,
                sleepDurationHours: 6.5,
                consistencyScore: 78,
                status: .delayed,
                notes: "Dormí tarde; costó salir de la cama."
            ),
            WakeLog(
                alarmId: UUID(),
                alarmLabel: "Despertar Productivo 🚀",
                scheduledTime: "06:30",
                wakeTime: "06:31",
                date: calendar.date(byAdding: .day, value: -4, to: now) ?? now,
                snoozeCount: 0,
                missionCompleted: true,
                sleepDurationHours: 7.6,
                consistencyScore: 97,
                status: .perfect
            ),
            WakeLog(
                alarmId: UUID(),
                alarmLabel: "Fin de Semana Relax ☕",
                scheduledTime: "09:30",
                wakeTime: "09:35",
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                snoozeCount: 0,
                missionCompleted: false,
                sleepDurationHours: 8.7,
                consistencyScore: 92,
                status: .perfect
            ),
            WakeLog(
                alarmId: UUID(),
                alarmLabel: "Fin de Semana Relax ☕",
                scheduledTime: "09:30",
                wakeTime: "09:50",
                date: calendar.date(byAdding: .day, value: -6, to: now) ?? now,
                snoozeCount: 2,
                missionCompleted: false,
                sleepDurationHours: 9.0,
                consistencyScore: 84,
                status: .snoozed
            )
        ]
    }
}
