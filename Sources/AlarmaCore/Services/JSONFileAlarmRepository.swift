import Foundation

/// Actor-isolated, thread-safe local JSON persistence repository with atomic writes and self-healing corruption recovery.
public actor JSONFileAlarmRepository: AlarmRepositoryProtocol {
    public let fileURL: URL
    private let fileManager: FileManager
    private let defaultStarterAlarms: [Alarm]
    private let jsonEncoder: JSONEncoder
    private let jsonDecoder: JSONDecoder
    private var cachedAlarms: [Alarm]?

    public enum RepositoryError: Error, LocalizedError, Equatable {
        case directoryCreationFailed(String)
        case atomicWriteFailed(String)
        case corruptedDataHandled(String)

        public var errorDescription: String? {
            switch self {
            case .directoryCreationFailed(let msg): return "Failed to create directory: \(msg)"
            case .atomicWriteFailed(let msg): return "Atomic write failed: \(msg)"
            case .corruptedDataHandled(let msg): return "Corrupted data handled: \(msg)"
            }
        }
    }

    public init(
        fileURL: URL = JSONFileAlarmRepository.defaultFileURL,
        fileManager: FileManager = .default,
        defaultStarterAlarms: [Alarm] = []
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.defaultStarterAlarms = defaultStarterAlarms

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.jsonDecoder = decoder
    }

    public static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDir = appSupport.appendingPathComponent("Alarma", isDirectory: true)
        return appDir.appendingPathComponent("alarms.json")
    }

    public func loadAlarms() async throws -> [Alarm] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            if !defaultStarterAlarms.isEmpty {
                try await saveAlarms(defaultStarterAlarms)
                return defaultStarterAlarms
            }
            cachedAlarms = []
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            if !defaultStarterAlarms.isEmpty {
                try await saveAlarms(defaultStarterAlarms)
                return defaultStarterAlarms
            }
            cachedAlarms = []
            return []
        }

        if data.isEmpty {
            if !defaultStarterAlarms.isEmpty {
                try await saveAlarms(defaultStarterAlarms)
                return defaultStarterAlarms
            }
            cachedAlarms = []
            return []
        }

        do {
            let alarms = try jsonDecoder.decode([Alarm].self, from: data)
            cachedAlarms = alarms
            return alarms
        } catch {
            // Self-healing / corruption recovery:
            // 1. Preserve corrupted content in a timestamped audit backup
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let corruptedBackupURL = fileURL.deletingPathExtension()
                .appendingPathExtension("corrupted.\(timestamp).json")

            try? fileManager.copyItem(at: fileURL, to: corruptedBackupURL)

            // 2. Overwrite corrupt file with valid fallback data
            let fallbackAlarms = defaultStarterAlarms
            let recoveryData = try jsonEncoder.encode(fallbackAlarms)
            try writeAtomic(data: recoveryData, to: fileURL)

            cachedAlarms = fallbackAlarms
            return fallbackAlarms
        }
    }

    public func saveAlarms(_ alarms: [Alarm]) async throws {
        let directoryURL = fileURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                throw RepositoryError.directoryCreationFailed(error.localizedDescription)
            }
        }

        let data = try jsonEncoder.encode(alarms)
        try writeAtomic(data: data, to: fileURL)
        cachedAlarms = alarms
    }

    public func upsertAlarm(_ alarm: Alarm) async throws {
        var current = try await loadAlarms()
        if let index = current.firstIndex(where: { $0.id == alarm.id }) {
            current[index] = alarm
        } else {
            current.append(alarm)
        }
        try await saveAlarms(current)
    }

    public func deleteAlarm(id: UUID) async throws {
        var current = try await loadAlarms()
        current.removeAll { $0.id == id }
        try await saveAlarms(current)
    }

    private func writeAtomic(data: Data, to destinationURL: URL) throws {
        do {
            #if os(iOS)
            try data.write(to: destinationURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            #else
            try data.write(to: destinationURL, options: .atomic)
            #endif
        } catch {
            throw RepositoryError.atomicWriteFailed(error.localizedDescription)
        }
    }
}
