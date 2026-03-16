import Foundation

@MainActor
@Observable
final class GarageViewModel {
    var area: Area
    var isOperating = false
    var statusMessage: String?

    private let appState: AppState

    init(area: Area, appState: AppState) {
        self.area = area
        self.appState = appState
    }

    var garageDoors: [DeviceWidget] {
        area.widgets
            .filter { $0.widgetType == .garage }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var sensors: [DeviceWidget] {
        area.widgets
            .filter { $0.widgetType == .sensor }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var otherWidgets: [DeviceWidget] {
        area.widgets
            .filter { $0.widgetType != .garage && $0.widgetType != .sensor }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    func toggleDoor(_ door: DeviceWidget) async {
        isOperating = true
        defer { isOperating = false }
        statusMessage = "Toggling \(door.label)..."
        await appState.toggleWidget(door)
        statusMessage = nil
    }
}
