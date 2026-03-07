import SwiftUI

struct GarageView: View {
    let area: Area
    @Environment(AppState.self) private var appState
    @State private var viewModel: GarageViewModel?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: AppTheme.sectionSpacing) {
                    // Garage Doors — prominent
                    if !vm.garageDoors.isEmpty {
                        garageDoorSection(vm)
                    }

                    // Cameras
                    if !vm.cameras.isEmpty {
                        cameraSection(vm)
                    }

                    // Lights
                    if !vm.lights.isEmpty {
                        lightSection(vm)
                    }

                    // Sensors
                    if !vm.sensors.isEmpty {
                        sensorSection(vm)
                    }

                    // Other widgets
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

    // MARK: - Garage Door Section

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

    // MARK: - Camera Section

    private func cameraSection(_ vm: GarageViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Cameras", icon: "video.fill")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(vm.cameras) { camera in
                    VStack(spacing: 8) {
                        // Camera feed placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black)
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "video.fill")
                                        .font(.title)
                                        .foregroundStyle(.white.opacity(0.5))
                                    Text(camera.name)
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }

                        StatusBadge(state: camera.state, compact: true)
                    }
                    .cardStyle()
                }
            }
        }
    }

    // MARK: - Lights

    private func lightSection(_ vm: GarageViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Lights", icon: "lightbulb.fill")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(vm.lights) { light in
                    WidgetCard(widget: light) {
                        Task { await vm.toggleLight(light) }
                    }
                }
            }
        }
    }

    // MARK: - Sensors

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

    // MARK: - Other

    private func otherSection(_ vm: GarageViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Other", icon: "ellipsis.circle.fill")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(vm.otherWidgets) { widget in
                    WidgetCard(widget: widget) {
                        if widget.isToggleable {
                            Task { await appState.toggleWidget(widget) }
                        }
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        UIDevice.current.userInterfaceIdiom == .pad ? AppTheme.padColumns : AppTheme.phoneColumns
    }
}
