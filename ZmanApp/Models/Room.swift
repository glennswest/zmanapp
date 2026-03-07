import Foundation

enum RoomMode: String, Codable, Hashable, CaseIterable {
    case general
    case room
    case garage
}

struct Room: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var mode: RoomMode
    var widgets: [DeviceWidget]
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "square.grid.2x2.fill",
        mode: RoomMode = .room,
        widgets: [DeviceWidget] = [],
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.mode = mode
        self.widgets = widgets
        self.sortOrder = sortOrder
    }
}
