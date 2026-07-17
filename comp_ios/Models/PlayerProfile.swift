import Foundation

struct PlayerProfile: Codable, Identifiable, Equatable, Sendable {
    let id: String
    /// Login name (email or username), unique on this device.
    var username: String
    var displayName: String
    /// Simple SHA256 hash — fine for a local educational app. Empty for guests.
    var passwordHash: String
    var isGuest: Bool
    let createdAt: Date
    var lastPlayedAt: Date
    var avatarSymbol: String

    init(
        id: String,
        username: String,
        displayName: String,
        passwordHash: String,
        isGuest: Bool,
        createdAt: Date,
        lastPlayedAt: Date,
        avatarSymbol: String
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.passwordHash = passwordHash
        self.isGuest = isGuest
        self.createdAt = createdAt
        self.lastPlayedAt = lastPlayedAt
        self.avatarSymbol = avatarSymbol
    }

    static func make(username: String, passwordHash: String) -> PlayerProfile {
        let clean = username.trimmingCharacters(in: .whitespacesAndNewlines)
        return PlayerProfile(
            id: UUID().uuidString,
            username: clean.lowercased(),
            displayName: clean,
            passwordHash: passwordHash,
            isGuest: false,
            createdAt: Date(),
            lastPlayedAt: Date(),
            avatarSymbol: avatar(for: clean)
        )
    }

    static func makeGuest(displayName: String) -> PlayerProfile {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Guest" : trimmed
        return PlayerProfile(
            id: UUID().uuidString,
            username: "guest_\(UUID().uuidString.prefix(8))",
            displayName: name,
            passwordHash: "",
            isGuest: true,
            createdAt: Date(),
            lastPlayedAt: Date(),
            avatarSymbol: avatar(for: name)
        )
    }

    /// Older saved profiles may not have `isGuest`.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        username = try c.decode(String.self, forKey: .username)
        displayName = try c.decode(String.self, forKey: .displayName)
        passwordHash = try c.decode(String.self, forKey: .passwordHash)
        isGuest = try c.decodeIfPresent(Bool.self, forKey: .isGuest) ?? passwordHash.isEmpty
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        lastPlayedAt = try c.decode(Date.self, forKey: .lastPlayedAt)
        avatarSymbol = try c.decode(String.self, forKey: .avatarSymbol)
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
    let id: String
    let playerId: String
    let displayName: String
    let avatarSymbol: String
    /// Overall board: total XP. Per-game board: same as bestScore for that mode.
    let totalXP: Int
    let bestScore: Int
    let gamesPlayed: Int
    let rank: Int
}
