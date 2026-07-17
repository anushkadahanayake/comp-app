import Foundation
import Combine

/// Per-player high scores and leaderboard aggregation.
@MainActor
final class PlayerStatsStore: ObservableObject {
    static let shared = PlayerStatsStore()

    @Published private(set) var revision = 0

    private init() {}

    func highScoreKey(mode: GameMode, playerId: String) -> String {
        "\(mode.highScoreKey)_\(playerId)"
    }

    func highScore(for mode: GameMode, playerId: String) -> Int {
        UserDefaults.standard.integer(forKey: highScoreKey(mode: mode, playerId: playerId))
    }

    func setHighScore(_ score: Int, for mode: GameMode, playerId: String) {
        let key = highScoreKey(mode: mode, playerId: playerId)
        let current = UserDefaults.standard.integer(forKey: key)
        if score > current {
            UserDefaults.standard.set(score, forKey: key)
            revision += 1
        }
    }

    func updateHighScoreIfNeeded(score: Int, mode: GameMode, playerId: String) -> Bool {
        let current = highScore(for: mode, playerId: playerId)
        if score > current {
            UserDefaults.standard.set(score, forKey: highScoreKey(mode: mode, playerId: playerId))
            revision += 1
            return true
        }
        return false
    }

    func ensureDefaults(for playerId: String) {
        // Migrates legacy global highs into the first signed-in player once.
        let flag = "DidMigrateLegacyHighScores_\(playerId)"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        let isFirstPlayer = AuthService.shared.knownPlayers.count <= 1
        if isFirstPlayer {
            for mode in [GameMode.tapFrenzy, .lightItUp, .quizRush] {
                let legacy = UserDefaults.standard.integer(forKey: mode.highScoreKey)
                if legacy > highScore(for: mode, playerId: playerId) {
                    UserDefaults.standard.set(legacy, forKey: highScoreKey(mode: mode, playerId: playerId))
                }
            }
        }
        UserDefaults.standard.set(true, forKey: flag)
        revision += 1
    }

    func resetScores(for playerId: String) {
        for mode in [GameMode.tapFrenzy, .lightItUp, .quizRush] {
            UserDefaults.standard.set(0, forKey: highScoreKey(mode: mode, playerId: playerId))
        }
        revision += 1
    }

    /// Overall ranking by total XP across all games.
    func leaderboard(limit: Int = 20) -> [LeaderboardEntry] {
        let players = AuthService.shared.knownPlayers
        let sessions = SessionHistoryManager.shared.sessions

        let ranked: [(PlayerProfile, Int, Int, Int)] = players.map { player in
            let mine = sessions.filter { $0.playerId == player.id }
            let xp = mine.reduce(0) { $0 + $1.score }
            let best = mine.map(\.score).max()
                ?? [
                    highScore(for: .tapFrenzy, playerId: player.id),
                    highScore(for: .lightItUp, playerId: player.id),
                    highScore(for: .quizRush, playerId: player.id)
                ].max() ?? 0
            return (player, xp, best, mine.count)
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.2 > rhs.2
        }

        return ranked.prefix(limit).enumerated().map { index, row in
            LeaderboardEntry(
                id: "overall-\(row.0.id)",
                playerId: row.0.id,
                displayName: row.0.displayName,
                avatarSymbol: row.0.avatarSymbol,
                totalXP: row.1,
                bestScore: row.2,
                gamesPlayed: row.3,
                rank: index + 1
            )
        }
    }

    /// Per-game ranking by that mode’s best score (high score + session history).
    func leaderboard(for mode: GameMode, limit: Int = 10) -> [LeaderboardEntry] {
        let players = AuthService.shared.knownPlayers
        let sessions = SessionHistoryManager.shared.sessions
        let modeName = mode.rawValue

        let ranked: [(PlayerProfile, Int, Int)] = players.compactMap { player in
            let modeSessions = sessions.filter { $0.playerId == player.id && $0.mode == modeName }
            let sessionBest = modeSessions.map(\.score).max() ?? 0
            let storedBest = highScore(for: mode, playerId: player.id)
            let best = max(sessionBest, storedBest)
            let games = modeSessions.count
            guard best > 0 || games > 0 else { return nil }
            return (player, best, games)
        }
        .sorted { lhs, rhs in
            if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
            return lhs.2 > rhs.2
        }

        return ranked.prefix(limit).enumerated().map { index, row in
            LeaderboardEntry(
                id: "\(mode.rawValue)-\(row.0.id)",
                playerId: row.0.id,
                displayName: row.0.displayName,
                avatarSymbol: row.0.avatarSymbol,
                totalXP: row.1,
                bestScore: row.1,
                gamesPlayed: row.2,
                rank: index + 1
            )
        }
    }
}

extension GameMode {
    var highScoreKey: String {
        switch self {
        case .tapFrenzy: return "HighScore_TapFrenzy"
        case .lightItUp: return "HighScore_LightItUp"
        case .quizRush: return "HighScore_QuizRush"
        }
    }
}
