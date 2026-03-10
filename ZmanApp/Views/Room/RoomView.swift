import SwiftUI

struct RoomView: View {
    let area: Area
    @Environment(AppState.self) private var appState
    @State private var viewModel: RoomViewModel?
    @State private var showPhysicalOnly = false
    @State private var showVirtualOnly = false

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: AppTheme.sectionSpacing) {
                    filterBar

                    ForEach(vm.widgetsByCategory, id: \.category) { group in
                        let filtered = filteredWidgets(group.widgets)
                        if !filtered.isEmpty {
                            widgetSection(category: group.category, widgets: filtered, vm: vm)
                        }
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

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 12) {
            FilterChip(title: "All", isSelected: !showPhysicalOnly && !showVirtualOnly) {
                showPhysicalOnly = false
                showVirtualOnly = false
            }
            FilterChip(title: "Physical", isSelected: showPhysicalOnly) {
                showPhysicalOnly = true
                showVirtualOnly = false
            }
            FilterChip(title: "Virtual", isSelected: showVirtualOnly) {
                showVirtualOnly = true
                showPhysicalOnly = false
            }
            Spacer()
        }
    }

    // MARK: - Widget Section

    private func widgetSection(category: WidgetCategory, widgets: [DeviceWidget], vm: RoomViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: category.displayName, icon: category.systemImage)

            LazyVGrid(columns: gridColumns, spacing: 12) {
                ForEach(widgets) { widget in
                    WidgetCard(widget: widget) {
                        if widget.isToggleable {
                            Task { await vm.toggleWidget(widget) }
                        }
                    }
                }
            }
        }
    }

    private func filteredWidgets(_ widgets: [DeviceWidget]) -> [DeviceWidget] {
        if showPhysicalOnly {
            return widgets.filter { $0.kind == .physical }
        } else if showVirtualOnly {
            return widgets.filter { $0.kind == .virtual }
        }
        return widgets
    }

    private var gridColumns: [GridItem] {
        PlatformService.isWideDevice ? AppTheme.padColumns : AppTheme.phoneColumns
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.accent : AppTheme.secondaryBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
