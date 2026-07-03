import Foundation
import SwiftUI
import Combine

enum QuizState: Equatable {
    case loading
    case error(String)
    case playing
    case finished
}

struct PreparedQuestion: Identifiable, Equatable {
    let id: UUID = UUID()
    let question: String
    let correctAnswer: String
    let shuffledAnswers: [String]
}

final class QuizViewModel: ObservableObject {
    @Published var state: QuizState = .loading
    @Published var questions: [PreparedQuestion] = []
    @Published var currentIndex: Int = 0
    @Published var score: Int = 0
    @Published var streak: Int = 0
    @Published var isNewHighScore: Bool = false
    
    // High Score persistent storage
    @AppStorage("HighScore_QuizRush") var highScoreQuizRush: Int = 0
    
    // Haptic Triggers
    enum HapticType {
        case success
        case error
        case warning
    }
    @Published var hapticTrigger: HapticType? = nil
    
    // Check if there's a next question
    var currentQuestion: PreparedQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    func startGame() {
        state = .loading
        score = 0
        streak = 0
        currentIndex = 0
        isNewHighScore = false
        hapticTrigger = nil
        
        Task {
            await fetchQuestions()
        }
    }
    
    func fetchQuestions() async {
        let urlString = "https://opentdb.com/api.php?amount=10&type=multiple"
        guard let url = URL(string: urlString) else {
            updateStateOnMainThread(.error("Invalid URL format"))
            return
        }
        
        do {
            updateStateOnMainThread(.loading)
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                updateStateOnMainThread(.error("Network server returned an error code"))
                return
            }
            
            let decoded = try JSONDecoder().decode(TriviaResponse.self, from: data)
            
            if decoded.response_code == 0 {
                // Prepare and pre-shuffle answers to prevent view re-render shuffling issues
                let prepared = decoded.results.map { item -> PreparedQuestion in
                    let decodedQ = item.decodedQuestion
                    let decodedCorrect = item.correctAnswer.decodingHTMLEntities()
                    var answers = item.incorrectAnswers.map { $0.decodingHTMLEntities() }
                    answers.append(decodedCorrect)
                    return PreparedQuestion(
                        question: decodedQ,
                        correctAnswer: decodedCorrect,
                        shuffledAnswers: answers.shuffled()
                    )
                }
                
                await MainActor.run {
                    self.questions = prepared
                    self.state = .playing
                }
            } else {
                updateStateOnMainThread(.error("Failed to retrieve questions from server"))
            }
            
        } catch {
            updateStateOnMainThread(.error("Connection failed. Please check your internet connection."))
        }
    }
    
    func tapAnswer(_ answer: String) {
        guard state == .playing, let current = currentQuestion else { return }
        
        if answer == current.correctAnswer {
            // Correct answer
            streak += 1
            let pointsGained = 1 + max(0, streak - 1)
            score += pointsGained
            hapticTrigger = .success
        } else {
            // Incorrect answer: small penalty
            score = max(0, score - 1)
            streak = 0
            hapticTrigger = .error
        }
        
        // Advance to next question
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
            // Finished!
            endGame()
        }
    }
    
    private func endGame() {
        state = .finished
        if score > highScoreQuizRush {
            highScoreQuizRush = score
            isNewHighScore = true
        } else {
            isNewHighScore = false
        }
        hapticTrigger = .warning
    }
    
    private func updateStateOnMainThread(_ newState: QuizState) {
        DispatchQueue.main.async {
            self.state = newState
        }
    }
}
