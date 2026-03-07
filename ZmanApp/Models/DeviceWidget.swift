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
    let id: UUID
    var name: String
    var kind: WidgetKind
    var category: WidgetCategory
    var state: WidgetState
    var roomId: UUID?
    var icon: String?
    var sortOrder: Int
    var metadata: [String: String]

    init(
        id: UUID = UUID(),
        name: String,
        kind: WidgetKind = .physical,
        category: WidgetCategory = .switch_,
        state: WidgetState = .unknown,
        roomId: UUID? = nil,
        icon: String? = nil,
        sortOrder: Int = 0,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.category = category
        self.state = state
        self.roomId = roomId
        self.icon = icon
        self.sortOrder = sortOrder
        self.metadata = metadata
    }

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
}
