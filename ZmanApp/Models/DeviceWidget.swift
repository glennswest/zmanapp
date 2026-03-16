import Foundation

// MARK: - Widget Type (inferred from device_id)

enum WidgetType: String, Hashable, Sendable {
    case garage
    case thermostat
    case sensor
    case weather
    case plug
    case unknown

    static func infer(from deviceId: String) -> WidgetType {
        if deviceId.hasPrefix("virtual.esphome.") { return .garage }
        if deviceId.hasPrefix("virtual.hvac.") { return .thermostat }
        if deviceId.hasPrefix("zwave.") { return .sensor }
        if deviceId.hasPrefix("virtual.weather.") { return .weather }
        return .unknown
    }

    static func fromRaw(_ raw: String) -> WidgetType {
        switch raw {
        case "garage": .garage
        case "hvac": .thermostat
        case "sensor": .sensor
        case "weather", "forecast": .weather
        case "plug": .plug
        default: .unknown
        }
    }
}

// MARK: - Property Value (flexible JSON value)

enum PropertyValue: Codable, Hashable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)

    var stringValue: String {
        switch self {
        case .string(let s): s
        case .number(let n):
            n.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(n))
                : String(format: "%.1f", n)
        case .bool(let b): b ? "true" : "false"
        }
    }

    var doubleValue: Double? {
        switch self {
        case .number(let n): n
        case .string(let s): Double(s)
        case .bool: nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let b): b
        case .string(let s): s == "true"
        case .number(let n): n != 0
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            self = .string("")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .bool(let b): try container.encode(b)
        }
    }
}

// MARK: - Device Widget

struct DeviceWidget: Identifiable, Codable, Hashable {
    let id: String
    let deviceId: String
    var label: String
    var dashboardId: String
    var properties: [String: PropertyValue]
    var sortOrder: Int
    var widgetTypeRaw: String?
    var widgetProperty: String?

    var widgetType: WidgetType {
        if let raw = widgetTypeRaw {
            let t = WidgetType.fromRaw(raw)
            if t != .unknown { return t }
        }
        return WidgetType.infer(from: deviceId)
    }

    // MARK: - Convenience Accessors

    /// Garage door state (closed/open/opening/closing)
    var state: String? { properties["state"]?.stringValue }

    /// Temperature in Celsius
    var temperature: Double? { properties["temperature"]?.doubleValue }

    /// Humidity percentage
    var humidity: Double? { properties["humidity"]?.doubleValue }

    /// Thermostat desired temperature
    var desiredTemp: Double? { properties["desiredTemp"]?.doubleValue }

    /// Thermostat room temperature
    var roomTemp: Double? { properties["roomTemp"]?.doubleValue }

    /// HVAC fan mode
    var fanMode: String? { properties["fanMode"]?.stringValue }

    /// Wind speed
    var windSpeed: Double? { properties["windSpeed"]?.doubleValue }

    /// Wind direction in degrees
    var windDirection: Double? { properties["windDirection"]?.doubleValue }

    /// Weather condition text (e.g., "Partly cloudy")
    var condition: String? { properties["condition"]?.stringValue }

    /// Weather code (WMO)
    var weatherCode: Int? {
        if let n = properties["weatherCode"]?.doubleValue { return Int(n) }
        return nil
    }

    /// Thermostat mode (heat/cool/auto)
    var thermostatMode: String? { properties["thermostatMode"]?.stringValue }

    /// Thermostat state (heating/cooling/idle)
    var thermostatState: String? { properties["thermostatState"]?.stringValue }

    // Garage convenience
    var isGarageClosed: Bool { state == "closed" }
    var isGarageOpen: Bool { state == "open" }
    var isGarageMoving: Bool { state == "opening" || state == "closing" }

    // MARK: - Display Helpers

    /// Formatted temperature string with degree symbol
    func formatTemp(_ value: Double?) -> String {
        guard let v = value else { return "--" }
        return String(format: "%.1f°C", v)
    }

    /// Formatted humidity string
    func formatHumidity(_ value: Double?) -> String {
        guard let v = value else { return "--" }
        return String(format: "%.0f%%", v)
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case id, deviceId, label, name, dashboardId, properties, sortOrder, order
        case widgetTypeRaw = "type"
        case widgetProperty = "property"
    }

    init(id: String, deviceId: String, label: String, dashboardId: String = "default", properties: [String: PropertyValue] = [:], sortOrder: Int = 0, widgetTypeRaw: String? = nil, widgetProperty: String? = nil) {
        self.id = id
        self.deviceId = deviceId
        self.label = label
        self.dashboardId = dashboardId
        self.properties = properties
        self.sortOrder = sortOrder
        self.widgetTypeRaw = widgetTypeRaw
        self.widgetProperty = widgetProperty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        deviceId = try c.decodeIfPresent(String.self, forKey: .deviceId) ?? ""
        let l = try c.decodeIfPresent(String.self, forKey: .label)
        let n = try c.decodeIfPresent(String.self, forKey: .name)
        label = l ?? n ?? "Widget"
        dashboardId = try c.decodeIfPresent(String.self, forKey: .dashboardId) ?? "default"
        properties = try c.decodeIfPresent([String: PropertyValue].self, forKey: .properties) ?? [:]
        let so = try c.decodeIfPresent(Int.self, forKey: .sortOrder)
        let o = try c.decodeIfPresent(Int.self, forKey: .order)
        sortOrder = so ?? o ?? 0
        widgetTypeRaw = try c.decodeIfPresent(String.self, forKey: .widgetTypeRaw)
        widgetProperty = try c.decodeIfPresent(String.self, forKey: .widgetProperty)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(deviceId, forKey: .deviceId)
        try c.encode(label, forKey: .label)
        try c.encode(dashboardId, forKey: .dashboardId)
        try c.encode(properties, forKey: .properties)
        try c.encode(sortOrder, forKey: .sortOrder)
        try c.encodeIfPresent(widgetTypeRaw, forKey: .widgetTypeRaw)
        try c.encodeIfPresent(widgetProperty, forKey: .widgetProperty)
    }
}
