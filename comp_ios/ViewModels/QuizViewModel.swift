import Foundation
import SwiftUI
import Combine

nonisolated enum QuizViewState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case levelComplete
    case failed(String)
}

enum TriviaCategory: String, CaseIterable, Identifiable {
    case any = "Any Category"
    case general = "General Knowledge"
    case games = "Video Games"
    case science = "Science & Nature"
    case computers = "Computers"
    case sports = "Sports"
    case history = "History"

    var id: String { rawValue }

    var apiId: Int? {
        switch self {
        case .any: return nil
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
        case .any: return "sparkles"
        case .general: return "globe.americas.fill"
        case .games: return "gamecontroller.fill"
        case .science: return "atom"
        case .computers: return "desktopcomputer"
        case .sports: return "sportscourt.fill"
        case .history: return "book.closed.fill"
        }
    }
}

/// Progressive campaign: Easy → Medium → Hard (longer sessions for retention).
nonisolated enum QuizCampaignLevel: Int, CaseIterable, Identifiable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .easy: return "Level 1 · Easy"
        case .medium: return "Level 2 · Medium"
        case .hard: return "Level 3 · Hard"
        }
    }

    var shortTitle: String {
        switch self {
        case .easy: return "EASY"
        case .medium: return "MEDIUM"
        case .hard: return "HARD"
        }
    }

    var apiDifficulty: String {
        switch self {
        case .easy: return "easy"
        case .medium: return "medium"
        case .hard: return "hard"
        }
    }

    var questionCount: Int {
        switch self {
        case .easy: return 5
        case .medium: return 6
        case .hard: return 7
        }
    }

    var baseQuestionTime: Double {
        switch self {
        case .easy: return 20
        case .medium: return 16
        case .hard: return 13
        }
    }

    var next: QuizCampaignLevel? {
        QuizCampaignLevel(rawValue: rawValue + 1)
    }
}

final class QuizViewModel: ObservableObject {
    @Published var viewState: QuizViewState = .idle
    @Published var selectedCategory: TriviaCategory = .any
    @Published var questions: [Question] = []
    @Published var index: Int = 0
    @Published var score: Int = 0
    @Published var streak: Int = 0
    @Published var isNewHighScore: Bool = false

    @Published var campaignLevel: QuizCampaignLevel = .easy
    @Published var lives: Int = 3
    @Published var timeRemaining: Double = 20
    @Published var maxQuestionTime: Double = 20
    @Published var totalCorrect: Int = 0
    @Published var levelsCleared: Int = 0
    @Published var bonusBanner: String?
    @Published var lastPointsGained: Int = 0

    @Published var correctHighlightIndex: String?
    @Published var wrongHighlightIndex: String?
    @Published var shakeTrigger: CGFloat = 0.0

    @AppStorage("HighScore_QuizRush") var highScoreQuizRush: Int = 0

    enum HapticType {
        case success
        case error
        case warning
    }
    @Published var hapticTrigger: HapticType?

    private var shuffledAnswersCache: [UUID: [String]] = [:]
    private let service = TriviaService()
    private var questionTimer: Timer?
    private var questionStartedAt: Date?
    private var hasEnded = false

    var currentQuestion: Question? {
        guard index >= 0 && index < questions.count else { return nil }
        return questions[index]
    }

    var isTransitioning: Bool {
        correctHighlightIndex != nil || wrongHighlightIndex != nil
    }

    var timerProgress: Double {
        guard maxQuestionTime > 0 else { return 0 }
        return max(0, min(1, timeRemaining / maxQuestionTime))
    }

    var isGameOver: Bool {
        hasEnded || (viewState == .loaded && index >= questions.count && !questions.isEmpty)
    }

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

    @MainActor
    func load(category: TriviaCategory) async {
        selectedCategory = category
        score = 0
        streak = 0
        index = 0
        lives = 3
        totalCorrect = 0
        levelsCleared = 0
        isNewHighScore = false
        hasEnded = false
        bonusBanner = nil
        lastPointsGained = 0
        hapticTrigger = nil
        correctHighlightIndex = nil
        wrongHighlightIndex = nil
        shuffledAnswersCache.removeAll()
        stopQuestionTimer()
        await startLevel(.easy)
    }

    @MainActor
    func continueToNextLevel() async {
        guard let next = campaignLevel.next else {
            endGame()
            return
        }
        await startLevel(next)
    }

