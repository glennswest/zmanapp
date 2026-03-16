import SwiftUI

struct PadDashboardView: View {
    @Environment(AppState.self) private var appState

    private var displayMode: PersistenceService.DisplayMode {
        appState.persistence.displayMode
    }

    var body: some View {
        Group {
            switch displayMode {
            case .general:
                generalMode
            case .room, .garage:
                generalMode
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - General Mode

    private var generalMode: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            dashboardDetail
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List {
            if appState.buildings.count > 1 {
                Section("Building") {
                    ForEach(appState.buildings) { building in
                        Button {
                            appState.selectBuilding(building)
                        } label: {
                            HStack {
                                Text(building.name)
                                if building.id == appState.selectedBuilding?.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            Section("Dashboards") {
                ForEach(appState.dashboardIds, id: \.self) { dashId in
                    Button {
                        appState.selectedDashboard = dashId
                    } label: {
                        HStack {
                            Text(appState.dashboardName(dashId))
                            Spacer()
                            if appState.selectedDashboard == dashId {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }

            Section {
                NavigationLink {
                    SettingsView()
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
        .navigationTitle(appState.selectedBuilding?.name ?? "Zman")
        .refreshable {
            await appState.refreshCurrentBuilding()
        }
    }

    // MARK: - Widget Groups

    private var regularWidgets: [DeviceWidget] {
        appState.currentDashboardWidgets.filter {
            $0.widgetType != .thermostat && $0.widgetType != .weather
        }
    }

    private var thermostatWidgets: [DeviceWidget] {
        appState.currentDashboardWidgets.filter { $0.widgetType == .thermostat }
    }

    private var weatherLocations: [WeatherLocation] {
        let wx = appState.currentDashboardWidgets.filter { $0.widgetType == .weather }
        let grouped = Dictionary(grouping: wx) { $0.deviceId }
        return grouped.map { deviceId, widgets in
            let name = deviceId
                .replacingOccurrences(of: "virtual.weather.", with: "")
                .capitalized
            return WeatherLocation(
                locationId: deviceId,
                name: name,
                current: widgets.first { ($0.widgetProperty ?? "").isEmpty },
                today: widgets.first { $0.widgetProperty == "today" },
                tomorrow: widgets.first { $0.widgetProperty == "tomorrow" }
            )
        }.sorted { $0.name < $1.name }
    }

    private var dashboardDetail: some View {
        ScrollView {
            VStack(spacing: 16) {
                connectionHeader

                if !regularWidgets.isEmpty {
                    LazyVGrid(columns: AppTheme.padColumns, spacing: 16) {
                        ForEach(regularWidgets) { widget in
                            padWidgetView(widget)
                        }
                    }
                }

                ForEach(thermostatWidgets) { widget in
                    ThermostatCard(widget: widget)
                }

                ForEach(weatherLocations, id: \.locationId) { loc in
                    WeatherLocationCard(location: loc)
                }
            }
            .padding()
        }
        .background(AppTheme.dashBackground)
        .navigationTitle(appState.dashboardName(appState.selectedDashboard))
    }

    @ViewBuilder
    private func padWidgetView(_ widget: DeviceWidget) -> some View {
        switch widget.widgetType {
        case .garage:
            GarageDoorWidget(widget: widget) {
                Task { await appState.toggleWidget(widget) }
            }
        case .sensor:
            SensorWidget(widget: widget)
        default:
            GenericWidget(widget: widget)
        }
    }

    // MARK: - Shared Components

    private var connectionHeader: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.api.isConnected ? AppTheme.onlineGreen : AppTheme.errorRed)
                .frame(width: 10, height: 10)
            Text(appState.api.isConnected ? "Connected" : "Offline")
                .font(.subheadline)
                .foregroundStyle(AppTheme.dashSecondary)

            if appState.syncService.isSyncing {
                ProgressView()
                    .scaleEffect(0.6)
            } else if let lastSync = appState.syncService.lastSyncDate {
                Text("Synced \(lastSync.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.dashSecondary.opacity(0.7))
            }

            Spacer()
        }
    }
}
