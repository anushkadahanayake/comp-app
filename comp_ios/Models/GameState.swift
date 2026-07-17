import Foundation

/// Value type used by timers / onChange — must stay nonisolated under default MainActor isolation.
nonisolated enum GameState: Equatable, Sendable {
    case idle
    case running
    case finished
}

nonisolated enum GameMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case tapFrenzy = "Tap Frenzy"
    case lightItUp = "Light It Up"
    case quizRush = "Quiz Rush"
    
    var id: String { self.rawValue }
}

nonisolated struct Card: Identifiable, Equatable, Sendable {
    let id: Int
    var isLit: Bool = false
    /// Gold “clock” card — tapping it grants extra round time.
    var isBonusTime: Bool = false
}

nonisolated enum Level: CaseIterable, Sendable {
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
    
    /// From Level 3 up, two cards light at once (one normal + one bonus-time).
    var activeLitCount: Int {
        switch self {
        case .l3, .l4: return 2
        default: return 1
        }
    }
}

// MARK: - Trivia Models
nonisolated struct TriviaResponse: Codable, Sendable {
    let response_code: Int
    let results: [Question]
}

nonisolated struct Question: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
    
    // Decoded question helper
    nonisolated var decodedQuestion: String {
        question.decodingHTMLEntities()
    }
    
    // Decoded correct answer helper
    nonisolated var decodedCorrectAnswer: String {
        correct_answer.decodingHTMLEntities()
    }
    
    // Decoded incorrect answers helper
    nonisolated var decodedIncorrectAnswers: [String] {
        incorrect_answers.map { $0.decodingHTMLEntities() }
    }

    enum CodingKeys: String, CodingKey {
        case category, type, difficulty, question
        case correct_answer
        case incorrect_answers
    }

    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        category = try container.decode(String.self, forKey: .category)
        type = try container.decode(String.self, forKey: .type)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        question = try container.decode(String.self, forKey: .question)
        correct_answer = try container.decode(String.self, forKey: .correct_answer)
        incorrect_answers = try container.decode([String].self, forKey: .incorrect_answers)
    }
    
    nonisolated static func == (lhs: Question, rhs: Question) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - HTML Decoding Extension
extension String {
    /// Trivia DB entity decode — nonisolated (no UIKit / MainActor dependency).
    nonisolated func decodingHTMLEntities() -> String {
        var result = self
        let entities: [(String, String)] = [
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#039;", "'"),
            ("&#39;", "'"),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&nbsp;", " "),
            ("&ldquo;", "\u{201C}"),
            ("&rdquo;", "\u{201D}"),
            ("&lsquo;", "\u{2018}"),
            ("&rsquo;", "\u{2019}"),
            ("&hellip;", "…"),
            ("&mdash;", "—"),
            ("&ndash;", "–")
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }

        // Numeric entities like &#039; or &#x27;
        if let regex = try? NSRegularExpression(pattern: "&#(x?[0-9A-Fa-f]+);") {
            let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)
            let matches = regex.matches(in: result, range: nsRange).reversed()
            for match in matches {
                guard let fullRange = Range(match.range, in: result),
                      let valueRange = Range(match.range(at: 1), in: result) else { continue }
                let raw = String(result[valueRange])
                let scalarValue: UInt32?
                if raw.lowercased().hasPrefix("x") {
                    scalarValue = UInt32(raw.dropFirst(), radix: 16)
                } else {
                    scalarValue = UInt32(raw)
                }
                if let scalarValue, let scalar = UnicodeScalar(scalarValue) {
                    result.replaceSubrange(fullRange, with: String(Character(scalar)))
                }
            }
        }

        return result
    }
}
