import Foundation
import SwiftUI
import Combine

nonisolated enum QuizViewState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}

enum TriviaCategory: String, CaseIterable, Identifiable {
    case general = "General Knowledge"
    case games = "Video Games"
    case science = "Science & Nature"
    case computers = "Computers"
    case sports = "Sports"
    case history = "History"
    
    var id: String { self.rawValue }
    
    var apiId: Int {
        switch self {
        case .general: return 9
        case .games: return 15
        case .science: return 17
        case .computers: return 18
        case .sports: return 21
        case .history: return 23
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "globe.americas.fill"
        case .games: return "gamecontroller.fill"
        case .science: return "atom"
        case .computers: return "desktopcomputer"
        case .sports: return "sportscourt.fill"
        case .history: return "book.closed.fill"
        }
    }
}

final class QuizViewModel: ObservableObject {
    @Published var viewState: QuizViewState = .idle
    @Published var selectedCategory: TriviaCategory = .general
    @Published var questions: [Question] = []
    @Published var index: Int = 0
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
    
    // Cache shuffled choices by Question ID to prevent view re-render reshuffling
    private var shuffledAnswersCache: [UUID: [String]] = [:]
    
    private let service = TriviaService()
    
    // Retrieve current question
    var currentQuestion: Question? {
        guard index >= 0 && index < questions.count else { return nil }
        return questions[index]
    }
    
    // Retrieve cached shuffled answers for the current question
    func shuffledAnswers(for question: Question) -> [String] {
        if let cached = shuffledAnswersCache[question.id] {
            return cached
        }
        var answers = question.decodedIncorrectAnswers
        answers.append(question.decodedCorrectAnswer)
        let shuffled = answers.shuffled()
        shuffledAnswersCache[question.id] = shuffled
        return shuffled
    }
    
    // Check if transition is in progress (to temporarily disable buttons)
    var isTransitioning: Bool {
        correctHighlightIndex != nil || wrongHighlightIndex != nil
    }
    
    @MainActor
    func load(category: TriviaCategory) async {
        self.selectedCategory = category
        viewState = .loading
        score = 0
        streak = 0
        index = 0
        isNewHighScore = false
        hapticTrigger = nil
        correctHighlightIndex = nil
        wrongHighlightIndex = nil
        shuffledAnswersCache.removeAll()
        
        do {
            let results = try await service.fetchQuestions(categoryId: category.apiId)
            self.questions = results
            self.viewState = .loaded
        } catch {
            self.viewState = .failed("Connection failed. Please check your internet connection.")
        }
    }
    
    func tapAnswer(_ answer: String) {
        guard viewState == .loaded, let current = currentQuestion, !isTransitioning else { return }
        
        let correct = current.decodedCorrectAnswer
        if answer == correct {
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
            correctHighlightIndex = correct // reveal correct answer!
            score = max(0, score - 1)
            streak = 0
            hapticTrigger = .error
            
            // Trigger red shake animation
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
        
        if index + 1 <= questions.count {
            index += 1
        }
        
        if index >= questions.count {
            endGame()
        }
    }
    
    private func endGame() {
        if score > highScoreQuizRush {
            highScoreQuizRush = score
            isNewHighScore = true
        } else {
            isNewHighScore = false
        }
        hapticTrigger = .warning

        let saveLocation = UserDefaults.standard.object(forKey: "SaveLocationWithSessions") as? Bool ?? true
        if saveLocation {
            LocationService.shared.refreshLocation()
        }
        let lat = saveLocation ? LocationService.shared.currentLatitude : nil
        let lon = saveLocation ? LocationService.shared.currentLongitude : nil
        SessionHistoryManager.shared.saveSession(
            mode: "Quiz Rush",
            score: score,
            latitude: lat,
            longitude: lon
        )
    }
}
