import SwiftUI

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isActive: Bool = false
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isActive ? color : color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    if isLoading {
                        ProgressView()
                            .tint(isActive ? .white : color)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(isActive ? .white : color)
                    }
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}
