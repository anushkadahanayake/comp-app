//
//  GameViewModel.swift
//  comp_ios
//
//  Created by ANUSHKA DAHANAYAKE on 2026-06-10.
//

import Foundation
import Combine
import CoreGraphics
import SwiftUI

final class GameViewModel: ObservableObject {
    @Published var state: GameState = .idle
    @Published var currentMode: GameMode = .tapFrenzy
    
    // Timer and Score state (using Double for high-precision progress bar rendering)
    @Published var timeLeft: Double = 10.0
    @Published var tapCount: Int = 0
    @Published var isNewHighScore: Bool = false

    // Tap Frenzy Game State
    @Published var multiplier: Int = 1
    @Published var lastTapDate: Date? = nil
    @Published var buttonOffset: CGSize = .zero
    @Published var buttonScale: CGFloat = 1.0
    
    enum ButtonMode { case normal, bonus, penalty }
    @Published var buttonMode: ButtonMode = .normal
    @Published var isDoublePointsActive: Bool = false
    private var hasUsedDoublePointsThisRound: Bool = false

    // Light It Up Game State
    @Published var cards: [Card] = []
    @Published var currentLevel: Level = .l1
    
    // Haptic Feedback Trigger Communication
    enum HapticType {
        case success
        case error
        case warning
        case medium
        case light
    }
    @Published var hapticTrigger: HapticType? = nil

    // Timers
    private var mainTimer: Timer?
    private var cardTimer: Timer?
    private var moveTimer: Timer?
    private var colorTimer: Timer?
    private var doublePointsTimer: Timer?
    private var doublePointsEndTimer: Timer?

