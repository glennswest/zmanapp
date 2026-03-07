import SwiftUI

struct SectionHeader: View {
    let title: String
    var icon: String? = nil
    var trailing: (() -> AnyView)? = nil

    var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.accent)
            }
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
            if let trailing {
                trailing()
            }
        }
        .padding(.horizontal, 4)
    }
}
