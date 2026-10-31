import SwiftUI

public struct AlarmListView: View {
    @Bindable public var viewModel: AlarmViewModel
    @State private var editingAlarm: Alarm?
    @State private var isShowingNewSheet: Bool = false

    public init(viewModel: AlarmViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // Hero Next Alarm Countdown
                    if let next = viewModel.nextActiveAlarm {
                        nextAlarmBanner(next)
                    }

                    // Alarms List Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Todas las Alarmas (\(viewModel.alarms.count))")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 4)

                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.alarms) { alarm in
                                AlarmRowView(
                                    alarm: alarm,
                                    isSelected: viewModel.selectedAlarm?.id == alarm.id,
                                    onToggle: {
                                        viewModel.toggleAlarm(alarm)
                                    },
                                    onTestSound: {
                                        viewModel.previewSound(alarm.sound, volume: alarm.volume)
                                    },
                                    onTriggerChallenge: {
                                        viewModel.triggerAlarm(alarm)
                                    },
                                    onSelect: {
                                        editingAlarm = alarm
                                    }
                                )
                                .contextMenu {
                                    Button {
                                        viewModel.triggerAlarm(alarm)
                                    } label: {
                                        Label("Probar Alarma y Reto", systemImage: "bolt.fill")
                                    }

                                    Button {
                                        editingAlarm = alarm
                                    } label: {
                                        Label("Editar", systemImage: "pencil")
                                    }

                                    Button {
                                        viewModel.duplicateAlarm(alarm)
                                    } label: {
                                        Label("Duplicar", systemImage: "doc.on.doc")
                                    }

                                    Button(role: .destructive) {
                                        viewModel.deleteAlarm(alarm)
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #else
            .background(Color.secondary.opacity(0.06))
            #endif
            .navigationTitle("Alarmas")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Menu {
                        ForEach(AppTheme.allCases) { theme in
                            Button {
                                viewModel.selectedTheme = theme
                            } label: {
                                HStack {
                                    Label(theme.rawValue, systemImage: theme.iconName)
                                    if viewModel.selectedTheme == theme {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.selectedTheme.iconName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(viewModel.selectedTheme == .dark ? Color.orange : Color.blue)
                            Text(viewModel.selectedTheme.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .accessibilityLabel("Seleccionar tema de la app")
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingNewSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.orange)
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        viewModel.isShowingChatSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("IA")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.purple)
                    }
                }
            }
            .sheet(isPresented: $isShowingNewSheet) {
                AlarmEditSheet { newAlarm in
                    viewModel.saveAlarm(newAlarm)
                }
            }
            .sheet(item: $editingAlarm) { alarm in
                AlarmEditSheet(alarmToEdit: alarm) { updated in
                    viewModel.saveAlarm(updated)
                }
            }
        }
    }

    private func nextAlarmBanner(_ alarm: Alarm) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.orange)
                .padding(10)
                .background(Color.orange.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("PRÓXIMA ALARMA")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.orange)
                    .tracking(0.6)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(alarm.timeString)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                    Text("\"\(alarm.label)\"")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                viewModel.triggerAlarm(alarm)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                    Text("Probar")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.14))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        }
    }
}
