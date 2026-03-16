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

// MARK: - Auth (Legacy)

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

// MARK: - Cloud Claim Flow

struct AppConnectRequest: Codable {
    let email: String
}

struct AppConnectResponse: Codable {
    let status: String
}

struct AppPollRequest: Codable {
    let email: String
}

struct HubClaim: Codable, Identifiable {
    let hostname: String
    let hubId: String
    let claimToken: String

    var id: String { hubId }
}

struct AppPollResponse: Codable {
    let status: String
    let claims: [HubClaim]?
}

struct ClaimRequest: Codable {
    let claimToken: String
}

struct ClaimResponse: Codable {
    let key: String
    let keyId: String
    let hubId: String
    let hostname: String
}

// MARK: - Device Commands

struct DeviceCommand: Codable {
    let command: String
}

// MARK: - Building (Home/Building)

struct Building: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var address: String
    var areas: [Area]
    var tunnelURL: String

    enum CodingKeys: String, CodingKey {
        case id, name, address, areas, tunnelURL
    }

    init(id: String, name: String, address: String = "", areas: [Area] = [], tunnelURL: String = "") {
        self.id = id
        self.name = name
        self.address = address
        self.areas = areas
        self.tunnelURL = tunnelURL
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Home"
        address = try c.decodeIfPresent(String.self, forKey: .address) ?? ""
        areas = try c.decodeIfPresent([Area].self, forKey: .areas) ?? []
        tunnelURL = try c.decodeIfPresent(String.self, forKey: .tunnelURL) ?? ""
    }
}

// MARK: - Area (Room/Zone/Garage)

struct Area: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var icon: String
    var mode: RoomMode
    var widgets: [DeviceWidget]
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, icon, mode, widgets, sortOrder, order
    }

    init(id: String, name: String, icon: String = "square.grid.2x2.fill", mode: RoomMode = .general, widgets: [DeviceWidget] = [], sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.mode = mode
        self.widgets = widgets
        self.sortOrder = sortOrder
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Area"
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "square.grid.2x2.fill"
        mode = try c.decodeIfPresent(RoomMode.self, forKey: .mode) ?? .general
        widgets = try c.decodeIfPresent([DeviceWidget].self, forKey: .widgets) ?? []
        let so = try c.decodeIfPresent(Int.self, forKey: .sortOrder)
        let o = try c.decodeIfPresent(Int.self, forKey: .order)
        sortOrder = so ?? o ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(icon, forKey: .icon)
        try c.encode(mode, forKey: .mode)
        try c.encode(widgets, forKey: .widgets)
        try c.encode(sortOrder, forKey: .sortOrder)
    }
}
