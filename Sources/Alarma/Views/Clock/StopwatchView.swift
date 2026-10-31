import SwiftUI

public struct StopwatchView: View {
    @State private var elapsedTimeTenths: Int = 0
    @State private var isRunning: Bool = false
    @State private var laps: [Int] = []
    @State private var timer: Timer?

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("CRONÓMETRO")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.6)
                Spacer()
            }

            // Big Digital Display
            Text(formattedTime(elapsedTimeTenths))
                .font(.system(size: 46, weight: .thin, design: .monospaced))
                .padding(.vertical, 8)

            // Buttons
            HStack(spacing: 36) {
                // Lap or Reset button
                Button {
                    if isRunning {
                        recordLap()
                    } else {
                        resetStopwatch()
                    }
                } label: {
                    Text(isRunning ? "Vuelta" : "Reiniciar")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.primary)
                        .frame(width: 72, height: 72)
                        .background(Color.secondary.opacity(0.18))
                        .clipShape(Circle())
                }
                .disabled(elapsedTimeTenths == 0)

                // Start or Stop button
                Button {
                    if isRunning {
                        stop()
                    } else {
                        start()
                    }
                } label: {
                    Text(isRunning ? "Detener" : "Iniciar")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isRunning ? Color.red : Color.green)
                        .frame(width: 72, height: 72)
                        .background((isRunning ? Color.red : Color.green).opacity(0.18))
                        .clipShape(Circle())
                }
            }

            // Laps List
            if !laps.isEmpty {
                Divider()
                    .padding(.top, 8)

                VStack(spacing: 8) {
                    ForEach(Array(laps.enumerated().reversed()), id: \.offset) { index, lapTime in
                        HStack {
                            Text("Vuelta \(index + 1)")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(formattedTime(lapTime))
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .frame(maxHeight: 160)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        }
    }

    private func start() {
        isRunning = true
        HapticManager.triggerImpact(.medium)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                elapsedTimeTenths += 1
            }
        }
    }

    private func stop() {
        isRunning = false
        HapticManager.triggerImpact(.medium)
        timer?.invalidate()
        timer = nil
    }

    private func resetStopwatch() {
        elapsedTimeTenths = 0
        laps = []
        HapticManager.triggerImpact(.light)
    }

    private func recordLap() {
        laps.append(elapsedTimeTenths)
        HapticManager.triggerImpact(.light)
    }

    private func formattedTime(_ tenths: Int) -> String {
        let mins = tenths / 600
        let secs = (tenths % 600) / 10
        let ms = tenths % 10
        return String(format: "%02d:%02d.%d", mins, secs, ms)
    }
}
