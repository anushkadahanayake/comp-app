import SwiftUI

struct HomeView: View {
    @StateObject private var vm = GameViewModel()
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    @State private var isShowingSettings = false
    
    var body: some View {
        ZStack {
            // Premium background
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemGray6)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 36) {
                Spacer()
                
                // Arcade Header Branding
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 90, height: 90)
                            .shadow(color: .purple.opacity(0.35), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.white)
                    }
                    
                    Text("ARCADE FRENZY")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .secondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    Text("Double game mode response challenge")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                }
                
                // Selection Cards
                VStack(spacing: 16) {
                    // Mode 1: Tap Frenzy Card
                    NavigationLink(destination: TapFrenzyView()) {
                        HStack(spacing: 18) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .blue.opacity(0.2), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "bolt.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tap Frenzy")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Text("Mashing challenge. 10 seconds, multiplier, colors, double bursts.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("BEST")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("\(highScoreTapFrenzy)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.all, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Mode 2: Light It Up Card
                    NavigationLink(destination: LightItUpView()) {
                        HStack(spacing: 18) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .orange.opacity(0.2), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Light It Up")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Text("Whack-a-Mole cards. Speed progression, lives, level glows.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("BEST")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("\(highScoreLightItUp)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.all, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Mode 3: Quiz Rush Card
                    NavigationLink(destination: QuizRushView()) {
                        HStack(spacing: 18) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .purple.opacity(0.2), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: "questionmark.bubble.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Quiz Rush")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                Text("Trivia challenge. 10 live questions, streaks, async APIs, no lives.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("BEST")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("\(highScoreQuizRush)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.all, 16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isShowingSettings = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .onAppear {
            vm.resetGame()
            
            // Perform legacy migration fallback
            let savedFrenzy = UserDefaults.standard.integer(forKey: "HighScore_TapFrenzy")
            if savedFrenzy == 0 {
                let old = UserDefaults.standard.integer(forKey: "HighScoreKey")
                if old > 0 {
                    highScoreTapFrenzy = old
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
