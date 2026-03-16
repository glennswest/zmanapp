import SwiftUI

struct RoomView: View {
    let area: Area
    @Environment(AppState.self) private var appState
    @State private var viewModel: RoomViewModel?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: AppTheme.sectionSpacing) {
                    ForEach(vm.widgetsByType, id: \.type) { group in
                        widgetSection(type: group.type, widgets: group.widgets, vm: vm)
                    }

                    if vm.area.widgets.isEmpty {
                        ContentUnavailableView(
                            "No Devices",
                            systemImage: "square.grid.2x2",
                            description: Text("No devices are assigned to this area.")
                        )
                    }
                }
                .padding()
            }
        }
        .background(AppTheme.groupedBackground)
        .navigationTitle(area.name)
        .onAppear {
            if viewModel == nil {
                viewModel = RoomViewModel(area: area, appState: appState)
            }
        }
        .refreshable {
            await appState.refreshCurrentBuilding()
            if let updated = appState.currentAreas.first(where: { $0.id == area.id }) {
                viewModel?.area = updated
            }
        }
    }

    private func widgetSection(type: WidgetType, widgets: [DeviceWidget], vm: RoomViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: type.rawValue.capitalized, icon: "square.grid.2x2.fill")

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(widgets) { widget in
                    WidgetCard(widget: widget) {
                        Task { await vm.toggleWidget(widget) }
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        PlatformService.isWideDevice ? AppTheme.padColumns : AppTheme.phoneColumns
    }
}
