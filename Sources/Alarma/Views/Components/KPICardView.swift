import SwiftUI

public struct KPICardView: View {
    public let title: String
    public let value: String
    public let subtitle: String?
    public let systemImage: String
    public let trendValue: String?
    public let isPositiveTrend: Bool
    public let accentColor: Color

    public init(
        title: String,
        value: String,
        subtitle: String? = nil,
        systemImage: String,
        trendValue: String? = nil,
        isPositiveTrend: Bool = true,
        accentColor: Color = .blue
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.trendValue = trendValue
        self.isPositiveTrend = isPositiveTrend
        self.accentColor = accentColor
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Spacer()

                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(6)
                    .background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)
            }

            // Main Value - Single line with auto-shrink
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Bottom row: Trend badge & subtitle
            HStack(spacing: 6) {
                if let trend = trendValue {
                    HStack(spacing: 3) {
                        Image(systemName: isPositiveTrend ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text(trend)
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .foregroundStyle(isPositiveTrend ? Color.green : Color.red)
                    .background(isPositiveTrend ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                    .clipShape(Capsule())
                }

                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        }
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)\(trendValue != nil ? ", tendencia \(isPositiveTrend ? "positiva" : "negativa") de \(trendValue!)" : "")\(subtitle != nil ? ", \(subtitle!)" : "")")
    }
}