    func startGame() {
        tapCount = 0
        state = .running
        isNewHighScore = false
        hapticTrigger = nil
        
        switch currentMode {
        case .tapFrenzy:
            timeLeft = 10.0
            multiplier = 1
            lastTapDate = nil
            buttonOffset = .zero
            buttonScale = 1.0
            buttonMode = .normal
            isDoublePointsActive = false
            hasUsedDoublePointsThisRound = false
            
            startTapFrenzyTimers()
            
        case .lightItUp:
            timeLeft = 60.0
            currentLevel = .l1
            
            // Initialize cards & light up cards
            initializeCards(for: .l1)
            lightUpCards()
        }
        
        // High-precision main timer tick at 20Hz (0.05 seconds interval)
        mainTimer?.invalidate()
        mainTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            DispatchQueue.main.async {
                self.timerTick()
            }
        }
        RunLoop.main.add(mainTimer!, forMode: .common)
    }

    private func timerTick() {
        if timeLeft > 0 {
            timeLeft = max(0.0, timeLeft - 0.05)
            
            if currentMode == .tapFrenzy {
                let fraction = timeLeft / 10.0
                self.buttonScale = max(0.4, 0.4 + 0.6 * fraction)
            } else if currentMode == .lightItUp {
                // Determine level progression based on elapsed round time
                let elapsed = 60.0 - timeLeft
                let newLevel: Level
                if elapsed < 15.0 {
                    newLevel = .l1
                } else if elapsed < 30.0 {
                    newLevel = .l2
                } else if elapsed < 45.0 {
                    newLevel = .l3
                } else {
                    newLevel = .l4
                }
                
                if newLevel != currentLevel {
                    currentLevel = newLevel
                    // Rebuild cards grid for the new level
                    initializeCards(for: newLevel)
                    lightUpCards()
                }
            }
        }
        
        if timeLeft <= 0 {
            self.endGame()
        }
    }

    private func endGame() {
        mainTimer?.invalidate()
        mainTimer = nil
        cardTimer?.invalidate()
        cardTimer = nil
        stopTapFrenzyTimers()
        
        state = .finished
        isDoublePointsActive = false
        cards.removeAll()
        
        hapticTrigger = .warning
    }

    private func initializeCards(for level: Level) {
        cards = (0..<level.cardCount).map { Card(id: $0) }
    }

    func lightUpCards() {
        guard state == .running else { return }
        
        // Clear all active lit states
        for i in 0..<cards.count {
            cards[i].isLit = false
        }
        
        // Pick random unique indices to light up based on Level's active lit count
        let needed = currentLevel.activeLitCount
        var selectedIndices: Set<Int> = []
        while selectedIndices.count < needed && selectedIndices.count < cards.count {
            let rand = Int.random(in: 0..<cards.count)
            selectedIndices.insert(rand)
        }
        
        for index in selectedIndices {
            cards[index].isLit = true
        }
        
        // Re-schedule card timer to current level's window
        scheduleCardTimer()
    }

    private func scheduleCardTimer() {
        cardTimer?.invalidate()
        cardTimer = Timer.scheduledTimer(withTimeInterval: currentLevel.litWindow, repeats: false) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            DispatchQueue.main.async {
                // Deduct score as a miss penalty if cards go dark without being tapped
                let hadLit = self.cards.contains(where: { $0.isLit })
                if hadLit {
                    self.tapCount = max(0, self.tapCount - 1)
                    self.hapticTrigger = .warning
                }
                self.lightUpCards()
            }
        }
    }

    // MARK: - Tap Frenzy Gameplay Actions
    func tapButton() {
        guard state == .running, currentMode == .tapFrenzy else { return }

        if buttonMode == .penalty {
            multiplier = 1
            tapCount = max(0, tapCount - 5)
            lastTapDate = nil
            hapticTrigger = .error
            return
        }

        let now = Date()
        if let last = lastTapDate, now.timeIntervalSince(last) <= 0.5 {
            multiplier += 1
        } else {
            multiplier = 1
        }
        lastTapDate = now

        var points = multiplier
        switch buttonMode {
        case .bonus:
            points += 1
        case .normal, .penalty:
            break
        }

        if isDoublePointsActive {
            points *= 2
        }

        tapCount += points
        hapticTrigger = .medium
    }

    // MARK: - Light It Up Gameplay Actions
    func tapCard(at index: Int) {
        guard state == .running, currentMode == .lightItUp else { return }
        guard index >= 0 && index < cards.count else { return }
        
        if cards[index].isLit {
            // Correct tap!
            cards[index].isLit = false
            tapCount += 1
            hapticTrigger = .success
            
            // If all active lit cards are successfully cleared, trigger new ones immediately
            let anyLit = cards.contains(where: { $0.isLit })
            if !anyLit {
                lightUpCards()
            }
        } else {
            // Miss! Tapped dim card
            tapCount = max(0, tapCount - 1)
            hapticTrigger = .error
        }
    }

    // MARK: - Tap Frenzy Timer Management
    private func startTapFrenzyTimers() {
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            let dx = CGFloat.random(in: -120...120)
            let dy = CGFloat.random(in: -200...200)
            DispatchQueue.main.async {
                self.buttonOffset = CGSize(width: dx, height: dy)
            }
        }
        RunLoop.main.add(moveTimer!, forMode: .common)

        colorTimer?.invalidate()
        colorTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            DispatchQueue.main.async {
                switch self.buttonMode {
                case .normal:
                    self.buttonMode = .bonus
                case .bonus:
                    self.buttonMode = .penalty
                case .penalty:
                    self.buttonMode = .normal
                }
            }
        }
        RunLoop.main.add(colorTimer!, forMode: .common)

        doublePointsTimer?.invalidate()
        let fireIn = max(1.0, Double(Int.random(in: 2...8)))
        doublePointsTimer = Timer.scheduledTimer(withTimeInterval: fireIn, repeats: false) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            DispatchQueue.main.async {
                self.isDoublePointsActive = true
                self.hasUsedDoublePointsThisRound = true
                
                self.doublePointsEndTimer?.invalidate()
                self.doublePointsEndTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
                    self?.isDoublePointsActive = false
                }
            }
        }
        RunLoop.main.add(doublePointsTimer!, forMode: .common)
    }

    private func stopTapFrenzyTimers() {
        moveTimer?.invalidate(); moveTimer = nil
        colorTimer?.invalidate(); colorTimer = nil
        doublePointsTimer?.invalidate(); doublePointsTimer = nil
        doublePointsEndTimer?.invalidate(); doublePointsEndTimer = nil
    }

    func resetGame() {
        mainTimer?.invalidate()
        mainTimer = nil
        cardTimer?.invalidate()
        cardTimer = nil
        stopTapFrenzyTimers()

        state = .idle
        timeLeft = currentMode == .tapFrenzy ? 10.0 : 60.0
        tapCount = 0
        multiplier = 1
        lastTapDate = nil
        buttonOffset = .zero
        buttonScale = 1.0
        buttonMode = .normal
        isDoublePointsActive = false
        hasUsedDoublePointsThisRound = false
        
        cards.removeAll()
        isNewHighScore = false
        hapticTrigger = nil
    }

    deinit {
        mainTimer?.invalidate()
        cardTimer?.invalidate()
        stopTapFrenzyTimers()
    }
}
