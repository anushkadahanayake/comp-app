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
    
    // High scores per mode, persisted in UserDefaults
    @Published var highScoreTapFrenzy: Int = {
        let saved = UserDefaults.standard.integer(forKey: "HighScore_TapFrenzy")
        if saved == 0 {
            // Week 1 legacy key migration fallback
            let old = UserDefaults.standard.integer(forKey: "HighScoreKey")
            if old > 0 {
                UserDefaults.standard.set(old, forKey: "HighScore_TapFrenzy")
                return old
            }
        }
        return saved
    }() {
        didSet {
            UserDefaults.standard.set(highScoreTapFrenzy, forKey: "HighScore_TapFrenzy")
        }
    }
    
    @Published var highScoreLightItUp: Int = UserDefaults.standard.integer(forKey: "HighScore_LightItUp") {
        didSet {
            UserDefaults.standard.set(highScoreLightItUp, forKey: "HighScore_LightItUp")
        }
    }
    
    // Computed helper for the active game mode's high score
    var currentHighScore: Int {
        switch currentMode {
        case .tapFrenzy: return highScoreTapFrenzy
        case .lightItUp: return highScoreLightItUp
        }
    }
    
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
    @Published var activeCards: Set<Int> = []
    private var cardExpirations: [Int: Date] = [:]
    private var lastLevel: Int = 1
    
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
    private var moveTimer: Timer?
    private var colorTimer: Timer?
    private var doublePointsTimer: Timer?
    private var doublePointsEndTimer: Timer?

    // Computed properties for Light It Up Level & Cards
    var currentLevel: Int {
        guard currentMode == .lightItUp else { return 1 }
        let elapsed = 60.0 - timeLeft
        if elapsed < 15.0 {
            return 1
        } else if elapsed < 30.0 {
            return 2
        } else if elapsed < 45.0 {
            return 3
        } else {
            return 4
        }
    }
    
    var currentModeMaxCards: Int {
        switch currentLevel {
        case 1: return 3
        case 2: return 4
        case 3: return 6
        case 4: return 9
        default: return 3
        }
    }
    
    var currentLitWindow: TimeInterval {
        switch currentLevel {
        case 1: return 1.5
        case 2: return 1.2
        case 3: return 1.0
        case 4: return 0.8
        default: return 1.5
        }
    }
    
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
            activeCards.removeAll()
            cardExpirations.removeAll()
            lastLevel = 1
            
            ensureActiveCards()
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
                // Gradually shrink the scale of the Tap Frenzy button
                let fraction = timeLeft / 10.0
                self.buttonScale = max(0.4, 0.4 + 0.6 * fraction)
            } else if currentMode == .lightItUp {
                // Check if level has progressed and we need to rebuild grid/expirations
                let newLevel = self.currentLevel
                if newLevel != self.lastLevel {
                    self.lastLevel = newLevel
                    self.activeCards.removeAll()
                    self.cardExpirations.removeAll()
                    self.ensureActiveCards()
                }
                
                // Check expired cards in Light It Up
                let now = Date()
                var expiredIndices: [Int] = []
                for (index, expiration) in self.cardExpirations {
                    if now >= expiration {
                        expiredIndices.append(index)
                    }
                }
                
                if !expiredIndices.isEmpty {
                    for index in expiredIndices {
                        self.activeCards.remove(index)
                        self.cardExpirations.removeValue(forKey: index)
                    }
                    self.tapCount = max(0, self.tapCount - 1) // Miss penalty
                    self.hapticTrigger = .warning
                    self.ensureActiveCards()
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
        stopTapFrenzyTimers()
        
        state = .finished
        isDoublePointsActive = false
        activeCards.removeAll()
        cardExpirations.removeAll()
        
        // Save and verify high score achievements
        switch currentMode {
        case .tapFrenzy:
            if tapCount > highScoreTapFrenzy {
                highScoreTapFrenzy = tapCount
                isNewHighScore = true
            }
        case .lightItUp:
            if tapCount > highScoreLightItUp {
                highScoreLightItUp = tapCount
                isNewHighScore = true
            }
        }
        
        hapticTrigger = .warning
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
        
        if activeCards.contains(index) {
            // Correct tap!
            activeCards.remove(index)
            cardExpirations.removeValue(forKey: index)
            tapCount += 1
            hapticTrigger = .success
            
            ensureActiveCards()
        } else {
            // Incorrect tap!
            tapCount = max(0, tapCount - 1)
            hapticTrigger = .error
        }
    }

    func ensureActiveCards() {
        let maxCards = currentModeMaxCards
        let needed = currentLevel == 4 ? 2 : 1
        
        while activeCards.count < needed {
            let available = Array(0..<maxCards).filter { !activeCards.contains($0) }
            if let randomVal = available.randomElement() {
                activeCards.insert(randomVal)
                cardExpirations[randomVal] = Date().addingTimeInterval(currentLitWindow)
            } else {
                break
            }
        }
    }

    // MARK: - Tap Frenzy Timer Management
    private func startTapFrenzyTimers() {
        // Move Timer (every 2 seconds)
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

        // Color Mode Timer (every 3 seconds)
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

        // Double Points Timer (random start, lasts 2s)
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
        
        activeCards.removeAll()
        cardExpirations.removeAll()
        isNewHighScore = false
        hapticTrigger = nil
    }

    deinit {
        mainTimer?.invalidate()
        stopTapFrenzyTimers()
    }
}
