import Foundation
import Combine

enum GameState {
    case idle
    case running
    case finished
}

final class GameViewModel: ObservableObject {
    @Published var state: GameState = .idle
    @Published var timeLeft: Int = 10
    @Published var tapCount: Int = 0
    @Published var highScore: Int = 0

    private var timer: Timer?

    func startGame() {
        // Reset values and start
        tapCount = 0
        timeLeft = 10
        state = .running

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            if self.timeLeft > 0 {
                self.timeLeft -= 1
            }
            if self.timeLeft <= 0 {
                t.invalidate()
                self.timer = nil
                self.state = .finished
                if self.tapCount > self.highScore {
                    self.highScore = self.tapCount
                }
            }
        }
        // Ensure timer runs on common modes so it continues during UI interactions
        RunLoop.main.add(timer!, forMode: .common)
    }

    func tapButton() {
        guard state == .running else { return }
        tapCount += 1
    }

    func resetGame() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeLeft = 10
        tapCount = 0
    }

    deinit {
        timer?.invalidate()
    }
}
