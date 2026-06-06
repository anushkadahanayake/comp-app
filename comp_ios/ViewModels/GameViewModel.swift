//
//  GameViewModel.swift
//  comp_ios
//
//  Created by ANUSHKA DAHANAYAKE on 2026-06-10.
//

import Foundation
import SwiftUI

class GameViewModel: ObservableObject {

    @Published var timeLeft: Int = 10
    @Published var tapCount: Int = 0
    @Published var state: GameState = .idle

    private var timer: Timer?

    func startGame() {
        state = .running
        timeLeft = 10
        tapCount = 0

        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.tick()
        }
    }

    func tapButton() {
        if state == .running {
            tapCount += 1
        }
    }

    private func tick() {
        guard state == .running else { return }

        if timeLeft > 0 {
            timeLeft -= 1
        }

        if timeLeft == 0 {
            endGame()
        }
    }

    func endGame() {
        state = .finished
        timer?.invalidate()
        timer = nil
    }

    func resetGame() {
        state = .idle
        timeLeft = 10
        tapCount = 0
        timer?.invalidate()
        timer = nil
    }
}
