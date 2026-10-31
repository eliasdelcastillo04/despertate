import SwiftUI
import Charts

public struct WakeConsistencyChartView: View {
    public let logs: [WakeLog]

    public init(logs: [WakeLog]) {
        self.logs = logs
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Consistencia de Despertar")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Puntuación (%) y regularidad diaria")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()

                HStack(spacing: 12) {
                    Label("Score", systemImage: "circle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.blue)

                    Label("Snooze", systemImage: "moon.zzz.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.orange)
                }
            }

            Chart {
                ForEach(logs.reversed()) { log in
                    // Area under line
                    AreaMark(
                        x: .value("Fecha", log.formattedDate),
                        yStart: .value("Min", 50),
                        yEnd: .value("Score", log.consistencyScore)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line Mark
                    LineMark(
                        x: .value("Fecha", log.formattedDate),
                        y: .value("Score", log.consistencyScore)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    // Point Mark
                    PointMark(
                        x: .value("Fecha", log.formattedDate),
                        y: .value("Score", log.consistencyScore)
                    )
                    .foregroundStyle(log.snoozeCount > 0 ? Color.orange : Color.blue)
                    .symbolSize(log.snoozeCount > 0 ? 55 : 35)
                    .annotation(position: .top, spacing: 6) {
                        if log.snoozeCount > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 7))
                                Text("\(log.snoozeCount)")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .foregroundStyle(Color.orange)
                            .background(Color.orange.opacity(0.18))
                            .clipShape(Capsule())
                        }
                    }
                }

                // Reference RuleMark 90%
                RuleMark(y: .value("Meta", 90))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .foregroundStyle(Color.purple.opacity(0.6))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Meta 90%")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.purple)
                    }
            }
            .chartYScale(domain: 50...108)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [60, 80, 100]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intVal = value.as(Int.self) {
                            Text("\(intVal)%")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .frame(height: 200)
            .clipped()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        }
    }
}
