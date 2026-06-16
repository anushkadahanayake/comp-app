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

                    // Moving game button directly inside play area
                    if vm.state == .running {
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
                        .disabled(vm.timeLeft <= 0)
                        .offset(clampedOffset(for: vm.buttonOffset, containerSize: CGSize(width: proxy.size.width - 32, height: 320), buttonScale: vm.buttonScale))
                        .animation(.easeInOut(duration: 0.35), value: vm.buttonOffset)
                        .animation(.easeInOut(duration: 0.2), value: vm.buttonScale)
                    }
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))

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
            .padding()
            .alert("Round Over", isPresented: .constant(vm.state == .finished)) {
                Button("Restart") {
                    vm.resetGame()
                }
            } message: {
                Text("Final Score: \(vm.tapCount)\nHigh Score: \(vm.highScore)")
            }
        }
    }

    private func clampedOffset(for offset: CGSize, containerSize: CGSize, buttonScale: CGFloat) -> CGSize {
        let buttonSize = 160 * buttonScale
        let maxX = max(0, (containerSize.width - buttonSize) / 2)
        let maxY = max(0, (containerSize.height - buttonSize) / 2)
        let clampedW = min(max(offset.width, -maxX), maxX)
        let clampedH = min(max(offset.height, -maxY), maxY)
        return CGSize(width: clampedW, height: clampedH)
    }
}
#Preview {
    ContentView()
}

