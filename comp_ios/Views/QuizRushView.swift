import SwiftUI

struct QuizRushView: View {
    @StateObject private var vm = QuizViewModel()
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    @State private var scaleCombo = false
    
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
                case .loaded:
                    if vm.index < vm.questions.count {
                        gameplayView
                    } else {
                        gameOverView
                    }
                }
            }
        }
        .navigationTitle("Quiz Rush")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .foregroundStyle(.purple)
            }
        }
        .onChange(of: vm.index) { newIndex in
            // Handle high score updates as soon as the user completes the 10th question
            if newIndex >= vm.questions.count && !vm.questions.isEmpty {
                if vm.score > highScoreQuizRush {
                    highScoreQuizRush = vm.score
                    vm.isNewHighScore = true
                } else {
                    vm.isNewHighScore = false
                }
            }
        }
        .onChange(of: vm.streak) { newStreak in
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
        .onChange(of: vm.hapticTrigger) { trigger in
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
            
            Text("SELECT YOUR AREA")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .foregroundStyle(.white)
                .shadow(color: .purple.opacity(0.8), radius: 8)
                .tracking(3)
            
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
                                    .foregroundStyle(vm.selectedCategory == category ? .white : .purple)
                                
                                Text(category.rawValue)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .background(vm.selectedCategory == category ? Color.purple.opacity(0.3) : Color(red: 0.08, green: 0.08, blue: 0.16))
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(vm.selectedCategory == category ? Color.purple : Color.white.opacity(0.12), lineWidth: 2)
                            )
                            .shadow(color: vm.selectedCategory == category ? .purple.opacity(0.3) : .clear, radius: 8)
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
                        LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .purple.opacity(0.4), radius: 12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.purple)
            
            Text("Loading Trivia Questions...")
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
                        .background(Color(red: 0.12, green: 0.12, blue: 0.22))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var gameplayView: some View {
        VStack(spacing: 24) {
            // Score & Streak Header Panel
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("QUESTION")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.cyan)
                    Text("\(vm.index + 1) / \(vm.questions.count)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.08, green: 0.08, blue: 0.15))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1.5)
                )
                
                VStack(spacing: 4) {
                    Text("SCORE")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.purple)
                    Text("\(vm.score)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.08, green: 0.08, blue: 0.15))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1.5)
                )
                
                VStack(spacing: 4) {
                    Text("STREAK")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.orange)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(vm.streak > 0 ? .orange : .gray.opacity(0.4))
                        Text("\(vm.streak)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(vm.streak > 0 ? .orange : .white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(red: 0.08, green: 0.08, blue: 0.15))
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                )
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
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
                .background(Color(red: 0.05, green: 0.05, blue: 0.12).opacity(0.8))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(LinearGradient(colors: [.cyan.opacity(0.6), .purple.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
                )
                .shadow(color: .cyan.opacity(0.15), radius: 15)
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
    
    private var gameOverView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("ROUND OVER")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.black)
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: .purple.opacity(0.4), radius: 8)
                
                VStack(spacing: 4) {
                    Text("Final Score")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("\(vm.score)")
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
                                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        
                        ShareLink(item: "I just scored \(vm.score) on Quiz Rush — beat that!") {
                            Label("", systemImage: "square.and.arrow.up")
                                .font(.system(.headline, design: .rounded))
                                .bold()
                                .foregroundStyle(.white)
                                .padding(.all, 12)
                                .background(Color(red: 0.12, green: 0.12, blue: 0.22))
                                .clipShape(Circle())
                        }
                    }
                    
                    Button(action: {
                        vm.viewState = .idle
                    }) {
                        Text("Change Category")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.purple)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .padding(.all, 32)
            .background(Color(red: 0.05, green: 0.05, blue: 0.10).opacity(0.95))
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
            )
            .shadow(color: .purple.opacity(0.1), radius: 15)
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
        return Color(red: 0.08, green: 0.08, blue: 0.16)
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
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
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
            Color(red: 0.02, green: 0.01, blue: 0.04)
                .ignoresSafeArea()
            
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.22))
                    .frame(width: 320, height: 320)
                    .offset(x: animate ? -50 : 50, y: animate ? -80 : 80)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Color.indigo.opacity(0.20))
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
