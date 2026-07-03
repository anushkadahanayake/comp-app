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
    
    // Polish Feedback States
    @Published var correctHighlightIndex: String? = nil
    @Published var wrongHighlightIndex: String? = nil
    @Published var shakeTrigger: CGFloat = 0.0
    
    // High Score persistent storage
    @AppStorage("HighScore_QuizRush") var highScoreQuizRush: Int = 0
    
    // Haptic Triggers
    enum HapticType {
        case success
        case error
        case warning
    }
    @Published var hapticTrigger: HapticType? = nil
    
    private let service = TriviaService()
    
    // Check if there's a next question
    var currentQuestion: PreparedQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }
    
    // Check if transition is in progress (to temporarily disable buttons)
    var isTransitioning: Bool {
        correctHighlightIndex != nil || wrongHighlightIndex != nil
    }
    
    @MainActor
    func load() async {
        state = .loading
        score = 0
        streak = 0
        currentIndex = 0
        isNewHighScore = false
        hapticTrigger = nil
        correctHighlightIndex = nil
        wrongHighlightIndex = nil
        
        do {
            let results = try await service.fetchQuestions()
            
            // Prepare and pre-shuffle answers to prevent view re-render shuffling issues
            let prepared = results.map { item -> PreparedQuestion in
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
            
            self.questions = prepared
            self.state = .playing
            
        } catch {
            self.state = .error("Connection failed. Please check your internet connection.")
        }
    }
    
    func tapAnswer(_ answer: String) {
        guard state == .playing, let current = currentQuestion, !isTransitioning else { return }
        
        if answer == current.correctAnswer {
            // Correct answer
            correctHighlightIndex = answer
            streak += 1
            let pointsGained = 1 + max(0, streak - 1)
            score += pointsGained
            hapticTrigger = .success
            
            // Hold briefly for visual feedback, then advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
                self?.advanceQuestion()
            }
        } else {
            // Incorrect answer
            wrongHighlightIndex = answer
            correctHighlightIndex = current.correctAnswer // also reveal correct answer!
            score = max(0, score - 1)
            streak = 0
            hapticTrigger = .error
            
            // Trigger red shake animation by incrementing by 1
            withAnimation(.default) {
                shakeTrigger += 1.0
            }
            
            // Hold briefly for visual feedback, then advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                self?.advanceQuestion()
            }
        }
    }
    
    private func advanceQuestion() {
        correctHighlightIndex = nil
        wrongHighlightIndex = nil
        
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        } else {
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
}
