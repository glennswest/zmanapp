import Foundation

struct Residence: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var address: String
    var tunnelURL: String
    var rooms: [Room]
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String,
        address: String = "",
        tunnelURL: String = "",
        rooms: [Room] = [],
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.tunnelURL = tunnelURL
        self.rooms = rooms
        self.isActive = isActive
    }
}

extension Residence {
    static let preview = Residence(
        name: "Home",
        address: "123 Main St",
        tunnelURL: "https://home.example.com",
        rooms: [
            Room(name: "Living Room", icon: "sofa.fill", mode: .general),
            Room(name: "Garage", icon: "car.fill", mode: .garage),
            Room(name: "Kitchen", icon: "refrigerator.fill", mode: .room),
            Room(name: "Bedroom", icon: "bed.double.fill", mode: .room),
            Room(name: "Office", icon: "desktopcomputer", mode: .room),
        ]
    )
}
