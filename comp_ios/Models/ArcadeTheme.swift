import SwiftUI

/// Eye-friendly "Midnight Arcade" palette — warm dark surfaces, one amber accent,
/// soft steel secondary. Avoids neon cyan/purple glow spam.
enum ArcadeTheme {
    // MARK: Surfaces
    static let background = Color(red: 0.07, green: 0.075, blue: 0.09)
    static let backgroundDeep = Color(red: 0.05, green: 0.055, blue: 0.07)
    static let surface = Color(red: 0.12, green: 0.13, blue: 0.155)
    static let surfaceElevated = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let surfaceMuted = Color(red: 0.10, green: 0.11, blue: 0.13)

    // MARK: Text
    static let textPrimary = Color(red: 0.93, green: 0.94, blue: 0.96)
    static let textSecondary = Color(red: 0.62, green: 0.65, blue: 0.70)
    static let textTertiary = Color(red: 0.48, green: 0.51, blue: 0.56)

    // MARK: Brand accents (restrained)
    /// Primary CTA / selection — warm amber (readable on dark)
    static let accent = Color(red: 0.93, green: 0.64, blue: 0.32)
    /// Secondary — soft steel blue
    static let accentSecondary = Color(red: 0.42, green: 0.58, blue: 0.72)
    static let accentMuted = Color(red: 0.93, green: 0.64, blue: 0.32).opacity(0.18)

    // MARK: Semantic
    static let success = Color(red: 0.42, green: 0.70, blue: 0.52)
    static let warning = Color(red: 0.90, green: 0.68, blue: 0.30)
    static let danger = Color(red: 0.82, green: 0.40, blue: 0.38)
    static let info = accentSecondary

    // MARK: Borders / overlays
    static let border = Color.white.opacity(0.10)
    static let borderStrong = Color.white.opacity(0.16)
    static let dim = Color.black.opacity(0.35)

    // MARK: Gradients (subtle, not neon)
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.70, blue: 0.38),
                Color(red: 0.88, green: 0.48, blue: 0.28)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceElevated, surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var ambientA: Color { Color(red: 0.28, green: 0.18, blue: 0.12).opacity(0.55) }
    static var ambientB: Color { Color(red: 0.12, green: 0.20, blue: 0.28).opacity(0.45) }
    static var ambientC: Color { Color(red: 0.20, green: 0.14, blue: 0.18).opacity(0.35) }

    // Per-game accents (distinct but not neon)
    static let tapFrenzy = Color(red: 0.35, green: 0.58, blue: 0.82)
    static let lightItUp = Color(red: 0.90, green: 0.58, blue: 0.28)
    static let quizRush = Color(red: 0.55, green: 0.48, blue: 0.78)
}

extension Color {
    static let arcadeBackground = ArcadeTheme.background
    static let arcadeSurface = ArcadeTheme.surface
    static let arcadeAccent = ArcadeTheme.accent
    static let arcadeText = ArcadeTheme.textPrimary
    static let arcadeSecondary = ArcadeTheme.textSecondary
}
