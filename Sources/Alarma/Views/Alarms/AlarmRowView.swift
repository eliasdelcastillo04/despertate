import SwiftUI

public struct AlarmRowView: View {
    public let alarm: Alarm
    public let isSelected: Bool
    public let onToggle: () -> Void
    public let onTestSound: () -> Void
    public let onTriggerChallenge: () -> Void
    public let onSelect: () -> Void

    public init(
        alarm: Alarm,
        isSelected: Bool = false,
        onToggle: @escaping () -> Void,
        onTestSound: @escaping () -> Void,
        onTriggerChallenge: @escaping () -> Void = {},
        onSelect: @escaping () -> Void
    ) {
        self.alarm = alarm
        self.isSelected = isSelected
        self.onToggle = onToggle
        self.onTestSound = onTestSound
        self.onTriggerChallenge = onTriggerChallenge
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    // Weekday indicators (D L M M J V S) like reference design
                    HStack(spacing: 8) {
                        ForEach(Weekday.allCases) { day in
                            let isActive = alarm.repeatDays.contains(day)
                            Text(day.shortName)
                                .font(.system(size: 11, weight: isActive ? .bold : .regular))
                                .foregroundStyle(isActive ? (alarm.isEnabled ? Color.primary : Color.secondary) : Color.secondary.opacity(0.28))
                        }
                    }
                    .padding(.bottom, 2)

                    // Apple Clock massive digital time
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(alarm.timeString)
                            .font(.system(size: 42, weight: alarm.isEnabled ? .light : .thin, design: .default))
                            .foregroundStyle(alarm.isEnabled ? Color.primary : Color.secondary.opacity(0.6))

                        Text(alarm.isPM ? "p.m." : "a.m.")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(alarm.isEnabled ? Color.orange : Color.secondary.opacity(0.6))
                    }

                    // Label & repeat schedule
                    HStack(spacing: 6) {
                        Text(alarm.label)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)

                        Text("•")
                            .foregroundStyle(.secondary)

                        Text(alarm.formattedRepeatDays)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    // Mission & Snooze Badges
                    HStack(spacing: 6) {
                        if alarm.missionType != .none {
                            HStack(spacing: 3) {
                                Image(systemName: alarm.missionType.iconName)
                                    .font(.system(size: 10))
                                Text("\(alarm.missionType.rawValue) (\(alarm.difficulty.rawValue))")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundStyle(Color.purple)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Capsule())
                        }

                        if alarm.snoozeEnabled {
                            HStack(spacing: 2) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 9))
                                Text("\(alarm.snoozeDurationMinutes)m")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .foregroundStyle(.secondary)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(.top, 2)
                }

                Spacer()

                // Actions: Challenge Trigger, Audio Preview & Native iOS Switch
                HStack(spacing: 10) {
                    Button(action: onTriggerChallenge) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.orange)
                            .padding(8)
                            .background(Color.orange.opacity(0.14))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Probar alarma y reto de desactivación")

                    Button(action: onTestSound) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.blue)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Previsualizar tono")

                    Toggle("", isOn: Binding(
                        get: { alarm.isEnabled },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    #if os(iOS)
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color(uiColor: .secondarySystemGroupedBackground))
                    #else
                    .fill(isSelected ? Color.blue.opacity(0.08) : Color.secondary.opacity(0.1))
                    #endif
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? Color.blue.opacity(0.3) : Color.primary.opacity(0.04), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
