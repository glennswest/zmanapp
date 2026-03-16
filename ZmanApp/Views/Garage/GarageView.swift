import SwiftUI

struct GarageView: View {
    let area: Area
    @Environment(AppState.self) private var appState
    @State private var viewModel: GarageViewModel?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: AppTheme.sectionSpacing) {
                    if !vm.garageDoors.isEmpty {
                        garageDoorSection(vm)
                    }

                    if !vm.sensors.isEmpty {
                        sensorSection(vm)
                    }

                    if !vm.otherWidgets.isEmpty {
                        otherSection(vm)
                    }
                }
                .padding()
            }
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle(area.name)
        .onAppear {
            if viewModel == nil {
                viewModel = GarageViewModel(area: area, appState: appState)
            }
        }
        .refreshable {
            await appState.refreshCurrentBuilding()
            if let updated = appState.currentAreas.first(where: { $0.id == area.id }) {
                viewModel?.area = updated
            }
        }
    }

    private func garageDoorSection(_ vm: GarageViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Doors", icon: "door.garage.closed")

            ForEach(vm.garageDoors) { door in
                GarageDoorControl(door: door, isOperating: vm.isOperating) {
                    Task { await vm.toggleDoor(door) }
                }
            }

            if let message = vm.statusMessage {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
    }

    private func sensorSection(_ vm: GarageViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sensors", icon: "sensor.fill")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(vm.sensors) { sensor in
                    WidgetCard(widget: sensor)
                }
            }
        }
    }

    private func otherSection(_ vm: GarageViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Other", icon: "ellipsis.circle.fill")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(vm.otherWidgets) { widget in
                    WidgetCard(widget: widget) {
                        Task { await appState.toggleWidget(widget) }
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        PlatformService.isWideDevice ? AppTheme.padColumns : AppTheme.phoneColumns
    }
}
