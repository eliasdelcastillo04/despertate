import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public struct HapticManager {
    public static func triggerImpact(_ style: ImpactStyle = .medium) {
        #if os(iOS)
        switch style {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        case .rigid:
            let generator = UIImpactFeedbackGenerator(style: .rigid)
            generator.prepare()
            generator.impactOccurred()
        }
        #endif
    }

    public static func triggerNotification(_ type: NotificationType) {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        switch type {
        case .success:
            generator.notificationOccurred(.success)
        case .warning:
            generator.notificationOccurred(.warning)
        case .error:
            generator.notificationOccurred(.error)
        }
        #endif
    }

    public enum ImpactStyle {
        case light, medium, heavy, rigid
    }

    public enum NotificationType {
        case success, warning, error
    }
}
