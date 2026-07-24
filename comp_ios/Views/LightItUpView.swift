import SwiftUI

struct LightItUpView: View {
    @StateObject private var vm = GameViewModel()
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var statsStore = PlayerStatsStore.shared

    private var highScoreLightItUp: Int {
        guard let id = auth.currentPlayer?.id else { return 0 }
        return statsStore.highScore(for: .lightItUp, playerId: id)
    }
    @Environment(\.dismiss) private var dismiss
    
    @State private var flashRedBorder = false
    @State private var showLeaderboard = false
    
    // Grid columns layout based on the level
    private var columns: [GridItem] {
        switch vm.currentLevel {
        case .l1:
            return Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
        case .l2:
            return Array(repeating: GridItem(.flexible(), spacing: 18), count: 2)
        case .l3:
            return Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
        case .l4:
            return Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
        }
    }
    
    var body: some View {
        ZStack {
            LevelMatchingAuroraBackground(level: vm.currentLevel)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header: icon on top of each card
                HStack(spacing: 10) {
                    GameStatCard(
                        title: "SCORE",
                        value: "\(vm.tapCount)",
                        systemImage: "star.fill",
                        accent: .cyan
                    )
                    GameLivesCard(lives: vm.lives, maxLives: 3)
                    GameStatCard(
                        title: "BEST",
                        value: "\(highScoreLightItUp)",
                        systemImage: "crown.fill",
                        accent: .orange
                    )
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Countdown progress bar (grows when bonus-time cards are tapped)
                VStack(spacing: 8) {
                    HStack {
                        Text("Round Time")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let bonus = vm.lightItUpBonusBanner {
                            Text(bonus)
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        }
                        Text(String(format: "%.1fs", vm.timeLeft))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(vm.timeLeft <= 10.0 ? .red : .orange)
                    }
                    .padding(.horizontal)
                    
                    GeometryReader { barProxy in
                        let ceiling = max(vm.roundDurationSetting, vm.timeLeft, 0.1)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 10)
                            
                            Capsule()
                                .fill(vm.timeLeft <= 10.0 ? Color.red : Color.orange)
                                .frame(width: max(0, barProxy.size.width * CGFloat(vm.timeLeft / ceiling)), height: 10)
                                .animation(.linear(duration: 0.05), value: vm.timeLeft)
                                .shadow(color: (vm.timeLeft <= 10.0 ? Color.red : Color.orange).opacity(0.5), radius: 6)
                        }
                    }
                    .frame(height: 10)
                    .padding(.horizontal)
                }
                
                // Active Card Level Info Bar
                HStack {
                    Text(vm.currentLevel.name)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(levelColor(for: vm.currentLevel))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(levelColor(for: vm.currentLevel).opacity(0.15))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(levelColor(for: vm.currentLevel).opacity(0.4), lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    Text("Duration:")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1fs", vm.currentLevel.litWindow))
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(.orange)
                    
                    if vm.currentLevel != .l1 {
                        Text("Gold clock = +3s")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.yellow)
                    }
                }
                .padding(.horizontal)
                
                // Play Area Container
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(red: 0.05, green: 0.05, blue: 0.10).opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(flashRedBorder ? Color.red : Color.white.opacity(0.12), lineWidth: flashRedBorder ? 2.5 : 1.5)
                        )
                        .shadow(color: (flashRedBorder ? Color.red : Color.orange).opacity(0.04), radius: 10)
                    
