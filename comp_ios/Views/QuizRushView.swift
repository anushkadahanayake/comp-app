import SwiftUI

struct QuizRushView: View {
    @StateObject private var vm = QuizViewModel()
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var statsStore = PlayerStatsStore.shared

    private var highScoreQuizRush: Int {
        guard let id = auth.currentPlayer?.id else { return 0 }
        return statsStore.highScore(for: .quizRush, playerId: id)
    }
    @Environment(\.dismiss) private var dismiss
    
    @State private var scaleCombo = false
    @State private var showLeaderboard = false
    
    var body: some View {
        ZStack {
            // Holographic Space Nebula Background
            HolographicSpaceNebulaBackground()
                .ignoresSafeArea()
            
            VStack {
                switch vm.viewState {
                case .idle:
                    categorySelectionView
                case .loading:
                    loadingView
                case .failed(let message):
                    errorView(message: message)
                case .levelComplete:
                    levelCompleteView
                case .loaded:
                    if vm.isGameOver {
                        gameOverView
                    } else {
                        gameplayView
                    }
                }
            }
        }
        .navigationTitle("Quiz Rush")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showLeaderboard = true
                } label: {
                    Image(systemName: "trophy.fill")
                }
                .foregroundStyle(ArcadeTheme.accent)
                .accessibilityLabel("Top scores")

                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(ArcadeTheme.accentSecondary)
            }
        }
        .sheet(isPresented: $showLeaderboard) {
            GameModeLeaderboardSheet(mode: .quizRush)
        }
        .onChange(of: vm.streak) { _, newStreak in
            if newStreak > 0 {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                    scaleCombo = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                        scaleCombo = false
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
            }
            vm.hapticTrigger = nil
        }
    }
    
    // MARK: - Subviews
    private var categorySelectionView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("SELECT CATEGORY FILTER")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 4)
                .tracking(2)

            Text("Campaign: Easy → Medium → Hard · Bonus time for fast answers")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Grid of categories
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(TriviaCategory.allCases) { category in
                        Button(action: {
                            vm.selectedCategory = category
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: category.icon)
                                    .font(.title)
                                    .foregroundStyle(vm.selectedCategory == category ? ArcadeTheme.textPrimary : ArcadeTheme.accentSecondary)
                                
                                Text(category.rawValue)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(vm.selectedCategory == category ? ArcadeTheme.accentMuted : ArcadeTheme.surface)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(vm.selectedCategory == category ? ArcadeTheme.accent : ArcadeTheme.border, lineWidth: 2)
                            )
                            .shadow(color: .clear, radius: 0)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 340)
            
            // START button
            Button(action: {
                Task {
                    await vm.load(category: vm.selectedCategory)
                }
            }) {
                Text("START RUSH")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 48)
                    .background(
                        ArcadeTheme.brandGradient
                    )
                    .clipShape(Capsule())
                    .shadow(color: ArcadeTheme.accent.opacity(0.25), radius: 8)
            }
            .padding(.top, 8)
            
            Spacer(minLength: 12)
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ArcadeTheme.accent)
            
            Text("Loading \(vm.campaignLevel.title)...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            
            Text("Oops!")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            HStack(spacing: 16) {
                Button(action: {
                    Task {
                        await vm.load(category: vm.selectedCategory)
                    }
                }) {
                    Text("Retry")
                        .font(.system(.headline, design: .rounded))
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 28)
                        .background(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(Capsule())
                        .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                
                Button(action: {
                    vm.viewState = .idle
                }) {
                    Text("Change Category")
                        .font(.system(.headline, design: .rounded))
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(ArcadeTheme.surfaceElevated)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gameplayView: some View {
        VStack(spacing: 16) {
            // Level + lives + timer
            VStack(spacing: 10) {
                HStack {
                    Text(vm.campaignLevel.title)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(levelAccent.opacity(0.35)))

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(0..<max(vm.lives, 0), id: \.self) { _ in
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color(red: 0.82, green: 0.42, blue: 0.45))
                                .font(.caption)
                        }
                        if vm.lives == 0 {
                            Text("No lives")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Countdown bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Label(String(format: "%.0fs", max(0, vm.timeRemaining)), systemImage: "timer")
                            .font(.caption.bold())
                            .foregroundStyle(vm.timeRemaining < 5 ? ArcadeTheme.danger : ArcadeTheme.accentSecondary)
                        Spacer()
                        Text("Q \(vm.index + 1)/\(vm.questions.count)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: vm.timeRemaining < 5 ? [ArcadeTheme.danger, ArcadeTheme.warning] : [ArcadeTheme.accentSecondary, ArcadeTheme.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * vm.timerProgress)
                        }
                    }
                    .frame(height: 8)
                }

                if let bonus = vm.bonusBanner {
                    Text(bonus)
                        .font(.caption.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // Score / streak strip — icon on top of each card
            HStack(spacing: 10) {
                GameStatCard(title: "SCORE", value: "\(vm.score)", systemImage: "star.fill", accent: ArcadeTheme.accent)
                GameStatCard(title: "STREAK", value: "\(vm.streak)", systemImage: "flame.fill", accent: ArcadeTheme.warning)
                GameStatCard(title: "CORRECT", value: "\(vm.totalCorrect)", systemImage: "checkmark.circle.fill", accent: ArcadeTheme.accentSecondary)
            }
            .padding(.horizontal)
            
            // Question Card Display (Holographic outline)
            if let question = vm.currentQuestion {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Text(question.decodedQuestion)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(ArcadeTheme.surface.opacity(0.95))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(LinearGradient(colors: [ArcadeTheme.accentSecondary.opacity(0.5), ArcadeTheme.accent.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.2), radius: 8)
                .modifier(ShakeEffect(animatableData: vm.shakeTrigger))
                .padding(.horizontal)
                
                // Combo / Streak Fire banner
                if vm.streak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                        Text("COMBO MULTIPLIER X\(vm.streak) 🔥")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.5), radius: 8)
                    .scaleEffect(scaleCombo ? 1.25 : 1.0)
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Choices List (Cached Shuffled Order)
                VStack(spacing: 12) {
                    ForEach(vm.shuffledAnswers(for: question), id: \.self) { answer in
                        Button(action: {
                            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                                vm.tapAnswer(answer)
                            }
                        }) {
                            Text(answer)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(choiceTextColor(for: answer))
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(choiceBackgroundColor(for: answer))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(choiceBorderColor(for: answer), lineWidth: 1.5)
                                )
                                .shadow(color: choiceGlowColor(for: answer).opacity(0.12), radius: 6)
                        }
                        .disabled(vm.isTransitioning)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }

    private var levelAccent: Color {
        switch vm.campaignLevel {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    private var levelCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 18) {
                Text("LEVEL CLEARED!")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.black)
                    .foregroundStyle(
                        LinearGradient(colors: [ArcadeTheme.success, ArcadeTheme.accentSecondary], startPoint: .leading, endPoint: .trailing)
                    )

                Text(vm.campaignLevel.title)
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))

                if let bonus = vm.bonusBanner {
                    Text(bonus)
                        .font(.subheadline.bold())
                        .foregroundStyle(.yellow)
                }

                HStack(spacing: 20) {
                    VStack {
                        Text("\(vm.score)")
                            .font(.title.bold())
                            .foregroundStyle(.white)
                        Text("Score")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(vm.lives)")
                            .font(.title.bold())
                            .foregroundStyle(ArcadeTheme.danger)
                        Text("Lives")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack {
                        Text("\(vm.levelsCleared)/3")
                            .font(.title.bold())
                            .foregroundStyle(ArcadeTheme.accentSecondary)
                        Text("Levels")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let next = vm.campaignLevel.next {
                    Text("Next up: \(next.title)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))

                    Button {
                        Task { await vm.continueToNextLevel() }
                    } label: {
                        Text("Continue Campaign")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 32)
                            .background(
                                ArcadeTheme.brandGradient,
                                in: Capsule()
                            )
                    }
                }
            }
            .padding(28)
            .background(ArcadeTheme.surfaceElevated)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
            )
            .padding(.horizontal, 24)

            Spacer()
        }
    }
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                Text(vm.levelsCleared >= 3 ? "CAMPAIGN COMPLETE" : "RUN OVER")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.black)
                    .foregroundStyle(
                        ArcadeTheme.brandGradient
                    )
                    .shadow(color: ArcadeTheme.accent.opacity(0.2), radius: 6)
                
                VStack(spacing: 4) {
                    Text("Final Score")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("\(vm.score)")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                    Text("Levels cleared: \(vm.levelsCleared)/3 · Correct: \(vm.totalCorrect)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    Text("High Score: \(highScoreQuizRush)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button(action: {
                            Task {
                                await vm.load(category: vm.selectedCategory)
                            }
                        }) {
                            Text("Play Again")
                                .font(.system(.headline, design: .rounded))
                                .bold()
                                .foregroundStyle(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 28)
                                .background(
                                    ArcadeTheme.brandGradient
                                )
                                .clipShape(Capsule())
                                .shadow(color: ArcadeTheme.accent.opacity(0.25), radius: 6, y: 3)
                        }
                        
                        ShareLink(item: "I just scored \(vm.score) on Quiz Rush — beat that!") {
                            Label("", systemImage: "square.and.arrow.up")
                                .font(.system(.headline, design: .rounded))
                                .bold()
                                .foregroundStyle(.white)
                                .padding(.all, 12)
                                .background(ArcadeTheme.surfaceElevated)
                                .clipShape(Circle())
                        }
                    }
                    
                    Button(action: {
                        vm.viewState = .idle
                    }) {
                        Text("Change Category")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(ArcadeTheme.accentSecondary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.all, 32)
            .background(ArcadeTheme.surfaceElevated)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 10)
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Choice Styling Helpers
    private func choiceBackgroundColor(for answer: String) -> Color {
        if let correct = vm.correctHighlightIndex, correct == answer {
            return .green
        }
        if let wrong = vm.wrongHighlightIndex, wrong == answer {
            return .red
        }
        return ArcadeTheme.surface
    }
    
    private func choiceTextColor(for answer: String) -> Color {
        if vm.correctHighlightIndex == answer || vm.wrongHighlightIndex == answer {
            return .white
        }
        return .white.opacity(0.85)
    }
    
    private func choiceBorderColor(for answer: String) -> Color {
        if let correct = vm.correctHighlightIndex, correct == answer {
            return .green
        }
        if let wrong = vm.wrongHighlightIndex, wrong == answer {
            return .red
        }
        return Color.white.opacity(0.12)
    }
    
    private func choiceGlowColor(for answer: String) -> Color {
        if vm.correctHighlightIndex == answer {
            return .green
        }
        if vm.wrongHighlightIndex == answer {
            return .red
        }
        return .clear
    }
    
    private func triggerNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        AppFeedback.notify(type)
    }
}

// MARK: - Holographic Space Nebula Background
struct HolographicSpaceNebulaBackground: View {
    @State private var animate = false
    
    private let stars = (0..<20).map { _ in
        Star(
            id: UUID(),
            x: CGFloat.random(in: 10...380),
            y: CGFloat.random(in: 50...750),
            size: CGFloat.random(in: 2...4),
            speed: Double.random(in: 4.0...8.0),
            delay: Double.random(in: 0.0...3.0)
        )
    }
    
    var body: some View {
        ZStack {
            ArcadeTheme.backgroundDeep
                .ignoresSafeArea()
            
            ZStack {
                Circle()
                    .fill(ArcadeTheme.ambientC)
                    .frame(width: 320, height: 320)
                    .offset(x: animate ? -50 : 50, y: animate ? -80 : 80)
                    .blur(radius: 60)
                
                Circle()
                    .fill(ArcadeTheme.ambientB)
                    .frame(width: 280, height: 280)
                    .offset(x: animate ? 70 : -70, y: animate ? 70 : -70)
                    .blur(radius: 50)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
                    animate.toggle()
                }
            }
            
            ForEach(stars) { star in
                StarItemView(star: star)
            }
        }
    }
}

struct Star: Identifiable {
    let id: UUID
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let speed: Double
    let delay: Double
}

struct StarItemView: View {
    let star: Star
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 0.2
    
    var body: some View {
        Circle()
            .fill(Color.white.opacity(0.8))
            .frame(width: star.size, height: star.size)
            .position(x: star.x, y: star.y)
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(color: .white.opacity(0.5), radius: 3)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: star.speed / 2.0)
                    .repeatForever(autoreverses: true)
                    .delay(star.delay)
                ) {
                    scale = 1.2
                    opacity = 0.90
                }
            }
    }
}

// MARK: - Shake Geometry Effect
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    
    var animatableDataModifier: CGFloat {
        get { animatableData }
        set { animatableData = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 12 * sin(animatableData * .pi * 2), y: 0))
    }
}

#Preview {
    NavigationStack {
        QuizRushView()
    }
}
