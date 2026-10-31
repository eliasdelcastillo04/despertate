import SwiftUI

public struct AnalyticsDashboardView: View {
    @Bindable public var viewModel: AlarmViewModel
    @State private var selectedLogForDetail: WakeLog?
    @State private var editingAlarmForDetail: Alarm?

    public init(viewModel: AlarmViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // KPI Cards Row (Per building-data-apps)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        KPICardView(
                            title: "Alarmas Activas",
                            value: "\(viewModel.metrics.activeAlarms) / \(viewModel.metrics.totalAlarms)",
                            subtitle: "\(viewModel.alarms.filter { $0.missionType != .none }.count) con misiones",
                            systemImage: "bell.fill",
                            trendValue: "+1 hoy",
                            isPositiveTrend: true,
                            accentColor: .orange
                        )

                        KPICardView(
                            title: "Hora Promedio",
                            value: viewModel.metrics.averageWakeTimeString,
                            subtitle: "Meta recomendada",
                            systemImage: "clock.fill",
                            trendValue: "-12 min",
                            isPositiveTrend: true,
                            accentColor: .blue
                        )

                        KPICardView(
                            title: "Tasa de Snooze",
                            value: "\(viewModel.metrics.snoozeRatePercentage)%",
                            subtitle: "Objetivo: < 10%",
                            systemImage: "chart.line.downtrend.xyaxis",
                            trendValue: "-4.2%",
                            isPositiveTrend: true,
                            accentColor: .green
                        )

                        KPICardView(
                            title: "Consistencia",
                            value: "\(viewModel.metrics.consistencyScoreAverage)/100",
                            subtitle: "Nivel Óptimo",
                            systemImage: "sparkles",
                            trendValue: "+\(String(format: "%.1f", viewModel.metrics.weeklyTrendPercentage))%",
                            isPositiveTrend: true,
                            accentColor: .purple
                        )
                    }

                    // Native Apple Charts
                    VStack(spacing: 16) {
                        WakeConsistencyChartView(logs: viewModel.logs)
                        SleepDurationChartView(logs: viewModel.logs)
                    }

                    // Table & Filter Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Bitácora & Registros de Despertar")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                        }

                        // Search and filter controls
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Buscar en registros...", text: $viewModel.searchQuery)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13))

                                if !viewModel.searchQuery.isEmpty {
                                    Button {
                                        viewModel.searchQuery = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            // Filter Pills
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    filterPill(title: "Todos", isSelected: viewModel.statusFilter == nil) {
                                        viewModel.statusFilter = nil
                                    }

                                    ForEach(LogStatus.allCases) { status in
                                        filterPill(title: status.rawValue, isSelected: viewModel.statusFilter == status) {
                                            viewModel.statusFilter = status
                                        }
                                    }
                                }
                            }
                        }

                        // Log Rows
                        LazyVStack(spacing: 8) {
                            if viewModel.filteredLogs.isEmpty {
                                Text("No hay registros que coincidan con la búsqueda.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 24)
                            } else {
                                ForEach(viewModel.filteredLogs) { log in
                                    Button {
                                        selectedLogForDetail = log
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack(spacing: 6) {
                                                    Text(log.formattedDate)
                                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                        .foregroundStyle(.secondary)

                                                    Text("•")
                                                        .foregroundStyle(.secondary)

                                                    Text(log.alarmLabel)
                                                        .font(.system(size: 13, weight: .semibold))
                                                        .lineLimit(1)
                                                }

                                                HStack(spacing: 6) {
                                                    Text("\(log.scheduledTime) → \(log.wakeTime)")
                                                        .font(.system(size: 12, design: .monospaced))
                                                        .foregroundStyle(.secondary)

                                                    if log.snoozeCount > 0 {
                                                        Text("(\(log.snoozeCount)x snooze)")
                                                            .font(.system(size: 10, weight: .semibold))
                                                            .foregroundStyle(.orange)
                                                    }
                                                }
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing, spacing: 4) {
                                                StatusBadgeView(status: log.status)

                                                Text("\(log.consistencyScore)%")
                                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                    .foregroundStyle(.secondary)
                                            }

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundStyle(.tertiary)
                                                .padding(.leading, 4)
                                        }
                                        .padding(12)
                                        .background {
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(.ultraThinMaterial)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                                                )
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #endif
            .navigationTitle("Métricas & Sueño")
            .sheet(item: $selectedLogForDetail) { log in
                WakeLogDetailSheet(
                    log: log,
                    associatedAlarm: viewModel.alarms.first { $0.id == log.alarmId },
                    onUpdateStatus: { newStatus in
                        viewModel.updateLogStatus(logId: log.id, newStatus: newStatus)
                    },
                    onOpenAlarmEdit: { alarm in
                        editingAlarmForDetail = alarm
                    }
                )
            }
            .sheet(item: $editingAlarmForDetail) { alarm in
                AlarmEditSheet(alarmToEdit: alarm) { updated in
                    viewModel.saveAlarm(updated)
                }
            }
        }
    }

    private func filterPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
