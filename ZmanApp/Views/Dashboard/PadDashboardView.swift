import SwiftUI

struct PadDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedArea: Area?
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    private var displayMode: PersistenceService.DisplayMode {
        appState.persistence.displayMode
    }

    var body: some View {
        Group {
            switch displayMode {
            case .general:
                generalMode
            case .room:
                roomMode
            case .garage:
                garageMode
            }
        }
    }

    // MARK: - General Mode (Living Room iPad — full navigation)

    private var generalMode: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            if let selectedArea {
                areaDetail(selectedArea)
            } else {
                generalDashboard
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    private var sidebar: some View {
        List(selection: $selectedArea) {
            if appState.buildings.count > 1 {
                Section("Building") {
                    buildingPicker
                }
            }

            if !appState.garageAreas.isEmpty {
                Section("Garage") {
                    ForEach(appState.garageAreas) { area in
                        Label(area.name, systemImage: area.icon)
                            .tag(area)
                    }
                }
            }

            if !appState.roomAreas.isEmpty {
                Section("Rooms") {
                    ForEach(appState.roomAreas) { area in
                        Label(area.name, systemImage: area.icon)
                            .tag(area)
                    }
                }
            }

            if !appState.generalAreas.isEmpty {
                Section("General") {
                    ForEach(appState.generalAreas) { area in
                        Label(area.name, systemImage: area.icon)
                            .tag(area)
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

    @ViewBuilder
    private func areaDetail(_ area: Area) -> some View {
        switch area.mode {
        case .garage:
            GarageView(area: area)
        case .room, .general:
            RoomView(area: area)
        }
    }

    private var generalDashboard: some View {
        ScrollView {
            VStack(spacing: AppTheme.sectionSpacing) {
                connectionHeader

                // Quick garage controls at the top
                if !appState.garageAreas.isEmpty {
                    garageOverview
                }

                // All areas grid
                allAreasGrid
            }
            .padding(AppTheme.spacing)
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle("Dashboard")
    }

    // MARK: - Room Mode (Fixed iPad in a specific room)

    private var roomMode: some View {
        Group {
            if let areaId = appState.persistence.assignedAreaId,
               let area = appState.currentAreas.first(where: { $0.id == areaId }) {
                NavigationStack {
                    RoomView(area: area)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                }
                            }
                        }
                }
            } else {
                assignAreaPrompt
            }
        }
    }

    // MARK: - Garage Mode (Fixed iPad in the garage)

    private var garageMode: some View {
        Group {
            if let area = appState.garageAreas.first {
                NavigationStack {
                    GarageView(area: area)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                NavigationLink {
                                    SettingsView()
                                } label: {
                                    Image(systemName: "gearshape.fill")
                                }
                            }
                        }
                }
            } else {
                ContentUnavailableView(
                    "No Garage",
                    systemImage: "car.fill",
                    description: Text("No garage area is configured for this building.")
                )
            }
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
                .foregroundStyle(.secondary)
            Spacer()
            Text(appState.selectedBuilding?.name ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var garageOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Garage", icon: "car.fill")

            LazyVGrid(columns: AppTheme.padColumns, spacing: 16) {
                ForEach(appState.garageAreas) { area in
                    ForEach(area.widgets.filter { $0.category == .garageDoor }) { door in
                        GarageDoorCard(door: door) {
                            Task { await appState.toggleWidget(door) }
                        }
                    }
                }
            }
        }
    }

    private var allAreasGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "All Areas", icon: "square.grid.2x2.fill")

            LazyVGrid(columns: AppTheme.padColumns, spacing: 16) {
                ForEach(appState.currentAreas) { area in
                    Button {
                        selectedArea = area
                    } label: {
                        AreaCard(area: area)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var buildingPicker: some View {
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

    private var assignAreaPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Assign This iPad to a Room")
                .font(.title2)
                .fontWeight(.bold)

            Text("Go to Settings to assign this iPad to a specific room.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink {
                SettingsView()
            } label: {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.accent)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}

// MARK: - Garage Door Card (iPad)

struct GarageDoorCard: View {
    let door: DeviceWidget
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: doorIcon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(doorColor)
                    .frame(width: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(door.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    StatusBadge(state: door.state)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    private var doorIcon: String {
        switch door.state {
        case .open, .opening: "door.garage.open"
        case .closed, .closing: "door.garage.closed"
        default: "door.garage.closed"
        }
    }

    private var doorColor: Color {
        switch door.state {
        case .open: .orange
        case .opening, .closing: .yellow
        case .closed: .green
        default: .gray
        }
    }
}
