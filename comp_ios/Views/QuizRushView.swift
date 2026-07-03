import SwiftUI

struct QuizRushView: View {
    @StateObject private var vm = QuizViewModel()
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Premium background gradient
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                switch vm.state {
                case .loading:
                    loadingView
                case .error(let message):
                    errorView(message: message)
                case .playing:
                    gameplayView
                case .finished:
                    gameOverView
                }
            }
        }
        .navigationTitle("Quiz Rush")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            vm.startGame()
        }
        .onChange(of: vm.state) { newState in
            if newState == .finished {
                if vm.score > highScoreQuizRush {
                    highScoreQuizRush = vm.score
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
            
            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                vm.startGame()
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
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("\(vm.currentIndex + 1) / 10")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    Text("SCORE")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("\(vm.score)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                
                VStack(spacing: 4) {
                    Text("STREAK")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(vm.streak > 0 ? .orange : .gray.opacity(0.4))
                        Text("\(vm.streak)")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(vm.streak > 0 ? .orange : .primary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Question Card Display
            if let question = vm.currentQuestion {
                VStack(spacing: 16) {
                    Spacer()
                    
                    Text(question.question)
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                
                // Stack of 4 Choices
                VStack(spacing: 12) {
                    ForEach(question.shuffledAnswers, id: \.self) { answer in
                        Button(action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                vm.tapAnswer(answer)
                            }
                        }) {
                            Text(answer)
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.gray.opacity(0.15), lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.02), radius: 4, x: 0, y: 2)
                        }
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
                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                    )
                
                VStack(spacing: 4) {
                    Text("Final Score")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text("\(vm.score)")
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
                } else {
                    Text("High Score: \(highScoreQuizRush)")
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
            .padding(.all, 32)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    private func triggerNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

#Preview {
    NavigationStack {
        QuizRushView()
    }
}
