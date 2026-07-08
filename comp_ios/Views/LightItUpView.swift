import SwiftUI

struct LightItUpView: View {
    @StateObject private var vm = GameViewModel()
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    // Grid columns layout based on the level
    private var columns: [GridItem] {
        switch vm.currentLevel {
        case .l1:
            // 3 cards (1 row of 3)
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        case .l2:
            // 4 cards (2x2 grid)
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
        case .l3:
            // 6 cards (2x3 grid)
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        case .l4:
            // 9 cards (3x3 grid)
            return Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        }
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 24) {
                // Header displaying Scores & Lives System
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
                        Text("LIVES")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            ForEach(1...3, id: \.self) { heartIndex in
                                Image(systemName: heartIndex <= vm.lives ? "heart.fill" : "heart")
                                    .font(.system(size: 16))
                                    .foregroundStyle(heartIndex <= vm.lives ? .red : .gray.opacity(0.4))
                                    .scaleEffect(heartIndex <= vm.lives ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: vm.lives)
                            }
                        }
                        .frame(height: 24)
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
                        Text("\(highScoreLightItUp)")
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
                
                // Countdown progress bar based on roundDurationSetting
                VStack(spacing: 8) {
                    HStack {
                        Text("Round Time")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1fs", vm.timeLeft))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(vm.timeLeft <= 10.0 ? .red : .primary)
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { barProxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(vm.timeLeft <= 10.0 ? Color.red : Color.orange)
                                .frame(width: max(0, barProxy.size.width * CGFloat(vm.timeLeft) / CGFloat(vm.roundDurationSetting)), height: 10)
                                .animation(.linear(duration: 0.05), value: vm.timeLeft)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal)
                }
                
                // Active Card Level Info Bar
                HStack {
                    Text(vm.currentLevel.name)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(levelColor(for: vm.currentLevel))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(levelColor(for: vm.currentLevel).opacity(0.12))
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("Duration:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1fs", vm.currentLevel.litWindow))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    
                    if vm.currentLevel == .l4 {
                        Text("• 🔥 2 CARDS LIT!")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal)
                
                // Play Area Container
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                    
                    if vm.state == .running {
                        // Cards Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(vm.cards) { card in
                                Button(action: {
                                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                        vm.tapCard(at: card.id)
                                    }
                                }) {
                                    ZStack {
                                        if card.isLit {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(levelGradient(for: vm.currentLevel))
                                                .shadow(color: levelGlowColor(for: vm.currentLevel).opacity(0.55), radius: 10, x: 0, y: 4)
                                        } else {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(.systemGray5))
                                        }
                                    }
                                    .frame(height: cardHeight(for: vm.currentLevel))
                                    .scaleEffect(card.isLit ? 1.05 : 1.0)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(card.isLit ? Color.white.opacity(0.3) : Color.gray.opacity(0.15), lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: card.isLit)
                            }
                        }
                        .padding(20)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Level Up Flash Overlay
                    if vm.showLevelUpAlert {
                        ZStack {
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .cornerRadius(24)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .scaleEffect(1.1)
                                
                                Text("LEVEL UP!")
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(.primary)
                                
                                Text(vm.currentLevel.name)
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(levelColor(for: vm.currentLevel))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        .zIndex(2)
                    }
                    
                    // Game Over Overlay
                    if vm.state == .finished {
                        VStack(spacing: 16) {
                            Text(vm.lives <= 0 ? "DEFEATED" : "GAME OVER")
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
                                Text("High Score: \(highScoreLightItUp)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
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
                                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                                }
                                
                                ShareLink(item: "I just scored \(vm.tapCount) on Light It Up — beat that!") {
                                    Label("", systemImage: "square.and.arrow.up")
                                        .font(.system(.headline, design: .rounded))
                                        .bold()
                                        .foregroundStyle(.primary)
                                        .padding(.all, 12)
                                        .background(Color(.systemGray5))
                                        .clipShape(Circle())
                                }
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
                                    LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                }
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.currentMode = .lightItUp
            vm.resetGame()
        }
        .onChange(of: vm.state) { newState in
            if newState == .finished {
                if vm.tapCount > highScoreLightItUp {
                    highScoreLightItUp = vm.tapCount
                    vm.isNewHighScore = true
                } else {
                    vm.isNewHighScore = false
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
            vm.hapticTrigger = nil
        }
    }
    
    private func levelColor(for level: Level) -> Color {
        switch level {
        case .l1: return .blue
        case .l2: return .green
        case .l3: return .orange
        case .l4: return .red
        }
    }
    
    private func levelGradient(for level: Level) -> LinearGradient {
        switch level {
        case .l1:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .l2:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .l3:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .l4:
            return LinearGradient(colors: [.red, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func levelGlowColor(for level: Level) -> Color {
        switch level {
        case .l1: return .blue
        case .l2: return .green
        case .l3: return .orange
        case .l4: return .red
        }
    }
    
    private func cardHeight(for level: Level) -> CGFloat {
        switch level {
        case .l1: return 200 // row of 3 has plenty of height
        case .l2: return 120 // 2x2 grid
        case .l3: return 110 // 2x3 grid
        case .l4: return 75  // 3x3 grid
        }
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
    NavigationStack {
        LightItUpView()
    }
}
