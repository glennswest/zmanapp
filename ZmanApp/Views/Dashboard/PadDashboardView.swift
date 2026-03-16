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
                // Room and garage modes use the same dashboard
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

    private var dashboardDetail: some View {
        ScrollView {
            VStack(spacing: 16) {
                connectionHeader

                LazyVGrid(columns: AppTheme.padColumns, spacing: 16) {
                    ForEach(appState.currentDashboardWidgets) { widget in
                        DashboardWidgetView(widget: widget)
                    }
                }
            }
            .padding()
        }
        .background(AppTheme.dashBackground)
        .navigationTitle(appState.dashboardName(appState.selectedDashboard))
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
