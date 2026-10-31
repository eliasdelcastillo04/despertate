import SwiftUI

public struct MainTabView: View {
    @State private var viewModel = AlarmViewModel()
    @State private var selectedTab: TabItem = .alarms

    public enum TabItem: Hashable {
        case alarms
        case metrics
        case clock
    }

    public init() {}

    public var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                AlarmListView(viewModel: viewModel)
                    .tabItem {
                        Label("Alarmas", systemImage: "alarm.fill")
                    }
                    .tag(TabItem.alarms)

                AnalyticsDashboardView(viewModel: viewModel)
                    .tabItem {
                        Label("Métricas", systemImage: "chart.bar.xaxis")
                    }
                    .tag(TabItem.metrics)

                AppleClockView()
                    .tabItem {
                        Label("Reloj", systemImage: "stopwatch.fill")
                    }
                    .tag(TabItem.clock)
            }
            .tint(.orange)
            .sheet(isPresented: $viewModel.isShowingChatSheet) {
                DataChatSheet(viewModel: viewModel)
            }

            if let activeAlarm = viewModel.activeRingingAlarm {
                AlarmRingingOverlayView(alarm: activeAlarm, viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(999)
            }
        }
        .preferredColorScheme(viewModel.colorScheme)
    }
}
