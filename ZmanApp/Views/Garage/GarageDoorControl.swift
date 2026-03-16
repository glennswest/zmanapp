import SwiftUI

struct GarageDoorControl: View {
    let door: DeviceWidget
    var isOperating: Bool = false
    let onToggle: () -> Void

    private var doorState: String { door.state ?? "unknown" }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(doorBackgroundColor)
                        .frame(width: 80, height: 80)

                    Image(systemName: doorIcon)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(doorIconColor)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(door.label)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    StatusBadge(state: doorState)

                    Text(actionLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

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
        switch doorState {
        case "open", "opening": "door.garage.open"
        default: "door.garage.closed"
        }
    }

    private var doorIconColor: Color {
        switch doorState {
        case "open": .orange
        case "opening", "closing": .yellow
        case "closed": .green
        default: .gray
        }
    }

    private var doorBackgroundColor: Color {
        doorIconColor.opacity(0.15)
    }

    private var actionLabel: String {
        switch doorState {
        case "open", "opening": "Tap to close"
        case "closed", "closing": "Tap to open"
        default: "Tap to toggle"
        }
    }

    private var actionIcon: String {
        switch doorState {
        case "open", "opening": "chevron.down"
        case "closed", "closing": "chevron.up"
        default: "arrow.up.arrow.down"
        }
    }
}
