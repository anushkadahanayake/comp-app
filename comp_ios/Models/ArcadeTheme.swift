import SwiftUI

/// Blue-led "Midnight Arcade" palette — cool dark surfaces, sky/royal blue accent.
enum ArcadeTheme {
    // MARK: Surfaces
    static let background = Color(red: 0.06, green: 0.08, blue: 0.12)
    static let backgroundDeep = Color(red: 0.04, green: 0.06, blue: 0.10)
    static let surface = Color(red: 0.10, green: 0.13, blue: 0.18)
    static let surfaceElevated = Color(red: 0.14, green: 0.18, blue: 0.24)
    static let surfaceMuted = Color(red: 0.08, green: 0.11, blue: 0.16)

    // MARK: Text
    static let textPrimary = Color(red: 0.93, green: 0.95, blue: 0.98)
    static let textSecondary = Color(red: 0.60, green: 0.68, blue: 0.78)
    static let textTertiary = Color(red: 0.45, green: 0.52, blue: 0.62)

    // MARK: Brand accents — blue theme
    /// Primary CTA / selection
    static let accent = Color(red: 0.30, green: 0.62, blue: 0.98)
    /// Secondary — deeper royal blue
    static let accentSecondary = Color(red: 0.22, green: 0.42, blue: 0.82)
    static let accentMuted = Color(red: 0.30, green: 0.62, blue: 0.98).opacity(0.18)
    /// Soft highlight / ice blue
    static let accentSoft = Color(red: 0.55, green: 0.78, blue: 1.0)

    // MARK: Semantic
    static let success = Color(red: 0.38, green: 0.72, blue: 0.58)
    static let warning = Color(red: 0.92, green: 0.72, blue: 0.32)
    static let danger = Color(red: 0.86, green: 0.38, blue: 0.40)
    static let info = accent

    // MARK: Borders / overlays
    static let border = Color.white.opacity(0.10)
    static let borderStrong = Color.white.opacity(0.16)
    static let dim = Color.black.opacity(0.35)

    // MARK: Gradients
    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.40, green: 0.72, blue: 1.0),
                Color(red: 0.22, green: 0.45, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surfaceElevated, surface],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Ambient blobs for animated backgrounds (blue family)
    static var ambientA: Color { Color(red: 0.12, green: 0.28, blue: 0.55).opacity(0.55) }
    static var ambientB: Color { Color(red: 0.18, green: 0.45, blue: 0.75).opacity(0.40) }
    static var ambientC: Color { Color(red: 0.25, green: 0.35, blue: 0.70).opacity(0.35) }
    static var ambientD: Color { Color(red: 0.10, green: 0.55, blue: 0.70).opacity(0.28) }

    // Per-game accents (all in the blue family for a cohesive look)
    static let tapFrenzy = Color(red: 0.28, green: 0.60, blue: 0.95)
    static let lightItUp = Color(red: 0.25, green: 0.72, blue: 0.88)
    static let quizRush = Color(red: 0.38, green: 0.50, blue: 0.92)
}

extension Color {
    static let arcadeBackground = ArcadeTheme.background
    static let arcadeSurface = ArcadeTheme.surface
    static let arcadeAccent = ArcadeTheme.accent
    static let arcadeText = ArcadeTheme.textPrimary
    static let arcadeSecondary = ArcadeTheme.textSecondary
}
