import SwiftUI

enum AppTheme {
    // MARK: - Colors

    static let accent = Color.accentColor
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)

    static let onlineGreen = Color.green
    static let warningYellow = Color.yellow
    static let errorRed = Color.red
    static let offGray = Color(.systemGray4)

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

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
