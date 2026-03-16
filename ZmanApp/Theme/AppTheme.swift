import SwiftUI

enum AppTheme {
    // MARK: - Dashboard Colors (dark theme matching web UI)

    static let dashBackground = Color(red: 0.059, green: 0.067, blue: 0.090)   // #0f1117
    static let dashCard = Color(red: 0.086, green: 0.106, blue: 0.133)         // #161b22
    static let dashBorder = Color(red: 0.188, green: 0.212, blue: 0.239)       // #30363d
    static let dashText = Color(red: 0.902, green: 0.929, blue: 0.953)         // #e6edf3
    static let dashSecondary = Color(red: 0.545, green: 0.580, blue: 0.620)    // #8b949e
    static let dashBlue = Color(red: 0.345, green: 0.651, blue: 1.0)           // #58a6ff
    static let dashGreen = Color(red: 0.247, green: 0.725, blue: 0.314)        // #3fb950
    static let dashYellow = Color(red: 0.847, green: 0.659, blue: 0.110)       // #d8a81c
    static let dashOrange = Color(red: 0.878, green: 0.396, blue: 0.220)       // #e0653a
    static let dashRed = Color(red: 0.973, green: 0.318, blue: 0.286)          // #f85149

    // MARK: - System Colors

    static let accent = Color.accentColor

    #if os(macOS)
    static let background = Color(nsColor: .windowBackgroundColor)
    static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    static let tertiaryBackground = Color(nsColor: .underPageBackgroundColor)
    static let groupedBackground = Color(nsColor: .windowBackgroundColor)
    static let offGray = Color(nsColor: .systemGray)
    #else
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)
    static let offGray = Color(.systemGray4)
    #endif

    static let onlineGreen = Color.green
    static let warningYellow = Color.yellow
    static let errorRed = Color.red

    // MARK: - Card Style

    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardShadowRadius: CGFloat = 4

    // MARK: - Grid

    static let phoneColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    static let padColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    static let padWideColumns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    // MARK: - Spacing

    static let spacing: CGFloat = 16
    static let compactSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 24
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.cardPadding)
            .background(AppTheme.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .shadow(color: .black.opacity(0.1), radius: AppTheme.cardShadowRadius, y: 2)
    }
}

struct DashCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(AppTheme.dashCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.dashBorder, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func dashCardStyle() -> some View {
        modifier(DashCardStyle())
    }
}
