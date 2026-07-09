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
            
            VStack(spacing: 32) {
                Spacer()
                
                // Arcade Header Branding
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 90, height: 90)
                            .shadow(color: .cyan.opacity(0.6), radius: 20, x: 0, y: 0)
                        
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
                                colors: [.cyan, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.5), radius: 10, x: 0, y: 0)
                        .offset(y: animateHeader ? 0 : -20)
                        .opacity(animateHeader ? 1.0 : 0.0)
                    
                    Text("TAP SPEED • REFLEX • TRIVIA RUSH")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.cyan)
                        .tracking(3)
                        .offset(y: animateHeader ? 0 : -10)
                        .opacity(animateHeader ? 1.0 : 0.0)
                }
                
                // Selection Cards
                VStack(spacing: 18) {
                    // Mode 1: Tap Frenzy Card
                    NavigationLink(destination: TapFrenzyView()) {
                        HStack(spacing: 18) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 0)
                                
                                Image(systemName: "bolt.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Tap Frenzy")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.black)
                                        .foregroundStyle(.white)
                                    
                                    Text("SPEED")
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 6)
                                        .background(Color.blue)
                                        .cornerRadius(6)
                                }
                                Text("Mashing challenge. 10 seconds, multiplier, double points.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("BEST")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.cyan)
                                Text("\(highScoreTapFrenzy)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.all, 18)
                        .background(Color(red: 0.06, green: 0.06, blue: 0.12).opacity(0.75))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(LinearGradient(colors: [.blue.opacity(0.6), .cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                        )
                        .shadow(color: .blue.opacity(0.2), radius: 10, x: 0, y: 4)
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
                                    .shadow(color: .orange.opacity(0.4), radius: 8, x: 0, y: 0)
                                
                                Image(systemName: "lightbulb.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Light It Up")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.black)
                                        .foregroundStyle(.white)
                                    
                                    Text("REFLEX")
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 6)
                                        .background(Color.orange)
                                        .cornerRadius(6)
                                }
                                Text("Whack-a-Mole cards. Speed progression, lives, neon glows.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("BEST")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.orange)
                                Text("\(highScoreLightItUp)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.all, 18)
                        .background(Color(red: 0.06, green: 0.06, blue: 0.12).opacity(0.75))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(LinearGradient(colors: [.orange.opacity(0.6), .yellow.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                        )
                        .shadow(color: .orange.opacity(0.2), radius: 10, x: 0, y: 4)
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
                                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .purple.opacity(0.4), radius: 8, x: 0, y: 0)
                                
                                Image(systemName: "questionmark.bubble.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("Quiz Rush")
                                        .font(.system(.headline, design: .rounded))
                                        .fontWeight(.black)
                                        .foregroundStyle(.white)
                                    
                                    Text("TRIVIA")
                                        .font(.system(size: 8, weight: .black, design: .rounded))
                                        .foregroundStyle(.white)
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 6)
                                        .background(Color.purple)
                                        .cornerRadius(6)
                                }
                                Text("Trivia challenge. 10 questions, combo multipliers, live API.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("BEST")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.purple)
                                Text("\(highScoreQuizRush)")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.all, 18)
                        .background(Color(red: 0.06, green: 0.06, blue: 0.12).opacity(0.75))
                        .cornerRadius(22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(LinearGradient(colors: [.purple.opacity(0.6), .pink.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                        )
                        .shadow(color: .purple.opacity(0.2), radius: 10, x: 0, y: 4)
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
            
            // Trigger cascading spring animations
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                animateHeader = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.12)) {
                animateCard1 = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.24)) {
                animateCard2 = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.36)) {
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
            Color(red: 0.03, green: 0.03, blue: 0.07)
                .ignoresSafeArea()
            
            ZStack {
                // Blob 1 (Blue)
                Circle()
                    .fill(Color.blue.opacity(0.20))
                    .frame(width: 320, height: 320)
                    .offset(x: animate ? -60 : 60, y: animate ? -90 : 90)
                    .blur(radius: 60)
                
                // Blob 2 (Cyan)
                Circle()
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 280, height: 280)
                    .offset(x: animate ? 80 : -80, y: animate ? 100 : -100)
                    .blur(radius: 50)
                
                // Blob 3 (Purple/Lavender)
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 240, height: 240)
                    .offset(x: animate ? -100 : 100, y: animate ? 60 : -60)
                    .blur(radius: 45)
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 8.0)
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
    
    private let particleCoordinates: [CGPoint] = (0..<18).map { _ in
        CGPoint(
            x: CGFloat.random(in: 20...370),
            y: CGFloat.random(in: 80...720)
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<18, id: \.self) { index in
                    Circle()
                        .fill(index % 2 == 0 ? Color.cyan.opacity(0.12) : Color.purple.opacity(0.12))
                        .frame(width: CGFloat.random(in: 8...18))
                        .blur(radius: 1.0)
                        .position(particleCoordinates[index])
                        .offset(y: animate ? -250 : 250)
                        .opacity(animate ? 0.0 : 0.85)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: Double.random(in: 12.0...18.0))
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
