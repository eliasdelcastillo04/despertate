import Foundation
import AlarmaCore

public enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    public var id: Int { rawValue }

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public var shortName: String {
        switch self {
        case .sunday: return "D"
        case .monday: return "L"
        case .tuesday: return "Ma"
        case .wednesday: return "Mi"
        case .thursday: return "J"
        case .friday: return "V"
        case .saturday: return "S"
        }
    }

    public var mediumName: String {
        switch self {
        case .sunday: return "Dom"
        case .monday: return "Lun"
        case .tuesday: return "Mar"
        case .wednesday: return "Mié"
        case .thursday: return "Jue"
        case .friday: return "Vie"
        case .saturday: return "Sáb"
        }
    }
}

public enum AlarmSound: String, Codable, CaseIterable, Identifiable, Sendable {
    case radar = "Radar"
    case chimes = "Campanas Zen"
    case apex = "Apex"
    case breeze = "Brisa Matutina"
    case cosmic = "Cosmos"

    public var id: String { rawValue }

    public var coreSoundAsset: SoundAsset {
        switch self {
        case .radar: return .radar
        case .chimes: return .chimes
        case .apex: return .apex
        case .breeze: return .breeze
        case .cosmic: return .cosmic
        }
    }
}

public enum MissionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case math = "Cálculo mental"
    case shake = "Agitar iPhone"
    case memory = "Secuencia de memoria"
    case rapidTaps = "Toques rápidos"
    case holdCountdown = "Mantener presionado"
    case qr = "Escanear QR"
    case none = "Sin reto"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .none: return "bell"
        case .math: return "plus.slash.minus"
        case .shake: return "iphone.radiowaves.left.and.right"
        case .memory: return "square.grid.2x2.fill"
        case .rapidTaps: return "hand.tap.fill"
        case .holdCountdown: return "timer"
        case .qr: return "qrcode.viewfinder"
        }
    }

    public var coreChallengeType: ChallengeType {
        switch self {
        case .none: return .none
        case .math: return .math
        case .shake: return .shake
        case .memory: return .memory
        case .rapidTaps, .qr: return .rapidTaps
        case .holdCountdown: return .holdCountdown
        }
    }
}

public enum MissionDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy = "Fácil"
    case medium = "Medio"
    case hard = "Difícil"

    public var id: String { rawValue }

    public var coreDifficulty: ChallengeDifficulty {
        switch self {
        case .easy: return .easy
        case .medium: return .medium
        case .hard: return .hard
        }
    }
}

public enum AlarmCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case wakeUp = "Despertar"
    case fitness = "Ejercicio"
    case work = "Trabajo"
    case health = "Salud"
    case custom = "Personalizado"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .wakeUp: return "sun.horizon.fill"
        case .fitness: return "figure.run"
        case .work: return "briefcase.fill"
        case .health: return "pills.fill"
        case .custom: return "star.fill"
        }
    }
}

public struct Alarm: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var timeString: String // "06:30"
    public var label: String
    public var isEnabled: Bool
    public var repeatDays: Set<Weekday>
    public var sound: AlarmSound
    public var volume: Double // 0.0 ... 1.0
    public var snoozeEnabled: Bool
    public var snoozeDurationMinutes: Int // Default 9 (Apple HIG standard)
    public var missionType: MissionType
    public var difficulty: MissionDifficulty
    public var problemCount: Int
    public var category: AlarmCategory
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        timeString: String,
        label: String,
        isEnabled: Bool = true,
        repeatDays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday],
        sound: AlarmSound = .radar,
        volume: Double = 0.85,
        snoozeEnabled: Bool = true,
        snoozeDurationMinutes: Int = 9,
        missionType: MissionType = .math,
        difficulty: MissionDifficulty = .medium,
        problemCount: Int = 3,
        category: AlarmCategory = .wakeUp,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.timeString = timeString
        self.label = label
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays
        self.sound = sound
        self.volume = volume
        self.snoozeEnabled = snoozeEnabled
        self.snoozeDurationMinutes = snoozeDurationMinutes
        self.missionType = missionType
        self.difficulty = difficulty
        self.problemCount = max(1, problemCount)
        self.category = category
        self.createdAt = createdAt
    }

    public var formattedRepeatDays: String {
        if repeatDays.isEmpty { return "Una sola vez" }
        if repeatDays.count == 7 { return "Todos los días" }
        if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Días laborales" }
        if repeatDays == [.saturday, .sunday] { return "Fines de semana" }
        return repeatDays.sorted().map { $0.mediumName }.joined(separator: ", ")
    }

    public var isPM: Bool {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard let hour = parts.first else { return false }
        return hour >= 12
    }

    public func toCoreAlarm() -> AlarmaCore.Alarm {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        let hour = parts.first ?? 7
        let minute = parts.count > 1 ? parts[1] : 0
        var coreWeekdays: WeekdaySet = .none
        for day in repeatDays {
            if let bit = WeekdaySet(calendarWeekday: day.rawValue) {
                coreWeekdays.insert(bit)
            }
        }
        return AlarmaCore.Alarm(
            id: id,
            title: label,
            time: AlarmTime(clampingHour: hour, minute: minute),
            repeatDays: coreWeekdays,
            isEnabled: isEnabled,
            sound: sound.coreSoundAsset,
            volume: Float(volume),
            allowsSnooze: snoozeEnabled,
            snoozeDurationMinutes: snoozeDurationMinutes,
            challengeConfig: ChallengeConfiguration(
                type: missionType.coreChallengeType,
                difficulty: difficulty.coreDifficulty,
                problemCount: problemCount
            ),
            createdAt: createdAt
        )
    }
}
