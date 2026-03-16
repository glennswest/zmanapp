import Foundation

enum WidgetKind: String, Codable, Hashable, CaseIterable {
    case physical
    case virtual
}

enum WidgetCategory: String, Codable, Hashable, CaseIterable {
    case light
    case lock
    case garageDoor
    case thermostat
    case camera
    case sensor
    case media
    case switch_
    case blinds
    case fan
    case sprinkler
    case custom

    var displayName: String {
        switch self {
        case .light: "Light"
        case .lock: "Lock"
        case .garageDoor: "Garage Door"
        case .thermostat: "Thermostat"
        case .camera: "Camera"
        case .sensor: "Sensor"
        case .media: "Media"
        case .switch_: "Switch"
        case .blinds: "Blinds"
        case .fan: "Fan"
        case .sprinkler: "Sprinkler"
        case .custom: "Custom"
        }
    }

    var systemImage: String {
        switch self {
        case .light: "lightbulb.fill"
        case .lock: "lock.fill"
        case .garageDoor: "door.garage.closed"
        case .thermostat: "thermometer.medium"
        case .camera: "video.fill"
        case .sensor: "sensor.fill"
        case .media: "play.circle.fill"
        case .switch_: "power"
        case .blinds: "blinds.vertical.closed"
        case .fan: "fan.fill"
        case .sprinkler: "sprinkler.and.droplets.fill"
        case .custom: "gearshape.fill"
        }
    }
}

enum WidgetState: Codable, Hashable {
    case on
    case off
    case open
    case closed
    case opening
    case closing
    case locked
    case unlocked
    case value(Double)
    case unknown
}

struct DeviceWidget: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var kind: WidgetKind
    var category: WidgetCategory
    var state: WidgetState
    var roomId: String?
    var icon: String?
    var sortOrder: Int
    var metadata: [String: String]

    var displayIcon: String {
        icon ?? category.systemImage
    }

    var isToggleable: Bool {
        switch category {
        case .light, .lock, .garageDoor, .switch_, .fan, .blinds, .sprinkler:
            true
        default:
            false
        }
    }

    // Custom decoding with defaults for optional server fields
    enum CodingKeys: String, CodingKey {
        case id, name, kind, category, state, roomId, icon, sortOrder, metadata
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        kind = try c.decodeIfPresent(WidgetKind.self, forKey: .kind) ?? .physical
        category = try c.decodeIfPresent(WidgetCategory.self, forKey: .category) ?? .custom
        state = try c.decodeIfPresent(WidgetState.self, forKey: .state) ?? .unknown
        roomId = try c.decodeIfPresent(String.self, forKey: .roomId)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        metadata = try c.decodeIfPresent([String: String].self, forKey: .metadata) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(kind, forKey: .kind)
        try c.encode(category, forKey: .category)
        try c.encode(state, forKey: .state)
        try c.encodeIfPresent(roomId, forKey: .roomId)
        try c.encodeIfPresent(icon, forKey: .icon)
        try c.encode(sortOrder, forKey: .sortOrder)
        try c.encode(metadata, forKey: .metadata)
    }
}
