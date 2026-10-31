import SwiftUI

public struct StatusBadgeView: View {
    public let status: LogStatus

    public init(status: LogStatus) {
        self.status = status
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 9, weight: .bold))
            Text(status.rawValue)
                .font(.system(size: 11, weight: .semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundStyle(tintColor)
        .background(tintColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch status {
        case .perfect: return "checkmark.circle.fill"
        case .snoozed: return "clock.arrow.2.circlepath"
        case .delayed: return "exclamationmark.triangle.fill"
        case .missed: return "xmark.circle.fill"
        }
    }

    private var tintColor: Color {
        switch status {
        case .perfect: return .green
        case .snoozed: return .orange
        case .delayed: return .red
        case .missed: return .secondary
        }
    }
}
