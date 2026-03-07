import SwiftUI

struct WidgetCard: View {
    let widget: DeviceWidget
    var onTap: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: widget.displayIcon)
                        .font(.title2)
                        .foregroundStyle(iconColor)
                        .frame(width: 32, height: 32)

                    Spacer()

                    StatusBadge(state: widget.state, compact: true)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(widget.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(widget.kind == .virtual ? "Virtual" : "Physical")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if let value = stateValueText {
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(value)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var iconColor: Color {
        switch widget.state {
        case .on, .open, .unlocked:
            AppTheme.accent
        case .opening, .closing:
            AppTheme.warningYellow
        case .off, .closed, .locked, .unknown:
            .secondary
        case .value:
            AppTheme.accent
        }
    }

    private var stateValueText: String? {
        if case .value(let v) = widget.state {
            return String(format: "%.1f", v)
        }
        return nil
    }
}
