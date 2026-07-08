import SwiftUI

struct HomeView: View {
    @StateObject private var vm = GameViewModel()
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    // States for entrance animations
    @State private var animateHeader = false
    @State private var animateCard1 = false
    @State private var animateCard2 = false
    @State private var animateCard3 = false
    
    var body: some View {
        ZStack {
            // Premium fluid animated background
            ZStack {
                FluidBackgroundView()
                FloatingParticlesView()
            }
            .ignoresSafeArea()
            
            VStack(spacing: 36) {
                Spacer()
                
                // Arcade Header Branding
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 90, height: 90)
                            .shadow(color: .blue.opacity(0.25), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(animateHeader ? 1.0 : 0.5)
                    .opacity(animateHeader ? 1.0 : 0.0)
                    
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
                        .offset(y: animateHeader ? 0 : -20)
                        .opacity(animateHeader ? 1.0 : 0.0)
                    
                    Text("Double game mode response challenge")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fontWeight(.medium)
                        .offset(y: animateHeader ? 0 : -10)
                        .opacity(animateHeader ? 1.0 : 0.0)
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
                        .background(Color(.secondarySystemGroupedBackground).opacity(0.85))
                        .background(.ultraThinMaterial)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .offset(y: animateCard1 ? 0 : 60)
                    .opacity(animateCard1 ? 1.0 : 0.0)
                    
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
                        .background(Color(.secondarySystemGroupedBackground).opacity(0.85))
                        .background(.ultraThinMaterial)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .offset(y: animateCard2 ? 0 : 60)
                    .opacity(animateCard2 ? 1.0 : 0.0)
                    
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
                        .background(Color(.secondarySystemGroupedBackground).opacity(0.85))
                        .background(.ultraThinMaterial)
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.gray.opacity(0.12), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .offset(y: animateCard3 ? 0 : 60)
                    .opacity(animateCard3 ? 1.0 : 0.0)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
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
            
            // Trigger cascading load animations
            withAnimation(.spring(response: 0.75, dampingFraction: 0.75)) {
                animateHeader = true
            }
            
            withAnimation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.15)) {
                animateCard1 = true
            }
            
            withAnimation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.28)) {
                animateCard2 = true
            }
            
            withAnimation(.spring(response: 0.65, dampingFraction: 0.7).delay(0.40)) {
                animateCard3 = true
            }
        }
    }
}

// MARK: - Fluid Aurora Background View
struct FluidBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ZStack {
                // Blob 1 (Blue)
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .offset(x: animate ? -60 : 60, y: animate ? -90 : 90)
                    .blur(radius: 50)
                
                // Blob 2 (Cyan)
                Circle()
                    .fill(Color.cyan.opacity(0.10))
                    .frame(width: 280, height: 280)
                    .offset(x: animate ? 80 : -80, y: animate ? 100 : -100)
                    .blur(radius: 45)
                
                // Blob 3 (Purple/Lavender)
                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 240, height: 240)
                    .offset(x: animate ? -100 : 100, y: animate ? 60 : -60)
                    .blur(radius: 40)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 10.0)
                    .repeatForever(autoreverses: true)
                ) {
                    animate.toggle()
                }
            }
        }
    }
}

// MARK: - Floating Particles Background View
struct FloatingParticlesView: View {
    @State private var animate = false
    
    private let particleCoordinates: [CGPoint] = (0..<15).map { _ in
        CGPoint(
            x: CGFloat.random(in: 20...350),
            y: CGFloat.random(in: 100...700)
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.blue.opacity(0.06))
                        .frame(width: CGFloat.random(in: 12...24))
                        .blur(radius: 1.5)
                        .position(particleCoordinates[index])
                        .offset(y: animate ? -250 : 250)
                        .opacity(animate ? 0.1 : 0.8)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: Double.random(in: 14.0...20.0))
                    .repeatForever(autoreverses: false)
                ) {
                    animate.toggle()
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