    @MainActor
    private func startLevel(_ level: QuizCampaignLevel) async {
        campaignLevel = level
        viewState = .loading
        index = 0
        questions = []
        shuffledAnswersCache.removeAll()
        correctHighlightIndex = nil
        wrongHighlightIndex = nil
        bonusBanner = nil
        stopQuestionTimer()

        do {
            let results = try await service.fetchQuestions(
                categoryId: selectedCategory.apiId,
                difficulty: level.apiDifficulty,
                amount: level.questionCount
            )
            questions = results
            maxQuestionTime = level.baseQuestionTime
            timeRemaining = level.baseQuestionTime
            viewState = .loaded
            beginQuestionTimer()
        } catch let error as TriviaServiceError {
            viewState = .failed(error.localizedDescription)
        } catch {
            viewState = .failed("Could not load questions. Check your internet, wait a few seconds, then retry.")
        }
    }

    func tapAnswer(_ answer: String) {
        guard viewState == .loaded, currentQuestion != nil, !isTransitioning, !hasEnded else { return }

        stopQuestionTimer()
        let elapsed = Date().timeIntervalSince(questionStartedAt ?? Date())
        let correct = currentQuestion?.decodedCorrectAnswer ?? ""

        if answer == correct {
            applyCorrectAnswer(selected: answer, elapsed: elapsed)
        } else {
            applyWrongAnswer(selected: answer, correct: correct)
        }
    }

    private func applyCorrectAnswer(selected: String, elapsed: TimeInterval) {
        correctHighlightIndex = selected
        streak += 1
        totalCorrect += 1

        var points = 2 + max(0, streak - 1)
        var bonusSeconds = 2.0
        var bannerParts = ["+2s Correct"]

        if elapsed <= 5 {
            points += 3
            bonusSeconds += 4
            bannerParts.append("+4s Speed")
        } else if elapsed <= 10 {
            points += 1
            bonusSeconds += 2
            bannerParts.append("+2s Quick")
        }

        if streak >= 3 {
            bonusSeconds += 2
            bannerParts.append("+2s Streak")
        }

        score += points
        lastPointsGained = points
        timeRemaining = min(40, timeRemaining + bonusSeconds)
        maxQuestionTime = max(maxQuestionTime, timeRemaining)
        bonusBanner = bannerParts.joined(separator: " · ") + " · +\(points) pts"
        hapticTrigger = .success

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.advanceQuestion()
        }
    }

    private func applyWrongAnswer(selected: String, correct: String) {
        wrongHighlightIndex = selected
        correctHighlightIndex = correct
        streak = 0
        lives = max(0, lives - 1)
        score = max(0, score - 1)
        timeRemaining = max(0, timeRemaining - 2)
        bonusBanner = "−1 Life · −2s"
        hapticTrigger = .error

        withAnimation(.default) {
            shakeTrigger += 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { [weak self] in
            guard let self else { return }
            if self.lives <= 0 {
                self.endGame()
            } else {
                self.advanceQuestion()
            }
        }
    }

    private func advanceQuestion() {
        correctHighlightIndex = nil
        wrongHighlightIndex = nil
        bonusBanner = nil

        if index + 1 < questions.count {
            index += 1
            let carry = min(6, max(0, timeRemaining * 0.35))
            timeRemaining = campaignLevel.baseQuestionTime + carry
            maxQuestionTime = timeRemaining
            beginQuestionTimer()
            return
        }

        levelsCleared += 1
        stopQuestionTimer()

        if campaignLevel.next != nil {
            score += 5
            lives = min(5, lives + 1)
            bonusBanner = "Level Cleared! +5 pts · +1 Life"
            viewState = .levelComplete
        } else {
            score += 10
            endGame()
        }
    }

    private func beginQuestionTimer() {
        stopQuestionTimer()
        questionStartedAt = Date()
        questionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                guard self.viewState == .loaded, !self.isTransitioning, !self.hasEnded else { return }
                self.timeRemaining -= 0.1
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.handleTimeExpired()
                }
            }
        }
    }

    private func handleTimeExpired() {
        guard viewState == .loaded, !isTransitioning, !hasEnded else { return }
        stopQuestionTimer()

        if let current = currentQuestion {
            wrongHighlightIndex = nil
            correctHighlightIndex = current.decodedCorrectAnswer
        }

        streak = 0
        lives = max(0, lives - 1)
        bonusBanner = "Time's up! −1 Life"
        hapticTrigger = .warning

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self else { return }
            if self.lives <= 0 {
                self.endGame()
            } else {
                self.advanceQuestion()
            }
        }
    }

    private func stopQuestionTimer() {
        questionTimer?.invalidate()
        questionTimer = nil
    }

    private func endGame() {
        guard !hasEnded else { return }
        hasEnded = true
        stopQuestionTimer()
        correctHighlightIndex = nil
        wrongHighlightIndex = nil
        index = max(questions.count, index)
        viewState = .loaded

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
        SessionHistoryManager.shared.saveSession(
            mode: "Quiz Rush",
            score: score,
            latitude: saveLocation ? LocationService.shared.currentLatitude : nil,
            longitude: saveLocation ? LocationService.shared.currentLongitude : nil
        )
    }

    deinit {
        questionTimer?.invalidate()
    }
}
