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
            VStack(spacing: 24) {
                // Scores panel
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("SCORE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text("\(vm.tapCount)")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    VStack(spacing: 4) {
                        Text("HIGH SCORE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text("\(vm.highScore)")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Timer bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Time Remaining")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(vm.timeLeft)s")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(vm.timeLeft <= 3 ? .red : .primary)
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { barProxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(vm.timeLeft <= 3 ? Color.red : Color.blue)
                                .frame(width: max(0, barProxy.size.width * CGFloat(vm.timeLeft) / 10.0), height: 10)
                                .animation(.linear(duration: 1.0), value: vm.timeLeft)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal)
                }

                // Play area
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)

                    // Moving game button directly inside play area
                    if vm.state == .running || vm.state == .finished {
                        let gradient: LinearGradient = {
                            switch vm.buttonMode {
                            case .normal:
                                return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            case .bonus:
                                return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                            case .penalty:
                                return LinearGradient(colors: [.gray, Color(.systemGray3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            }
                        }()

                        Button(action: {
                            // Trigger haptics depending on mode
                            switch vm.buttonMode {
                            case .normal:
                                triggerHapticFeedback(style: .medium)
                            case .bonus:
                                triggerHapticFeedback(style: .light)
                            case .penalty:
                                triggerNotificationFeedback(type: .error)
                            }

                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                vm.tapButton()
                            }
                        }) {
                            Circle()
                                .fill(gradient)
                                .frame(width: 160 * vm.buttonScale, height: 160 * vm.buttonScale)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }
                        .disabled(vm.state == .finished)
                        .opacity(vm.state == .finished ? 0.15 : 1.0)
                        .offset(clampedOffset(for: vm.buttonOffset, containerSize: CGSize(width: proxy.size.width - 32, height: 320), buttonScale: vm.buttonScale))
                        .animation(.easeInOut(duration: 0.35), value: vm.buttonOffset)
                        .animation(.easeInOut(duration: 0.2), value: vm.buttonScale)
                    }

                    if vm.state == .finished {
                        // Game Over Screen Overlay
                        VStack(spacing: 16) {
                            Text("GAME OVER")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.black)
                                .foregroundStyle(
                                    LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                )
                            
                            VStack(spacing: 4) {
                                Text("Final Score")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Text("\(vm.tapCount)")
                                    .font(.system(.largeTitle, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                            }
                            
                            if vm.isNewHighScore {
                                Text("🎉 NEW HIGH SCORE! 🎉")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 16)
                                    .background(
                                        LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("High Score: \(vm.highScore)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button(action: {
                                triggerNotificationFeedback(type: .success)
                                withAnimation {
                                    vm.startGame()
                                }
                            }) {
                                Text("Play Again")
                                    .font(.system(.headline, design: .rounded))
                                    .bold()
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 36)
                                    .background(
                                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.85))
                        .cornerRadius(20)
                        .transition(.opacity)
                    } else if vm.state == .idle {
                        // Game start CTA
                        Button(action: {
                            triggerNotificationFeedback(type: .success)
                            withAnimation {
                                vm.startGame()
                            }
                        }) {
                            Text("START")
                                .font(.system(.headline, design: .rounded))
                                .bold()
                                .foregroundStyle(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 48)
                                .background(
                                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                // Multiplier and double-points indicator
                if vm.state == .running {
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.yellow)
                            Text("×\(vm.multiplier)")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Capsule())
                        
                        if vm.isDoublePointsActive {
                            Text("DOUBLE POINTS!")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(
                                    LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 3)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .transition(.opacity)
                }

                Spacer()
            }
            .padding(.vertical)
            .onChange(of: vm.state) { newState in
                if newState == .finished {
                    triggerNotificationFeedback(type: .warning)
                }
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

    private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private func triggerNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

#Preview {
    ContentView()
}
