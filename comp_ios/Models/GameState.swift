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

struct Card: Identifiable, Equatable {
    let id: Int
    var isLit: Bool = false
}

enum Level: CaseIterable {
    case l1, l2, l3, l4
    
    var name: String {
        switch self {
        case .l1: return "Level 1"
        case .l2: return "Level 2"
        case .l3: return "Level 3"
        case .l4: return "Level 4"
        }
    }
    
    var cardCount: Int {
        switch self {
        case .l1: return 3
        case .l2: return 4
        case .l3: return 6
        case .l4: return 9
        }
    }
    
    var litWindow: TimeInterval {
        switch self {
        case .l1: return 1.5
        case .l2: return 1.2
        case .l3: return 1.0
        case .l4: return 0.8
        }
    }
    
    var activeLitCount: Int {
        switch self {
        case .l4: return 2
        default: return 1
        }
    }
}
