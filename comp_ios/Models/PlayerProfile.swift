import Foundation

struct PlayerProfile: Codable, Identifiable, Equatable, Sendable {
    let id: String
    /// Login name (email or username), unique on this device.
    var username: String
    var displayName: String
    /// Simple SHA256 hash — fine for a local educational app.
    var passwordHash: String
    let createdAt: Date
    var lastPlayedAt: Date
    var avatarSymbol: String

    static func make(username: String, passwordHash: String) -> PlayerProfile {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return PlayerProfile(
            id: UUID().uuidString,
            username: clean.lowercased(),
            displayName: clean,
            passwordHash: passwordHash,
            createdAt: Date(),
            lastPlayedAt: Date(),
            avatarSymbol: avatar(for: clean)
        )
    }

    private static func avatar(for name: String) -> String {
        let symbols = [
            "gamecontroller.fill", "bolt.fill", "star.fill",
            "flame.fill", "sparkles", "trophy.fill", "headphones"
        ]
        let idx = abs(name.hashValue) % symbols.count
        return symbols[idx]
    }
}

struct LeaderboardEntry: Identifiable, Equatable, Sendable {
    var id: String { playerId }
    let playerId: String
    let displayName: String
    let avatarSymbol: String
    let totalXP: Int
    let bestScore: Int
    let gamesPlayed: Int
    let rank: Int
}
