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
            .filter { $0.category == .garageDoor }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var cameras: [DeviceWidget] {
        area.widgets
            .filter { $0.category == .camera }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var sensors: [DeviceWidget] {
        area.widgets
            .filter { $0.category == .sensor }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var lights: [DeviceWidget] {
        area.widgets
            .filter { $0.category == .light }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var otherWidgets: [DeviceWidget] {
        area.widgets
            .filter { ![.garageDoor, .camera, .sensor, .light].contains($0.category) }
            .sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    func toggleDoor(_ door: DeviceWidget) async {
        isOperating = true
        defer { isOperating = false }

        let action: String
        switch door.state {
        case .open, .opening:
            action = "close"
            statusMessage = "Closing \(door.name)..."
        case .closed, .closing:
            action = "open"
            statusMessage = "Opening \(door.name)..."
        default:
            action = "toggle"
            statusMessage = "Toggling \(door.name)..."
        }

        await appState.sendWidgetAction(door, action: action)
        statusMessage = nil
    }

    func toggleLight(_ light: DeviceWidget) async {
        await appState.toggleWidget(light)
    }
}
