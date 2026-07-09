import SwiftUI

struct QuizRushView: View {
    @StateObject private var vm = QuizViewModel()
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    @State private var scaleCombo = false
    
    var body: some View {
        ZStack {
            // Dark Gaming Background
            Color(red: 0.03, green: 0.03, blue: 0.07)
                .ignoresSafeArea()
            
            VStack {
                switch vm.viewState {
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
        .task {
            await vm.load()
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
            
            Button(action: {
                Task {
                    await vm.load()
                }
            }) {
                Text("Retry")
                    .font(.system(.headline, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 48)
                    .background(
                        LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
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
                
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await vm.load()
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
