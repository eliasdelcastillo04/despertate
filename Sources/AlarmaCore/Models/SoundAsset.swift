import Foundation

/// Represents bundled audio tones available for alarm ringing.
public enum SoundAsset: String, Codable, CaseIterable, Sendable, Identifiable {
    case radar = "radar"
    case beacon = "beacon"
    case chimes = "chimes"
    case circuit = "circuit"
    case classicBell = "classic_bell"
    case digital = "digital"
    case gentleRise = "gentle_rise"
    case systemDefault = "system_default"
    case apex = "apex"
    case breeze = "breeze"
    case cosmic = "cosmic"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .radar: return "Radar"
        case .beacon: return "Beacon"
        case .chimes: return "Chimes"
        case .circuit: return "Circuit"
        case .classicBell: return "Classic Bell"
        case .digital: return "Digital Alarm"
        case .gentleRise: return "Gentle Rise"
        case .systemDefault: return "System Default"
        case .apex: return "Apex"
        case .breeze: return "Breeze"
        case .cosmic: return "Cosmic"
        }
    }

    public var fileName: String {
        rawValue
    }

    public var fileExtension: String {
        "caf"
    }

    public var fileNameWithExtension: String {
        "\(rawValue).caf"
    }

    public static let `default`: SoundAsset = .radar
    public static let defaultSound: SoundAsset = .radar
}
