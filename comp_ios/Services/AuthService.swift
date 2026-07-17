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

    /// Guests kept on this device (newest first) so they can be resumed after log out.
    var savedGuests: [PlayerProfile] {
        knownPlayers
            .filter(\.isGuest)
            .sorted { $0.lastPlayedAt > $1.lastPlayedAt }
    }

    private let playersKey = "ArcadeKnownPlayers_v2"
    private let currentPlayerKey = "ArcadeCurrentPlayerId"
    /// Guests unused longer than this are removed from the resume list.
    private let guestRetentionDays = 30

    private init() {
        loadPlayers()
        pruneExpiredGuests()
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
        if knownPlayers.contains(where: { $0.username == cleanUser.lowercased() && !$0.isGuest }) {
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

        guard let player = knownPlayers.first(where: { $0.username == cleanUser && !$0.isGuest }) else {
            authError = "No account found. Create one first."
            return
        }
        guard player.passwordHash == hashPassword(cleanPass) else {
            authError = "Wrong password. Try again."
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

    /// Resume a guest that was saved on this device (no password).
    func resumeGuest(playerId: String) {
        authError = nil
        guard var guest = knownPlayers.first(where: { $0.id == playerId && $0.isGuest }) else {
            authError = "That guest profile is no longer saved on this device."
            return
        }
        guest.lastPlayedAt = Date()
        activate(guest)
    }

    /// Turn the current guest into a full account — **same player id**, so scores stay.
    func upgradeGuest(username: String, password: String) {
        authError = nil
        guard var player = currentPlayer, player.isGuest else {
            authError = "Only a guest can upgrade to a full account."
            return
        }

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
        if knownPlayers.contains(where: {
            $0.username == cleanUser.lowercased() && !$0.isGuest && $0.id != player.id
        }) {
            authError = "That username is already taken."
            return
        }

        player.username = cleanUser.lowercased()
        player.displayName = cleanUser
        player.passwordHash = hashPassword(cleanPass)
        player.isGuest = false
        player.lastPlayedAt = Date()
        activate(player)
    }

    // MARK: - Session

    /// Signs out but **keeps** the profile (including guests) on this device for resume.
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

    private func pruneExpiredGuests() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -guestRetentionDays, to: Date()) ?? Date.distantPast
        let before = knownPlayers.count
        knownPlayers.removeAll { player in
            player.isGuest && player.lastPlayedAt < cutoff
        }
        if knownPlayers.count != before {
            savePlayers()
        }
    }

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        return SHA256.hash(data: data).compactMap { String(format: "%02x", $0) }.joined()
    }
}
