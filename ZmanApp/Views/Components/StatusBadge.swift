import SwiftUI

struct StatusBadge: View {
    let state: String
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(stateColor)
                .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
            if !compact {
                Text(state.uppercased())
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
        case "on", "open", "unlocked":
            AppTheme.onlineGreen
        case "off", "closed", "locked":
            AppTheme.offGray
        case "opening", "closing":
            AppTheme.warningYellow
        default:
            AppTheme.offGray
        }
    }
}
