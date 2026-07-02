import Foundation

enum GameState {
    case idle
    case running
    case finished
}

enum GameMode: String, CaseIterable, Identifiable {
    case tapFrenzy = "Tap Frenzy"
    case lightItUp = "Light It Up"
    
    var id: String { self.rawValue }
}
