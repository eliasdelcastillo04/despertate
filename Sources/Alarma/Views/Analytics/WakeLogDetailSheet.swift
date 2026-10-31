import SwiftUI

public struct WakeLogDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    public let log: WakeLog
    public let associatedAlarm: Alarm?
    public let onUpdateStatus: (LogStatus) -> Void
    public let onOpenAlarmEdit: (Alarm) -> Void

    public init(
        log: WakeLog,
        associatedAlarm: Alarm?,
        onUpdateStatus: @escaping (LogStatus) -> Void,
        onOpenAlarmEdit: @escaping (Alarm) -> Void
    ) {
        self.log = log
        self.associatedAlarm = associatedAlarm
        self.onUpdateStatus = onUpdateStatus
        self.onOpenAlarmEdit = onOpenAlarmEdit
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Status Banner
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(log.fullFormattedDate.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text(log.alarmLabel)
                                .font(.system(size: 20, weight: .bold))
                        }
                        Spacer()
                        StatusBadgeView(status: log.status)
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }

                    // Block 1: Target vs Actual Time
                    HStack(spacing: 12) {
                        timeStatCard(
                            title: "PROGRAMADA",
                            time: log.scheduledTime,
                            icon: "clock",
                            tint: .secondary
                        )

                        timeStatCard(
                            title: "HORA REAL",
                            time: log.wakeTime,
                            icon: "sun.max.fill",
                            tint: .orange
                        )
                    }

                    // Block 2: Sleep & Health metrics
                    VStack(spacing: 12) {
                        HStack {
                            Text("Diagnóstico de Despertar")
                                .font(.system(size: 13, weight: .semibold))
                            Spacer()
                        }

                        // Consistency Progress Bar
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Puntuación de Consistencia")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(log.consistencyScore)%")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                            }

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.15))
                                    Capsule()
                                        .fill(consistencyColor(log.consistencyScore))
                                        .frame(width: geo.size.width * CGFloat(log.consistencyScore) / 100.0)
                                }
                            }
                            .frame(height: 8)
                        }

                        Divider()

                        HStack {
                            Label("Horas de Sueño", systemImage: "bed.double.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1f hrs", log.sleepDurationHours))
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        }

                        HStack {
                            Label("Postergaciones (Snooze)", systemImage: "clock.arrow.2.circlepath")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(log.snoozeCount)x (\(log.snoozeCount * 9)m)")
                                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                                .foregroundStyle(log.snoozeCount > 0 ? Color.orange : Color.primary)
                        }

                        HStack {
                            Label("Misión Cumplida", systemImage: "sparkles")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(log.missionCompleted ? "Superada" : "Sin reto")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(log.missionCompleted ? Color.purple : Color.secondary)
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }

                    // Block 3: Notes if available
                    if let notes = log.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("BITÁCORA")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)

                            Text("\"\(notes)\"")
                                .font(.system(size: 13))
                                .italic()
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }

                    // Action Buttons (per building-data-apps)
                    VStack(spacing: 10) {
                        Button {
                            onUpdateStatus(.perfect)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Marcar como Cumplida")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        HStack(spacing: 10) {
                            Button {
                                onUpdateStatus(.snoozed)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "clock.arrow.2.circlepath")
                                    Text("Marcar Snooze")
                                }
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.secondary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }

                            if let alarm = associatedAlarm {
                                Button {
                                    dismiss()
                                    onOpenAlarmEdit(alarm)
                                } label: {
                                    HStack {
                                        Image(systemName: "slider.horizontal.3")
                                        Text("Ajustar Alarma")
                                    }
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color.blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 11)
                                    .background(Color.blue.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #endif
            .navigationTitle("Inspección de Registro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func timeStatCard(title: String, time: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(tint)
            }

            Text(time)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    private func consistencyColor(_ score: Int) -> Color {
        if score >= 90 { return .green }
        if score >= 80 { return .orange }
        return .red
    }
}
