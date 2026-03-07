import SwiftUI

struct StatusBadge: View {
    let state: WidgetState
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
            if !compact {
                Text(stateText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(stateColor)
            }
        }
        .padding(.horizontal, compact ? 4 : 8)
        .padding(.vertical, compact ? 2 : 4)
        .background(stateColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var stateColor: Color {
        switch state {
        case .on, .open, .unlocked:
            AppTheme.onlineGreen
        case .off, .closed, .locked:
            AppTheme.offGray
        case .opening, .closing:
            AppTheme.warningYellow
        case .value:
            AppTheme.accent
        case .unknown:
            AppTheme.offGray
        }
    }

    private var stateText: String {
        switch state {
        case .on: "ON"
        case .off: "OFF"
        case .open: "OPEN"
        case .closed: "CLOSED"
        case .opening: "OPENING"
        case .closing: "CLOSING"
        case .locked: "LOCKED"
        case .unlocked: "UNLOCKED"
        case .value(let v): String(format: "%.0f", v)
        case .unknown: "—"
        }
    }
}
