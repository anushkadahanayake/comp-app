//
//  ContentView.swift
//  comp_ios
//
//  Created by ANUSHKA DAHANAYAKE on 2026-06-10.
//

import SwiftUI

struct ContentView: View {

    @StateObject var vm = GameViewModel()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Main content
                VStack(spacing: 20) {

                    // Scores at the top
                    Text("Score: \(vm.tapCount)")
                        .font(.largeTitle)
                        .bold()
                    Text("High Score: \(vm.highScore)")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    // Timer
                    Text("Time: \(vm.timeLeft)")
                        .font(.title)

                    // Play area
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        // Empty center; button is layered in outer ZStack and positioned using this frame
                    }
                    .frame(height: 320)

                    // Controls
                    if vm.state == .idle {
                        Button("Start") {
                            vm.startGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    // Multiplier and double-points indicator
                    if vm.state == .running {
                        HStack(spacing: 12) {
                            Text("×\(vm.multiplier)")
                                .font(.title2)
                                .bold()
                            if vm.isDoublePointsActive {
                                Text("DOUBLE POINTS!")
                                    .font(.headline)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }

                    Spacer()
                }

                // Moving game button constrained to play area
                VStack(spacing: 0) { // mirror main layout spacing to align with play area position
                    // Header spacing equivalent to content above play area
                    VStack(spacing: 20) {
                        // Scores and timer heights approximated by layout above
                        Text("")
                            .hidden()
                        Text("")
                            .hidden()
                        Text("")
                            .hidden()
                    }
                    // The play area overlay
                    ZStack {
                        Color.clear
                    }
                    .frame(height: 320)
                    .overlay(
                        Group {
                            let color: Color = {
                                switch vm.buttonMode {
                                case .normal: return .blue
                                case .bonus: return .green
                                case .penalty: return .gray
                                }
                            }()

                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    vm.tapButton()
                                }
                            }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 160 * vm.buttonScale, height: 160 * vm.buttonScale)
                            }
                            .disabled(vm.state != .running || vm.timeLeft <= 0)
                        }
                        .offset(vm.buttonOffset.clamped(to: CGSize(width: proxy.size.width - 32, height: 320)))
                        .animation(.easeInOut(duration: 0.35), value: vm.buttonOffset)
                        .animation(.easeInOut(duration: 0.2), value: vm.buttonScale)
                    )

                    Spacer() // push remaining content below
                }
            }
            .padding()
            .alert("Round Over", isPresented: .constant(vm.state == .finished)) {
                Button("Restart", role: .none) {
                    vm.resetGame()
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Final Score: \(vm.tapCount)\nHigh Score: \(vm.highScore)")
            }
        }
    }
}
#Preview {
    ContentView()
}

private extension CGSize {
    func clamped(to size: CGSize) -> CGSize {
        // Clamp offset so the moving button stays within the given size bounds.
        let half: CGFloat = 80 // tighter margin so scaled button stays inside
        let maxX = max(0, size.width / 2 - half)
        let maxY = max(0, size.height / 2 - half)
        let clampedW = min(max(self.width, -maxX), maxX)
        let clampedH = min(max(self.height, -maxY), maxY)
        return CGSize(width: clampedW, height: clampedH)
    }
}
