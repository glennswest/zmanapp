import SwiftUI

struct PhoneDashboardView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    connectionStatus

                    if !appState.garageAreas.isEmpty {
                        garageQuickActions
                    }

                    if let building = appState.selectedBuilding {
                        areaGrid(areas: building.areas)
                    }
                }
                .padding()
            }
            .background(AppTheme.groupedBackground)
            .navigationTitle(appState.selectedBuilding?.name ?? "Zman")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    buildingPicker
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .refreshable {
                await appState.refreshCurrentBuilding()
            }
        }
    }

    // MARK: - Connection Status

    private var connectionStatus: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(appState.api.isConnected ? AppTheme.onlineGreen : AppTheme.errorRed)
                .frame(width: 8, height: 8)
            Text(appState.api.isConnected ? "Connected" : "Offline")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Garage Quick Actions

    private var garageQuickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Garage", icon: "car.fill")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(appState.garageAreas) { area in
                        ForEach(area.widgets.filter { $0.category == .garageDoor }) { door in
                            QuickActionButton(
                                title: door.name,
                                icon: doorIcon(for: door.state),
                                color: doorColor(for: door.state),
                                isActive: door.state == .open || door.state == .opening
                            ) {
                                Task { await appState.toggleWidget(door) }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Area Grid

    private func areaGrid(areas: [Area]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Areas", icon: "square.grid.2x2.fill")

            LazyVGrid(columns: AppTheme.phoneColumns, spacing: 12) {
                ForEach(areas.sorted(by: { $0.sortOrder < $1.sortOrder })) { area in
                    NavigationLink {
                        areaDestination(area)
                    } label: {
                        AreaCard(area: area)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func areaDestination(_ area: Area) -> some View {
        switch area.mode {
        case .garage:
            GarageView(area: area)
        case .room, .general:
            RoomView(area: area)
        }
    }

    // MARK: - Building Picker

    private var buildingPicker: some View {
        Menu {
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
        } label: {
            Image(systemName: "building.2.fill")
        }
    }

    // MARK: - Helpers

    private func doorIcon(for state: WidgetState) -> String {
        switch state {
        case .open, .opening: "door.garage.open"
        case .closed, .closing: "door.garage.closed"
        default: "door.garage.closed"
        }
    }

    private func doorColor(for state: WidgetState) -> Color {
        switch state {
        case .open: .orange
        case .opening, .closing: .yellow
        case .closed: .green
        default: .gray
        }
    }
}

// MARK: - Area Card

struct AreaCard: View {
    let area: Area

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: area.icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                Spacer()
                Text("\(area.widgets.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppTheme.offGray.opacity(0.3))
                    .clipShape(Capsule())
            }

            Text(area.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Text(area.mode.rawValue.capitalized)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}
