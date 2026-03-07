import SwiftUI

struct GarageDoorControl: View {
    let door: DeviceWidget
    var isOperating: Bool = false
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 20) {
                // Door visual
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(doorBackgroundColor)
                        .frame(width: 80, height: 80)

                    Image(systemName: doorIcon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(doorIconColor)
                        .symbolEffect(.pulse, isActive: isAnimating)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(door.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    StatusBadge(state: door.state)

                    Text(actionLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Action chevron
                Image(systemName: actionIcon)
                    .font(.title2)
                    .foregroundStyle(doorIconColor)
                    .frame(width: 44, height: 44)
                    .background(doorIconColor.opacity(0.1))
                    .clipShape(Circle())
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .disabled(isOperating)
        .opacity(isOperating ? 0.7 : 1)
    }

    private var doorIcon: String {
        switch door.state {
        case .open, .opening: "door.garage.open"
        case .closed, .closing: "door.garage.closed"
        default: "door.garage.closed"
        }
    }

    private var doorIconColor: Color {
        switch door.state {
        case .open: .orange
        case .opening, .closing: .yellow
        case .closed: .green
        default: .gray
        }
    }

    private var doorBackgroundColor: Color {
        doorIconColor.opacity(0.15)
    }

    private var isAnimating: Bool {
        door.state == .opening || door.state == .closing
    }

    private var actionLabel: String {
        switch door.state {
        case .open, .opening: "Tap to close"
        case .closed, .closing: "Tap to open"
        default: "Tap to toggle"
        }
    }

    private var actionIcon: String {
        switch door.state {
        case .open, .opening: "chevron.down"
        case .closed, .closing: "chevron.up"
        default: "arrow.up.arrow.down"
        }
    }
}
