//
//  GameViewModel.swift
//  comp_ios
//
//  Created by ANUSHKA DAHANAYAKE on 2026-06-10.
//

import Foundation
import Combine
import CoreGraphics

final class GameViewModel: ObservableObject {
    @Published var state: GameState = .idle
    @Published var timeLeft: Int = 10
    @Published var tapCount: Int = 0
    @Published var highScore: Int = 0

    // Gameplay state
    @Published var multiplier: Int = 1
    @Published var lastTapDate: Date? = nil

    // Button presentation
    @Published var buttonOffset: CGSize = .zero
    @Published var buttonScale: CGFloat = 1.0

    // Color state: cycles every few seconds, with bonus and penalty windows
    enum ButtonMode { case normal, bonus, penalty }
    @Published var buttonMode: ButtonMode = .normal

    // Double points window (once per round, lasts 2 seconds)
    @Published var isDoublePointsActive: Bool = false
    private var hasUsedDoublePointsThisRound: Bool = false

    // Timers
    private var timer: Timer?
    private var moveTimer: Timer?
    private var colorTimer: Timer?
    private var doublePointsTimer: Timer?

    func startGame() {
        // Reset values and start
        tapCount = 0
        timeLeft = 10
        state = .running

        // Reset round-specific state
        multiplier = 1
        lastTapDate = nil
        buttonOffset = .zero
        buttonScale = 1.0
        buttonMode = .normal
        isDoublePointsActive = false
        hasUsedDoublePointsThisRound = false

        // Start movement timer (every 2 seconds)
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            // Random offset within a reasonable range; UI will clamp by layout
            let dx = CGFloat.random(in: -120...120)
            let dy = CGFloat.random(in: -200...200)
            DispatchQueue.main.async {
                self.buttonOffset = CGSize(width: dx, height: dy)
            }
        }
        RunLoop.main.add(moveTimer!, forMode: .common)

        // Start color timer (every 3 seconds cycle)
        colorTimer?.invalidate()
        colorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            switch self.buttonMode {
            case .normal:
                self.buttonMode = .bonus
            case .bonus:
                self.buttonMode = .penalty
            case .penalty:
                self.buttonMode = .normal
            }
        }
        RunLoop.main.add(colorTimer!, forMode: .common)

        // Schedule one double-points flash randomly within the round if not already used
        doublePointsTimer?.invalidate()
        let fireIn = max(1.0, Double(Int.random(in: 2...max(2, timeLeft-2))))
        doublePointsTimer = Timer.scheduledTimer(withTimeInterval: fireIn, repeats: false) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            self.isDoublePointsActive = true
            self.hasUsedDoublePointsThisRound = true
            // End after 2 seconds
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                self?.isDoublePointsActive = false
            }
        }
        if let doublePointsTimer { RunLoop.main.add(doublePointsTimer, forMode: .common) }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            if self.timeLeft > 0 {
                self.timeLeft -= 1
                // Scale button as time runs out: from 1.0 down to 0.4
                let total: CGFloat = 10
                let remaining = max(0, min(self.timeLeft, 10))
                let fraction = CGFloat(remaining) / total
                self.buttonScale = max(0.4, 0.4 + 0.6 * fraction)
            }
            if self.timeLeft <= 0 {
                t.invalidate()
                self.timer = nil
                self.state = .finished
                // Stop auxiliary timers
                self.moveTimer?.invalidate(); self.moveTimer = nil
                self.colorTimer?.invalidate(); self.colorTimer = nil
                self.doublePointsTimer?.invalidate(); self.doublePointsTimer = nil
                self.isDoublePointsActive = false
                // Update high score
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
        let now = Date()
        // Multiplier logic: consecutive taps within 0.5s increase multiplier; break resets to 1
        if let last = lastTapDate, now.timeIntervalSince(last) <= 0.5 {
            multiplier += 1
        } else {
            multiplier = 1
        }
        lastTapDate = now

        // Base points equals multiplier
        var points = multiplier

        // Button mode effects
        switch buttonMode {
        case .bonus:
            points += 1 // small bonus
        case .penalty:
            points = max(0, points - 1) // small penalty
        case .normal:
            break
        }

        // Double points window
        if isDoublePointsActive {
            points *= 2
        }

        tapCount += points
    }

    func resetGame() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeLeft = 10
        tapCount = 0

        moveTimer?.invalidate(); moveTimer = nil
        colorTimer?.invalidate(); colorTimer = nil
        doublePointsTimer?.invalidate(); doublePointsTimer = nil
        multiplier = 1
        lastTapDate = nil
        buttonOffset = .zero
        buttonScale = 1.0
        buttonMode = .normal
        isDoublePointsActive = false
        hasUsedDoublePointsThisRound = false
    }

    deinit {
        timer?.invalidate()
        moveTimer?.invalidate()
        colorTimer?.invalidate()
        doublePointsTimer?.invalidate()
    }
}
