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

    var widgetsByCategory: [(category: WidgetCategory, widgets: [DeviceWidget])] {
        let grouped = Dictionary(grouping: area.widgets) { $0.category }
        return grouped
            .map { (category: $0.key, widgets: $0.value.sorted(by: { $0.sortOrder < $1.sortOrder })) }
            .sorted(by: { $0.category.displayName < $1.category.displayName })
    }

    var physicalWidgets: [DeviceWidget] {
        area.widgets.filter { $0.kind == .physical }.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var virtualWidgets: [DeviceWidget] {
        area.widgets.filter { $0.kind == .virtual }.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    func toggleWidget(_ widget: DeviceWidget) async {
        await appState.toggleWidget(widget)
    }

    func sendAction(_ widget: DeviceWidget, action: String, parameters: [String: String]? = nil) async {
        await appState.sendWidgetAction(widget, action: action, parameters: parameters)
    }
}
