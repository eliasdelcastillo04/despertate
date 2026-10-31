import SwiftUI
import Charts

public struct SleepDurationChartView: View {
    public let logs: [WakeLog]

    public init(logs: [WakeLog]) {
        self.logs = logs
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Horas de Sueño Semanales")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Comparativa vs meta recomendada (8.0h)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Chart {
                ForEach(logs.suffix(7).reversed()) { log in
                    BarMark(
                        x: .value("Fecha", log.formattedDate),
                        yStart: .value("Base", 4.0),
                        yEnd: .value("Horas", log.sleepDurationHours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }

                // Optimal 8h Rule Mark
                RuleMark(y: .value("Meta 8h", 8.0))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .foregroundStyle(Color.purple)
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Meta 8h")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.purple)
                    }
            }
            .chartYScale(domain: 4...10)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.system(size: 10))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [5, 7, 8, 10]) { val in
                    AxisGridLine()
                    AxisValueLabel {
                        if let dbl = val.as(Double.self) {
                            Text("\(Int(dbl))h")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .frame(height: 180)
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
