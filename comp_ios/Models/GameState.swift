import Foundation
import UIKit

enum GameState {
    case idle
    case running
    case finished
}

enum GameMode: String, CaseIterable, Identifiable {
    case tapFrenzy = "Tap Frenzy"
    case lightItUp = "Light It Up"
    case quizRush = "Quiz Rush"
    
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

// MARK: - Trivia Models
struct TriviaResponse: Codable {
    let response_code: Int
    let results: [Question]
}

struct Question: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
    
    // Decoded question helper
    var decodedQuestion: String {
        question.decodingHTMLEntities()
    }
    
    // Decoded correct answer helper
    var decodedCorrectAnswer: String {
        correct_answer.decodingHTMLEntities()
    }
    
    // Decoded incorrect answers helper
    var decodedIncorrectAnswers: [String] {
        incorrect_answers.map { $0.decodingHTMLEntities() }
    }

    enum CodingKeys: String, CodingKey {
        case category, type, difficulty, question
        case correct_answer = "correct_answer"
        case incorrect_answers = "incorrect_answers"
    }
    
    static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - HTML Decoding Extension
extension String {
    func decodingHTMLEntities() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }
        return self
    }
}
