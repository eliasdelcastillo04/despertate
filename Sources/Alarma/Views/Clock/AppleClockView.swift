import SwiftUI

public struct AppleClockView: View {
    @State private var currentTime = Date()
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Analog Clock Card
                    VStack(spacing: 16) {
                        Text("HORA ACTUAL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)
                            .tracking(0.6)

                        ClockFaceView(date: currentTime)
                            .frame(width: 200, height: 200)

                        VStack(spacing: 2) {
                            Text(timeFormatted(currentTime))
                                .font(.system(size: 38, weight: .light, design: .monospaced))

                            Text(dateFormatted(currentTime))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .background {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                    }

                    // Stopwatch Section
                    StopwatchView()
                }
                .padding(16)
            }
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #endif
            .navigationTitle("Reloj")
            .onReceive(timer) { input in
                currentTime = input
            }
        }
    }

    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }

    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        return formatter.string(from: date).capitalized
    }
}

struct ClockFaceView: View {
    let date: Date

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2

            ZStack {
                // Circle border
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)

                // 12 Hour Ticks
                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(i % 3 == 0 ? Color.primary : Color.secondary.opacity(0.4))
                        .frame(width: i % 3 == 0 ? 3 : 1.5, height: i % 3 == 0 ? 12 : 7)
                        .offset(y: -radius + 10)
                        .rotationEffect(.degrees(Double(i) * 30))
                }

                // Hour Hand
                Hand(length: radius * 0.52, width: 4.5, color: .primary)
                    .rotationEffect(hourAngle)

                // Minute Hand
                Hand(length: radius * 0.74, width: 3, color: .primary)
                    .rotationEffect(minuteAngle)

                // Second Hand (Apple Orange)
                Hand(length: radius * 0.85, width: 1.5, color: .orange)
                    .rotationEffect(secondAngle)

                // Center Pin
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
            }
            .position(center)
        }
    }

    private var secondAngle: Angle {
        let calendar = Calendar.current
        let sec = Double(calendar.component(.second, from: date))
        return .degrees(sec * 6)
    }

    private var minuteAngle: Angle {
        let calendar = Calendar.current
        let min = Double(calendar.component(.minute, from: date))
        let sec = Double(calendar.component(.second, from: date))
        return .degrees((min + sec / 60) * 6)
    }

    private var hourAngle: Angle {
        let calendar = Calendar.current
        let hour = Double(calendar.component(.hour, from: date) % 12)
        let min = Double(calendar.component(.minute, from: date))
        return .degrees((hour + min / 60) * 30)
    }
}

struct Hand: View {
    let length: CGFloat
    let width: CGFloat
    let color: Color

    var body: some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
    }
}
