import Foundation
import Combine

struct GameSession: Codable, Identifiable, Sendable {
    let id: UUID
    let mode: String
    let score: Int
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
    let playerId: String?
    let playerName: String?

    init(
        id: UUID = UUID(),
        mode: String,
        score: Int,
        timestamp: Date = Date(),
        latitude: Double?,
        longitude: Double?,
        playerId: String?,
        playerName: String?
    ) {
        self.id = id
        self.mode = mode
        self.score = score
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.playerId = playerId
        self.playerName = playerName
    }

    private enum CodingKeys: String, CodingKey {
        case id, mode, score, timestamp, latitude, longitude, playerId, playerName
    }

    /// Backwards-compatible decode for sessions saved before player profiles.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        mode = try c.decode(String.self, forKey: .mode)
        score = try c.decode(Int.self, forKey: .score)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        latitude = try c.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try c.decodeIfPresent(Double.self, forKey: .longitude)
        playerId = try c.decodeIfPresent(String.self, forKey: .playerId)
        playerName = try c.decodeIfPresent(String.self, forKey: .playerName)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(mode, forKey: .mode)
        try c.encode(score, forKey: .score)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encodeIfPresent(playerId, forKey: .playerId)
        try c.encodeIfPresent(playerName, forKey: .playerName)
    }
}

final class SessionHistoryManager: ObservableObject {
    static let shared = SessionHistoryManager()

    @Published var sessions: [GameSession] = []

    private init() {
        loadSessions()
    }

    func saveSession(mode: String, score: Int, latitude: Double?, longitude: Double?) {
        let player = AuthService.shared.currentPlayer
        let newSession = GameSession(
            mode: mode,
            score: score,
            latitude: latitude,
            longitude: longitude,
            playerId: player?.id,
            playerName: player?.displayName
        )
        DispatchQueue.main.async {
            self.sessions.append(newSession)
            self.saveToDisk()
            AuthService.shared.touchLastPlayed()
            PlayerStatsStore.shared.objectWillChange.send()
        }
    }

    func sessions(for playerId: String) -> [GameSession] {
        sessions.filter { $0.playerId == playerId }
    }

    func clearAll() {
        DispatchQueue.main.async {
            self.sessions.removeAll()
            self.saveToDisk()
        }
    }

    func clearSessions(for playerId: String) {
        DispatchQueue.main.async {
            self.sessions.removeAll { $0.playerId == playerId }
            self.saveToDisk()
        }
    }

    private func saveToDisk() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "SavedGameSessions")
        }
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: "SavedGameSessions"),
           let decoded = try? JSONDecoder().decode([GameSession].self, from: data) {
            sessions = decoded
        }
    }
}
