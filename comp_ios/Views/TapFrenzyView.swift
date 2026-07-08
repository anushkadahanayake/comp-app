import SwiftUI

// Fallbacks in case shared files aren't compiled into this target yet
#if canImport(SwiftUI)
import Foundation

enum GameMode: String, Codable { case tapFrenzy }

@MainActor
final class TapFrenzyVM: ObservableObject {
    enum State { case idle, running, finished }
    enum ButtonMode { case normal, bonus, penalty }
    enum HapticTrigger { case success, error, warning, medium, light }

    @Published var state: State = .idle
    @Published var tapCount: Int = 0
    @Published var timeLeft: Double = 10.0
    @Published var buttonScale: CGFloat = 1.0
    @Published var buttonOffset: CGSize = .zero
    @Published var isDoublePointsActive: Bool = false
    @Published var multiplier: Int = 1
    @Published var isNewHighScore: Bool = false
    @Published var hapticTrigger: HapticTrigger? = nil

    var buttonMode: ButtonMode = .normal
    var currentMode: GameMode = .tapFrenzy

    private var timer: Timer?

    func startGame() {
        tapCount = 0
        timeLeft = 10.0
        multiplier = 1
        isDoublePointsActive = false
        buttonScale = 1.0
        buttonOffset = .zero
        isNewHighScore = false
        state = .running
        startTimer()
    }

    func resetGame() {
        state = .idle
        timeLeft = 10.0
        tapCount = 0
    }

    func tapButton() {
        guard state == .running else { return }
        tapCount += 1 * multiplier
        buttonScale = 0.9
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.buttonScale = 1.0
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self else { return }
            if self.state != .running { t.invalidate(); return }
            self.timeLeft = max(0, self.timeLeft - 0.1)
            if self.timeLeft <= 0 {
                t.invalidate()
                self.state = .finished
            }
        }
    }
}
#endif

struct TapFrenzyView: View {
    @StateObject private var vm = TapFrenzyVM()
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 24) {
                // Header displaying Scores
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("SCORE")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text("\(vm.tapCount)")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 4) {
                        Text("HIGH SCORE")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text("\(highScoreTapFrenzy)")
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // 10s countdown bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Time Remaining")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1fs", vm.timeLeft))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(vm.timeLeft <= 3.0 ? .red : .primary)
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { barProxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(vm.timeLeft <= 3.0 ? Color.red : Color.blue)
                                .frame(width: max(0, barProxy.size.width * CGFloat(vm.timeLeft) / 10.0), height: 10)
                                .animation(.linear(duration: 0.05), value: vm.timeLeft)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal)
                }

                // Play Area
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)

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
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.65)) {
                                vm.tapButton()
                            }
                        }) {
                            Circle()
                                .fill(gradient)
                                .frame(width: 160 * vm.buttonScale, height: 160 * vm.buttonScale)
                                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                        }
                        .disabled(vm.state == .finished)
                        .opacity(vm.state == .finished ? 0.15 : 1.0)
                        .offset(clampedOffset(for: vm.buttonOffset, containerSize: CGSize(width: proxy.size.width - 32, height: 320), buttonScale: vm.buttonScale))
                        .animation(.easeInOut(duration: 0.35), value: vm.buttonOffset)
                        .animation(.easeInOut(duration: 0.15), value: vm.buttonScale)
                    }

                    // Game Over Screen Overlay
                    if vm.state == .finished {
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
                                Text("High Score: \(highScoreTapFrenzy)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Button(action: {
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
                        .background(Color(.secondarySystemGroupedBackground).opacity(0.9))
                        .cornerRadius(24)
                        .transition(.opacity)
                    } else if vm.state == .idle {
                        // Game Start Button
                        Button(action: {
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
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal)

                // Multiplier and Double Points indicator
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
        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
        .onAppear {
            vm.currentMode = GameMode.tapFrenzy
            vm.resetGame()
        }
        .onChange(of: vm.state) { newState in
            if newState == .finished {
                DispatchQueue.main.async {
                    if vm.tapCount > highScoreTapFrenzy {
                        highScoreTapFrenzy = vm.tapCount
                        vm.isNewHighScore = true
                    } else {
                        vm.isNewHighScore = false
                    }
                }
            }
        }
        .onChange(of: vm.hapticTrigger) { trigger in
            guard let trigger = trigger else { return }
            switch trigger {
            case .success:
                triggerNotificationFeedback(type: .success)
            case .error:
                triggerNotificationFeedback(type: .error)
            case .warning:
                triggerNotificationFeedback(type: .warning)
            case .medium:
                triggerHapticFeedback(style: .medium)
            case .light:
                triggerHapticFeedback(style: .light)
            }
            DispatchQueue.main.async {
                vm.hapticTrigger = nil
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

    @MainActor private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    @MainActor private func triggerNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

#Preview {
    NavigationStack {
        TapFrenzyView()
    }
}
