import Foundation
import Combine

struct GameSession: Codable, Identifiable {
    let id: UUID
    let mode: String // "Tap Frenzy", "Light It Up", "Quiz Rush"
    let score: Int
    let timestamp: Date
    let latitude: Double?
    let longitude: Double?
}

final class SessionHistoryManager: ObservableObject {
    static let shared = SessionHistoryManager()
    
    @Published var sessions: [GameSession] = []
    
    private init() {
        loadSessions()
    }
    
    func saveSession(mode: String, score: Int, latitude: Double?, longitude: Double?) {
        let newSession = GameSession(
            id: UUID(),
            mode: mode,
            score: score,
            timestamp: Date(),
            latitude: latitude,
            longitude: longitude
        )
        DispatchQueue.main.async {
            self.sessions.append(newSession)
            self.saveToDisk()
        }
    }
    
    func clearAll() {
        DispatchQueue.main.async {
            self.sessions.removeAll()
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
            self.sessions = decoded
        }
    }
}
