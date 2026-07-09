import SwiftUI
import Combine
import CoreLocation

struct FloatingScore: Identifiable {
    let id: UUID
    let text: String
    let x: CGFloat
    let y: CGFloat
    let color: Color
}

struct TapFrenzyView: View {
    @StateObject private var vm = GameViewModel()
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    @State private var floatingScores: [FloatingScore] = []
    @State private var pulseOuterRing = false
    @State private var tapScaleEffect: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ElectricCyberPlasmaBackground()
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header displaying Scores
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("SCORE")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundStyle(.cyan)
                            Text("\(vm.tapCount)")
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.black)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.08, green: 0.08, blue: 0.15))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1.5)
                        )
                        
                        VStack(spacing: 4) {
                            Text("HIGH SCORE")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundStyle(.purple)
                            Text("\(highScoreTapFrenzy)")
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.black)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.08, green: 0.08, blue: 0.15))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // 10s countdown bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Time Remaining")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.1fs", vm.timeLeft))
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(vm.timeLeft <= 3.0 ? .red : .cyan)
                        }
                        .padding(.horizontal)
                        
                        GeometryReader { barProxy in
                            let barWidth = barProxy.size.width
                            let progressWidth = max(0.0, barWidth * CGFloat(vm.timeLeft) / 10.0)
                            
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 10)
                                
                                Capsule()
                                    .fill(vm.timeLeft <= 3.0 ? Color.red : Color.cyan)
                                    .frame(width: progressWidth, height: 10)
                                    .animation(.linear(duration: 0.05), value: vm.timeLeft)
                                    .shadow(color: (vm.timeLeft <= 3.0 ? Color.red : Color.cyan).opacity(0.5), radius: 6)
                            }
                        }
                        .frame(height: 10)
                        .padding(.horizontal)
                    }

                    // Play Area
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(red: 0.05, green: 0.05, blue: 0.10).opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(vm.buttonMode == .penalty ? Color.gray.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1.5)
                            )
                            .shadow(color: (vm.buttonMode == .penalty ? Color.gray : Color.cyan).opacity(0.05), radius: 10)

                        // Target button core
                        if vm.state == .running || vm.state == .finished {
                            let baseColor: Color = {
                                switch vm.buttonMode {
                                case .normal: return .cyan
                                case .bonus: return .green
                                case .penalty: return .gray
                                }
                            }()
                            
                            let gradient = RadialGradient(
                                colors: [baseColor, baseColor.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 90
                            )
                            
                            let combinedButtonScale = vm.buttonScale * tapScaleEffect

                            ZStack {
                                // Breathing Glow Outer Ring
                                Circle()
                                    .stroke(baseColor.opacity(0.4), lineWidth: 3)
                                    .frame(width: 175 * combinedButtonScale, height: 175 * combinedButtonScale)
                                    .scaleEffect(pulseOuterRing ? 1.08 : 0.96)
                                    .shadow(color: baseColor.opacity(0.6), radius: 15)
                                
                                // Center Glowing Button
                                Button(action: {
                                    withAnimation(.spring(response: 0.15, dampingFraction: 0.4)) {
                                        tapScaleEffect = 0.85
                                    }
                                    
                                    vm.tapButton()
                                    
                                    // Spawning floating score particles
                                    let scoreText: String = {
                                        if vm.buttonMode == .penalty {
                                            return "-5"
                                        }
                                        var pts = vm.multiplier
                                        if vm.buttonMode == .bonus {
                                            pts += 1
                                        }
                                        if vm.isDoublePointsActive {
                                            pts *= 2
                                        }
                                        return "+\(pts)"
                                    }()
                                    
                                    let scoreColor: Color = {
                                        switch vm.buttonMode {
                                        case .normal: return .cyan
                                        case .bonus: return .green
                                        case .penalty: return .gray
                                        }
                                    }()
                                    
                                    let newScore = FloatingScore(
                                        id: UUID(),
                                        text: scoreText,
                                        x: CGFloat.random(in: -40...40),
                                        y: CGFloat.random(in: -40...40),
                                        color: scoreColor
                                    )
                                    floatingScores.append(newScore)
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                                            tapScaleEffect = 1.0
                                        }
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        floatingScores.removeAll(where: { $0.id == newScore.id })
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(gradient)
                                            .frame(width: 140 * combinedButtonScale, height: 140 * combinedButtonScale)
                                        
                                        Circle()
                                            .stroke(baseColor, lineWidth: 2)
                                            .frame(width: 140 * combinedButtonScale, height: 140 * combinedButtonScale)
                                        
                                        Image(systemName: vm.buttonMode == .penalty ? "exclamationmark.triangle.fill" : (vm.buttonMode == .bonus ? "plus.circle.fill" : "bolt.fill"))
                                            .font(.title)
                                            .foregroundStyle(.white)
                                            .shadow(color: .white.opacity(0.5), radius: 5)
                                    }
                                }
                                .disabled(vm.state == .finished)
                                .opacity(vm.state == .finished ? 0.15 : 1.0)
                            }
                            .offset(clampedOffset(for: vm.buttonOffset, containerSize: CGSize(width: proxy.size.width - 32, height: 320), buttonScale: combinedButtonScale))
                            .animation(.spring(response: 0.38, dampingFraction: 0.7), value: vm.buttonOffset)
                        }
                        
                        // Floating score particles container
                        ForEach(floatingScores) { score in
                            Text(score.text)
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.black)
                                .foregroundStyle(score.color)
                                .shadow(color: score.color.opacity(0.8), radius: 8)
                                .offset(x: score.x, y: score.y - 60)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.5)),
                                    removal: .opacity.combined(with: .move(edge: .top))
                                ))
                        }

                        // Game Over Screen Overlay
                        if vm.state == .finished {
                            VStack(spacing: 20) {
                                Text("GAME OVER")
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(
                                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .shadow(color: .red.opacity(0.4), radius: 8)
                                
                                VStack(spacing: 4) {
                                    Text("Final Score")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                    Text("\(vm.tapCount)")
                                        .font(.system(.largeTitle, design: .rounded))
                                        .fontWeight(.black)
                                        .foregroundStyle(.white)
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
                                        .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 0)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text("High Score: \(highScoreTapFrenzy)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.secondary)
                                }
                                
                                HStack(spacing: 16) {
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
                                            .padding(.horizontal, 28)
                                            .background(
                                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                            )
                                            .clipShape(Capsule())
                                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    ShareLink(item: "I just scored \(vm.tapCount) on Tap Frenzy — beat that!") {
                                        Label("", systemImage: "square.and.arrow.up")
                                            .font(.system(.headline, design: .rounded))
                                            .bold()
                                            .foregroundStyle(.white)
                                            .padding(.all, 12)
                                            .background(Color(red: 0.12, green: 0.12, blue: 0.22))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(red: 0.05, green: 0.05, blue: 0.10).opacity(0.95))
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
                                    .fontWeight(.black)
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 48)
                                    .background(
                                        LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .cyan.opacity(0.4), radius: 12, x: 0, y: 0)
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
                                    .foregroundStyle(.white)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                            
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
                                    .shadow(color: .orange.opacity(0.5), radius: 10, x: 0, y: 0)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .transition(.opacity)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Tap Frenzy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(.cyan)
            }
        }
        .onAppear {
            vm.currentMode = GameMode.tapFrenzy
            vm.resetGame()
            
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseOuterRing = true
            }
        }
        .onChange(of: vm.state) { _, newState in
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
        .onChange(of: vm.hapticTrigger) { _, trigger in
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

// MARK: - Electric Cyber Plasma Background
struct ElectricCyberPlasmaBackground: View {
    @State private var animate = false
    
    private let sparks = (0..<15).map { _ in
        Spark(
            id: UUID(),
            x: CGFloat.random(in: 10...380),
            size: CGFloat.random(in: 4...8),
            speed: Double.random(in: 4.0...7.0),
            delay: Double.random(in: 0.0...3.0)
        )
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.01, green: 0.02, blue: 0.05)
                .ignoresSafeArea()
            
            ZStack {
                // Blob 1 (Electric Blue)
                Circle()
                    .fill(Color.blue.opacity(0.25))
                    .frame(width: 320, height: 320)
                    .offset(x: animate ? -60 : 60, y: animate ? -70 : 70)
                    .blur(radius: 55)
                
                // Blob 2 (Cyber Cyan)
                Circle()
                    .fill(Color.cyan.opacity(0.20))
                    .frame(width: 280, height: 280)
                    .offset(x: animate ? 80 : -80, y: animate ? 90 : -90)
                    .blur(radius: 45)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
            
            // Fast sparks
            GeometryReader { proxy in
                ZStack {
                    ForEach(sparks) { spark in
                        SparkItemView(spark: spark, containerHeight: proxy.size.height)
                    }
                }
            }
        }
    }
}

struct Spark: Identifiable {
    let id: UUID
    let x: CGFloat
    let size: CGFloat
    let speed: Double
    let delay: Double
}

struct SparkItemView: View {
    let spark: Spark
    let containerHeight: CGFloat
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0.8
    
    var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.cyan.opacity(0.6))
            .frame(width: 2, height: spark.size)
            .position(x: spark.x, y: containerHeight + 20 - offset)
            .opacity(opacity)
            .shadow(color: .cyan.opacity(0.8), radius: 4)
            .onAppear {
                withAnimation(
                    .linear(duration: spark.speed)
                    .repeatForever(autoreverses: false)
                    .delay(spark.delay)
                ) {
                    offset = containerHeight + 100
                    opacity = 0.0
                }
            }
    }
}
