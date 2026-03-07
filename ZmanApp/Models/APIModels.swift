import Foundation

// MARK: - API Response Wrappers

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let error: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let total: Int
    let page: Int
    let pageSize: Int
}

// MARK: - Auth

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

// MARK: - Widget Commands

struct WidgetCommand: Codable {
    let widgetId: UUID
    let action: String
    let parameters: [String: String]?
}

struct WidgetCommandResult: Codable {
    let widgetId: UUID
    let success: Bool
    let newState: WidgetState?
    let message: String?
}

// MARK: - Building (Home/Building)

struct Building: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var areas: [Area]
    var tunnelURL: String

    init(
        id: UUID = UUID(),
        name: String,
        address: String = "",
        areas: [Area] = [],
        tunnelURL: String = ""
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.areas = areas
        self.tunnelURL = tunnelURL
    }
}

// MARK: - Area (Room/Zone/Garage)

struct Area: Identifiable, Codable, Hashable {
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
