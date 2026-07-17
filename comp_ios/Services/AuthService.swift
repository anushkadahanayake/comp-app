import Foundation
import Combine
import CryptoKit

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentPlayer: PlayerProfile?
    @Published private(set) var knownPlayers: [PlayerProfile] = []
    @Published var authError: String?

    var isSignedIn: Bool { currentPlayer != nil }

    private let playersKey = "ArcadeKnownPlayers_v2"
    private let currentPlayerKey = "ArcadeCurrentPlayerId"

    private init() {
        loadPlayers()
        if let id = UserDefaults.standard.string(forKey: currentPlayerKey) {
            currentPlayer = knownPlayers.first(where: { $0.id == id })
        }
    }

    // MARK: - Register / Login

    func register(username: String, password: String) {
        authError = nil
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPass = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanUser.count >= 3 else {
            authError = "Username must be at least 3 characters."
            return
        }
        guard cleanPass.count >= 4 else {
            authError = "Password must be at least 4 characters."
            return
        }
        if knownPlayers.contains(where: { $0.username == cleanUser.lowercased() }) {
            authError = "That username is already taken. Try logging in."
            return
        }

        let player = PlayerProfile.make(
            username: cleanUser,
            passwordHash: hashPassword(cleanPass)
        )
        activate(player)
    }

    func login(username: String, password: String) {
        authError = nil
        let cleanUser = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPass = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let player = knownPlayers.first(where: { $0.username == cleanUser }) else {
            authError = "No account found. Create one first."
            return
        }
        guard player.passwordHash == hashPassword(cleanPass) else {
            authError = "Wrong password. Try again."
            return
        }

        guard !player.isGuest else {
            authError = "That is a guest profile. Use Continue as Guest with a name."
            return
        }

        var restored = player
        restored.lastPlayedAt = Date()
        activate(restored)
    }

    func continueAsGuest(displayName: String) {
        authError = nil
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.count >= 2 else {
            authError = "Enter a nickname (at least 2 characters)."
            return
        }
        activate(PlayerProfile.makeGuest(displayName: name))
    }

    // MARK: - Session

    func signOut() {
        currentPlayer = nil
        UserDefaults.standard.removeObject(forKey: currentPlayerKey)
    }

    func updateDisplayName(_ name: String) {
        guard var player = currentPlayer else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        player.displayName = trimmed
        player.lastPlayedAt = Date()
        activate(player)
    }

    func touchLastPlayed() {
        guard var player = currentPlayer else { return }
        player.lastPlayedAt = Date()
        upsert(player)
        currentPlayer = player
    }

    // MARK: - Persistence

    private func activate(_ player: PlayerProfile) {
        var updated = player
        updated.lastPlayedAt = Date()
        upsert(updated)
        currentPlayer = updated
        UserDefaults.standard.set(updated.id, forKey: currentPlayerKey)
        PlayerStatsStore.shared.ensureDefaults(for: updated.id)
    }

    private func upsert(_ player: PlayerProfile) {
        if let idx = knownPlayers.firstIndex(where: { $0.id == player.id }) {
            knownPlayers[idx] = player
        } else {
            knownPlayers.append(player)
        }
        savePlayers()
    }

    private func loadPlayers() {
        guard let data = UserDefaults.standard.data(forKey: playersKey),
              let decoded = try? JSONDecoder().decode([PlayerProfile].self, from: data) else {
            knownPlayers = []
            return
        }
        knownPlayers = decoded
    }

    private func savePlayers() {
        if let data = try? JSONEncoder().encode(knownPlayers) {
            UserDefaults.standard.set(data, forKey: playersKey)
        }
    }

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}