                    if vm.state == .running {
                        // Cards Grid
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(vm.cards) { card in
                                Button(action: {
                                    let oldLives = vm.lives
                                    withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                                        vm.tapCard(at: card.id)
                                        
                                        // Trigger red screen flashing if lives decrease
                                        if vm.lives < oldLives {
                                            flashRedBorder = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                flashRedBorder = false
                                            }
                                        }
                                    }
                                }) {
                                    ZStack {
                                        if card.isLit {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(
                                                    card.isBonusTime
                                                        ? LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                                        : levelGradient(for: vm.currentLevel)
                                                )
                                                .shadow(
                                                    color: (card.isBonusTime ? Color.yellow : levelGlowColor(for: vm.currentLevel)).opacity(0.75),
                                                    radius: 15, x: 0, y: 0
                                                )
                                            if card.isBonusTime {
                                                Image(systemName: "clock.badge.checkmark.fill")
                                                    .font(.title2.weight(.bold))
                                                    .foregroundStyle(.white)
                                                    .shadow(color: .black.opacity(0.35), radius: 2)
                                            }
                                        } else {
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .fill(Color(red: 0.10, green: 0.10, blue: 0.18))
                                        }
                                    }
                                    .frame(height: cardHeight(for: vm.currentLevel))
                                    .scaleEffect(card.isLit ? 1.06 : 1.0)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(
                                                card.isLit
                                                    ? (card.isBonusTime ? Color.yellow : Color.white)
                                                    : Color.white.opacity(0.15),
                                                lineWidth: card.isLit ? 2 : 1
                                            )
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .animation(.spring(response: 0.22, dampingFraction: 0.6), value: card.isLit)
                                .animation(.spring(response: 0.22, dampingFraction: 0.6), value: card.isBonusTime)
                            }
                        }
                        .padding(20)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Level Up Flash Overlay
                    if vm.showLevelUpAlert {
                        ZStack {
                            Rectangle()
                                .fill(Color(red: 0.05, green: 0.05, blue: 0.10).opacity(0.9))
                                .cornerRadius(24)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .scaleEffect(1.1)
                                    .shadow(color: .orange.opacity(0.5), radius: 12)
                                
                                Text("LEVEL UP!")
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(.white)
                                    .shadow(color: .white.opacity(0.4), radius: 8)
                                
                                Text(vm.currentLevel.name)
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(levelColor(for: vm.currentLevel))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        .zIndex(2)
                    }
                    
                    // Game Over Overlay
                    if vm.state == .finished {
                        VStack(spacing: 20) {
                            Text(vm.lives <= 0 ? "DEFEATED" : "GAME OVER")
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
                                Label("NEW HIGH SCORE!", systemImage: "trophy.fill")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(
                                        LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .orange.opacity(0.5), radius: 10)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("High Score: \(highScoreLightItUp)")
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
                                
                                ShareLink(item: "I just scored \(vm.tapCount) on Light It Up — beat that!") {
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
                        VStack(spacing: 14) {
                            Label("From Level 2: 2 cards — tap the gold clock for +3s", systemImage: "clock.badge.checkmark.fill")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)

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
                                        LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 0)
                            }
                        }
                    }
                }
                .frame(maxHeight: 340)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal)
                
                Spacer(minLength: 8)
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Light It Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showLeaderboard = true
                } label: {
                    Image(systemName: "trophy.fill")
                }
                .foregroundStyle(.orange)
                .accessibilityLabel("Top scores")

                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(.orange)
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            GameModeLeaderboardSheet(mode: .lightItUp)
        }
        .onAppear {
            vm.currentMode = GameMode.lightItUp
            vm.resetGame()
        }
        .onChange(of: vm.state) { _, newState in
            if newState == .finished {
                DispatchQueue.main.async {
                    guard let playerId = auth.currentPlayer?.id else {
                        vm.isNewHighScore = false
                        return
                    }
                    vm.isNewHighScore = statsStore.updateHighScoreIfNeeded(
                        score: vm.tapCount,
                        mode: .lightItUp,
                        playerId: playerId,
                        latitude: LocationService.shared.currentLatitude,
                        longitude: LocationService.shared.currentLongitude
                    )
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
    
    // UI Helpers
    private func cardHeight(for level: Level) -> CGFloat {
        switch level {
        case .l1: return 120
        case .l2: return 120
        case .l3: return 110
        case .l4: return 80
        }
    }
    
    private func levelColor(for level: Level) -> Color {
        switch level {
        case .l1: return .cyan
        case .l2: return .green
        case .l3: return .purple
        case .l4: return .orange
        }
    }
    
    private func levelGlowColor(for level: Level) -> Color {
        switch level {
        case .l1: return .cyan
        case .l2: return .green
        case .l3: return .pink
        case .l4: return .orange
        }
    }
    
    private func levelGradient(for level: Level) -> LinearGradient {
        switch level {
        case .l1:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .l2:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .l3:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .l4:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    @MainActor private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        AppFeedback.impact(style)
        AppFeedback.playTap()
    }
    
    @MainActor private func triggerNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        AppFeedback.notify(type)
    }
}

#Preview {
    NavigationStack {
        LightItUpView()
    }
}

// MARK: - Level Matching Aurora Background
struct LevelMatchingAuroraBackground: View {
    let level: Level
    @State private var animate = false
    
    private var levelColor: Color {
        switch level {
        case .l1: return .cyan
        case .l2: return .green
        case .l3: return .purple
        case .l4: return .orange
        }
    }
    
    private var secondaryColor: Color {
        switch level {
        case .l1: return .blue
        case .l2: return .mint
        case .l3: return .pink
        case .l4: return .red
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.01, blue: 0.04)
                .ignoresSafeArea()
            
            ZStack {
                Circle()
                    .fill(levelColor.opacity(0.24))
                    .frame(width: 320, height: 320)
                    .offset(x: animate ? -50 : 50, y: animate ? -80 : 80)
                    .blur(radius: 60)
                
                Circle()
                    .fill(secondaryColor.opacity(0.20))
                    .frame(width: 280, height: 280)
                    .offset(x: animate ? 70 : -70, y: animate ? 70 : -70)
                    .blur(radius: 50)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
        }
    }
}
