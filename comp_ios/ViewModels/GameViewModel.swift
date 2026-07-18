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
    
    // Settings: Round duration (30s / 60s / 90s)
    @AppStorage("RoundDurationSetting") var roundDurationSetting: Double = 60.0
    
    // Timer and Score state (using Double for high-precision progress bar rendering)
    @Published var timeLeft: Double = 10.0
    @Published var tapCount: Int = 0
    @Published var isNewHighScore: Bool = false

    // Lives System (Starts at 3, decremented on wrong taps or expired card misses)
    @Published var lives: Int = 3
    
    // Level Up visual overlay flag
    @Published var showLevelUpAlert: Bool = false

    // Tap Frenzy Game State
    @Published var multiplier: Int = 1
    @Published var lastTapDate: Date? = nil
    @Published var buttonOffset: CGSize = .zero
    @Published var buttonScale: CGFloat = 1.0
    /// Score-based stage inside one Tap Frenzy round (1…7).
    @Published var tapFrenzyLevel: Int = 1
    /// Progress-bar denominator; grows when bonus time is earned (capped).
    @Published var tapFrenzyTimeCeiling: Double = 10.0
    /// Short “+1.5s” / level banner text.
    @Published var tapFrenzyBonusBanner: String?

    enum ButtonMode { case normal, bonus, penalty }
    @Published var buttonMode: ButtonMode = .normal
    @Published var isDoublePointsActive: Bool = false
    private var hasUsedDoublePointsThisRound: Bool = false
    private var lastComboTimeBonusAtMultiplier = 0
    private let tapFrenzyBaseTime = 10.0
    private let tapFrenzyMaxTime = 20.0
    private let tapFrenzyMaxLevel = 7
    /// Score thresholds for levels 1…7 (index = level − 1).
    private let tapFrenzyLevelThresholds = [0, 40, 100, 180, 280, 400, 550]

    // Light It Up Game State
    @Published var cards: [Card] = []
    @Published var currentLevel: Level = .l1
    @Published var lightItUpBonusBanner: String?
    private let lightItUpBonusSeconds = 3.0
    
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
            timeLeft = tapFrenzyBaseTime
            tapFrenzyTimeCeiling = tapFrenzyBaseTime
            tapFrenzyLevel = 1
            tapFrenzyBonusBanner = nil
            lastComboTimeBonusAtMultiplier = 0
            multiplier = 1
            lastTapDate = nil
            buttonOffset = .zero
            buttonScale = 1.0
            buttonMode = .normal
            isDoublePointsActive = false
            hasUsedDoublePointsThisRound = false
            showLevelUpAlert = false
            
            startTapFrenzyTimers()
            
        case .lightItUp:
            timeLeft = roundDurationSetting
            lives = 3
            showLevelUpAlert = false
            lightItUpBonusBanner = nil
            currentLevel = .l1
            
            initializeCards(for: .l1)
            lightUpCards()
            
        case .quizRush:
            break
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
            let drain: Double
            if currentMode == .tapFrenzy, tapFrenzyLevel >= 5 {
                // Level 5+: slightly faster drain so bonus time cannot sustain forever.
                drain = 0.05 * (1.0 + 0.08 * Double(tapFrenzyLevel - 4))
            } else {
                drain = 0.05
            }
            timeLeft = max(0.0, timeLeft - drain)
            
            if currentMode == .tapFrenzy {
                let ceiling = max(tapFrenzyTimeCeiling, 0.1)
                let fraction = timeLeft / ceiling
                let minScale = max(0.22, 0.42 - Double(tapFrenzyLevel - 1) * 0.028)
                self.buttonScale = CGFloat(max(minScale, minScale + (1.0 - minScale) * fraction))
            } else if currentMode == .lightItUp {
                // Determine level progression dynamically based on roundDurationSetting
                let elapsed = roundDurationSetting - timeLeft
                let newLevel: Level
                if elapsed < roundDurationSetting * 0.25 {
                    newLevel = .l1
                } else if elapsed < roundDurationSetting * 0.50 {
                    newLevel = .l2
                } else if elapsed < roundDurationSetting * 0.75 {
                    newLevel = .l3
                } else {
                    newLevel = .l4
                }
                
                if newLevel != currentLevel {
                    currentLevel = newLevel
                    // Rebuild cards grid for the new level
                    initializeCards(for: newLevel)
                    lightUpCards()
                    
                    // Flash Level Up banner overlay
                    showLevelUpAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.showLevelUpAlert = false
                    }
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

        let saveLocation = UserDefaults.standard.object(forKey: "SaveLocationWithSessions") as? Bool ?? true
        if saveLocation {
            LocationService.shared.refreshLocation()
        }
        let lat = saveLocation ? LocationService.shared.currentLatitude : nil
        let lon = saveLocation ? LocationService.shared.currentLongitude : nil
        SessionHistoryManager.shared.saveSession(
            mode: currentMode.rawValue,
            score: tapCount,
            latitude: lat,
            longitude: lon
        )
    }

    private func initializeCards(for level: Level) {
        cards = (0..<level.cardCount).map { Card(id: $0) }
    }

    func lightUpCards() {
        guard state == .running else { return }
        
        // Clear all active lit states
        for i in 0..<cards.count {
            cards[i].isLit = false
            cards[i].isBonusTime = false
        }
        
        // Pick random unique indices to light up based on Level's active lit count
        let needed = currentLevel.activeLitCount
        var selectedIndices: [Int] = []
        while selectedIndices.count < needed && selectedIndices.count < cards.count {
            let rand = Int.random(in: 0..<cards.count)
            if !selectedIndices.contains(rand) {
                selectedIndices.append(rand)
            }
        }
        
        for index in selectedIndices {
            cards[index].isLit = true
        }

        // When 2 cards light: one normal score card + one bonus-time card.
        if selectedIndices.count >= 2 {
            let bonusIndex = selectedIndices.randomElement()!
            cards[bonusIndex].isBonusTime = true
        }
        
        // Re-schedule card timer to current level's window
        scheduleCardTimer()
    }

    private func scheduleCardTimer() {
        cardTimer?.invalidate()
        cardTimer = Timer.scheduledTimer(withTimeInterval: currentLevel.litWindow, repeats: false) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            DispatchQueue.main.async {
                // If cards went dark without being tapped, lose 1 life!
                let hadLit = self.cards.contains(where: { $0.isLit })
                if hadLit {
                    self.lives = max(0, self.lives - 1)
                    self.hapticTrigger = .error
                    
                    if self.lives <= 0 {
                        self.endGame()
                        return
                    }
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
            lastComboTimeBonusAtMultiplier = 0
            tapCount = max(0, tapCount - 5)
            lastTapDate = nil
            hapticTrigger = .error
            return
        }

        let now = Date()
        var didCombo = false
        if let last = lastTapDate, now.timeIntervalSince(last) <= 0.5 {
            multiplier += 1
            didCombo = true
        } else {
            multiplier = 1
            lastComboTimeBonusAtMultiplier = 0
        }
        lastTapDate = now

        var points = multiplier
        var timeBonus: Double = 0

        switch buttonMode {
        case .bonus:
            points += 1
            timeBonus += 0.5 // green window → extra time
        case .normal, .penalty:
            break
        }

        // Combo milestones ×3 / ×5 / ×7 only (no free time after ×7).
        if didCombo,
           [3, 5, 7].contains(multiplier),
           multiplier != lastComboTimeBonusAtMultiplier {
            timeBonus += 0.4
            lastComboTimeBonusAtMultiplier = multiplier
        }

        if isDoublePointsActive {
            points *= 2
        }

        tapCount += points
        if timeBonus > 0 {
            grantTapFrenzyTime(timeBonus, banner: String(format: "+%.1fs", timeBonus))
        }
        evaluateTapFrenzyLevel()
        hapticTrigger = .medium
    }

    private func evaluateTapFrenzyLevel() {
        var newLevel = 1
        for (index, threshold) in tapFrenzyLevelThresholds.enumerated() where tapCount >= threshold {
            newLevel = index + 1
        }
        newLevel = min(tapFrenzyMaxLevel, newLevel)
        guard newLevel > tapFrenzyLevel else { return }

        tapFrenzyLevel = newLevel
        grantTapFrenzyTime(1.0, banner: "LEVEL \(newLevel)! +1s")
        showLevelUpAlert = true
        hapticTrigger = .success
        // Faster movement / mode swaps at higher levels.
        startTapFrenzyTimers()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.showLevelUpAlert = false
        }
    }

    private func grantTapFrenzyTime(_ seconds: Double, banner: String) {
        let room = tapFrenzyMaxTime - timeLeft
        guard room > 0.05 else { return }
        let added = min(seconds, room)
        timeLeft += added
        tapFrenzyTimeCeiling = min(tapFrenzyMaxTime, max(tapFrenzyTimeCeiling, timeLeft))
        tapFrenzyBonusBanner = banner
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.tapFrenzyBonusBanner == banner {
                self?.tapFrenzyBonusBanner = nil
            }
        }
    }

    private var tapFrenzyMoveInterval: TimeInterval {
        // Levels 1–7: ~2.0s → ~0.55s
        max(0.55, 2.0 - Double(tapFrenzyLevel - 1) * 0.24)
    }

    private var tapFrenzyColorInterval: TimeInterval {
        // Levels 1–7: ~3.0s → ~0.9s (penalty windows more frequent late-game)
        max(0.9, 3.0 - Double(tapFrenzyLevel - 1) * 0.35)
    }

    // MARK: - Light It Up Gameplay Actions
    func tapCard(at index: Int) {
        guard state == .running, currentMode == .lightItUp else { return }
        guard index >= 0 && index < cards.count else { return }
        
        if cards[index].isLit {
            let wasBonus = cards[index].isBonusTime
            cards[index].isLit = false
            cards[index].isBonusTime = false
            tapCount += wasBonus ? 2 : 1
            hapticTrigger = .success

            if wasBonus {
                grantLightItUpTime(lightItUpBonusSeconds)
            }
            
            // If all active lit cards are successfully cleared, trigger new ones immediately
            let anyLit = cards.contains(where: { $0.isLit })
            if !anyLit {
                lightUpCards()
            }
        } else {
            // Miss! Tapped dim card - deduct 1 life
            lives = max(0, lives - 1)
            hapticTrigger = .error
            
            if lives <= 0 {
                endGame()
            }
        }
    }

    private func grantLightItUpTime(_ seconds: Double) {
        let maxTime = roundDurationSetting + 20.0
        let room = maxTime - timeLeft
        guard room > 0.05 else {
            lightItUpBonusBanner = "TIME MAX"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                if self?.lightItUpBonusBanner == "TIME MAX" {
                    self?.lightItUpBonusBanner = nil
                }
            }
            return
        }
        let added = min(seconds, room)
        timeLeft += added
        let banner = String(format: "+%.0fs TIME!", added)
        lightItUpBonusBanner = banner
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            if self?.lightItUpBonusBanner == banner {
                self?.lightItUpBonusBanner = nil
            }
        }
    }

    // MARK: - Tap Frenzy Timer Management
    private func startTapFrenzyTimers() {
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: tapFrenzyMoveInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .running else { return }
            let spread = 100 + CGFloat(self.tapFrenzyLevel) * 16
            let dx = CGFloat.random(in: -spread...spread)
            let dy = CGFloat.random(in: -(spread + 40)...(spread + 40))
            DispatchQueue.main.async {
                self.buttonOffset = CGSize(width: dx, height: dy)
            }
        }
        RunLoop.main.add(moveTimer!, forMode: .common)

        colorTimer?.invalidate()
        colorTimer = Timer.scheduledTimer(withTimeInterval: tapFrenzyColorInterval, repeats: true) { [weak self] _ in
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

        // Only schedule the one-shot double-points event once per round.
        if !hasUsedDoublePointsThisRound && doublePointsTimer == nil && !isDoublePointsActive {
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
        timeLeft = currentMode == .tapFrenzy ? tapFrenzyBaseTime : roundDurationSetting
        tapCount = 0
        lives = 3
        showLevelUpAlert = false
        multiplier = 1
        lastTapDate = nil
        buttonOffset = .zero
        buttonScale = 1.0
        buttonMode = .normal
        isDoublePointsActive = false
        hasUsedDoublePointsThisRound = false
        tapFrenzyLevel = 1
        tapFrenzyTimeCeiling = tapFrenzyBaseTime
        tapFrenzyBonusBanner = nil
        lastComboTimeBonusAtMultiplier = 0
        lightItUpBonusBanner = nil
        
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
