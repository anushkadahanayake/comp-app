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
        defaults.integer(forKey: highScoreKey)
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
            subtitle: "10s speed tap challenge",
            imageName: "tapFrenzyHero",
            gradient: [.blue, .purple],
            icon: "bolt.fill",
            highScoreKey: "HighScore_TapFrenzy"
        ),
        ArcadeGame(
            mode: .lightItUp,
            subtitle: "Whack-a-mole reflex mode",
            imageName: "lightItUpHero",
            gradient: [.orange, .yellow],
            icon: "lightbulb.fill",
            highScoreKey: "HighScore_LightItUp"
        ),
        ArcadeGame(
            mode: .quizRush,
            subtitle: "Rapid-fire trivia",
            imageName: "quizRushHero",
            gradient: [.purple, .pink],
            icon: "questionmark.circle.fill",
            highScoreKey: "HighScore_QuizRush"
        )
    ]
}
