import SwiftUI

struct ArcadeGame: Identifiable {
    let mode: GameMode
    let subtitle: String
    let imageName: String
    let gradient: [Color]
    let icon: String
    let highScoreKey: String

    var id: String { mode.rawValue }
    var title: String { mode.rawValue }

    func highScore(from defaults: UserDefaults = .standard) -> Int {
        if let playerId = AuthService.shared.currentPlayer?.id {
            return PlayerStatsStore.shared.highScore(for: mode, playerId: playerId)
        }
        return defaults.integer(forKey: highScoreKey)
    }

    @ViewBuilder
    var destination: some View {
        switch mode {
        case .tapFrenzy:
            TapFrenzyView()
        case .lightItUp:
            LightItUpView()
        case .quizRush:
            QuizRushView()
        }
    }

    static let all: [ArcadeGame] = [
        ArcadeGame(
            mode: .tapFrenzy,
            subtitle: "Level up · earn time · combo taps",
            imageName: "tapFrenzyHero",
            gradient: [ArcadeTheme.tapFrenzy, ArcadeTheme.accentSecondary],
            icon: "bolt.fill",
            highScoreKey: "HighScore_TapFrenzy"
        ),
        ArcadeGame(
            mode: .lightItUp,
            subtitle: "Lit cards · gold clock = extra time",
            imageName: "lightItUpHero",
            gradient: [ArcadeTheme.lightItUp, ArcadeTheme.accentSoft],
            icon: "lightbulb.fill",
            highScoreKey: "HighScore_LightItUp"
        ),
        ArcadeGame(
            mode: .quizRush,
            subtitle: "Easy→Hard campaign with bonus time",
            imageName: "quizRushHero",
            gradient: [ArcadeTheme.quizRush, ArcadeTheme.accentSecondary],
            icon: "questionmark.circle.fill",
            highScoreKey: "HighScore_QuizRush"
        )
    ]
}
