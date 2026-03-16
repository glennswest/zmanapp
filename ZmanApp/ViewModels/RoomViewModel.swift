import Foundation

@MainActor
@Observable
final class RoomViewModel {
    var area: Area
    private let appState: AppState

    init(area: Area, appState: AppState) {
        self.area = area
        self.appState = appState
    }

    var widgetsByType: [(type: WidgetType, widgets: [DeviceWidget])] {
        let grouped = Dictionary(grouping: area.widgets) { $0.widgetType }
        return grouped
            .map { (type: $0.key, widgets: $0.value.sorted(by: { $0.sortOrder < $1.sortOrder })) }
            .sorted(by: { $0.type.rawValue < $1.type.rawValue })
    }

    func toggleWidget(_ widget: DeviceWidget) async {
        await appState.toggleWidget(widget)
    }

    func sendCommand(_ widget: DeviceWidget, command: String) async {
        await appState.sendWidgetCommand(widget, command: command)
    }
}
