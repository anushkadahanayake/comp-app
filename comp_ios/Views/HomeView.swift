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
                LavaPlasmaBackgroundView()
                EmberSparklesView()
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

// MARK: - Lava Plasma Background View
struct LavaPlasmaBackgroundView: View {
    @State private var animateBlob1 = false
    @State private var animateBlob2 = false
    @State private var animateBlob3 = false
    @State private var animateBlob4 = false
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.01, blue: 0.04)
                .ignoresSafeArea()
            
            ZStack {
                // Blob 1: Deep Red
                Circle()
                    .fill(Color(red: 0.75, green: 0.05, blue: 0.05).opacity(0.42))
                    .frame(width: 360, height: 360)
                    .offset(x: animateBlob1 ? -70 : 70, y: animateBlob1 ? -110 : 110)
                    .scaleEffect(animateBlob1 ? 1.12 : 0.88)
                    .blur(radius: 60)
                
                // Blob 2: Lava Orange
                Circle()
                    .fill(Color(red: 0.95, green: 0.3, blue: 0.0).opacity(0.38))
                    .frame(width: 320, height: 320)
                    .offset(x: animateBlob2 ? 80 : -80, y: animateBlob2 ? 60 : -60)
                    .scaleEffect(animateBlob2 ? 0.92 : 1.15)
                    .blur(radius: 50)
                
                // Blob 3: Golden Flame
                Circle()
                    .fill(Color(red: 0.95, green: 0.65, blue: 0.0).opacity(0.28))
                    .frame(width: 270, height: 270)
                    .offset(x: animateBlob3 ? -90 : 90, y: animateBlob3 ? 70 : -70)
                    .scaleEffect(animateBlob3 ? 1.2 : 0.85)
                    .blur(radius: 45)
                
                // Blob 4: Hot Magenta
                Circle()
                    .fill(Color(red: 0.85, green: 0.0, blue: 0.45).opacity(0.22))
                    .frame(width: 240, height: 240)
                    .offset(x: animateBlob4 ? 50 : -50, y: animateBlob4 ? -90 : 90)
                    .scaleEffect(animateBlob4 ? 0.88 : 1.08)
                    .blur(radius: 40)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animateBlob1.toggle()
                }
                withAnimation(.easeInOut(duration: 6.5).repeatForever(autoreverses: true)) {
                    animateBlob2.toggle()
                }
                withAnimation(.easeInOut(duration: 9.0).repeatForever(autoreverses: true)) {
                    animateBlob3.toggle()
                }
                withAnimation(.easeInOut(duration: 5.5).repeatForever(autoreverses: true)) {
                    animateBlob4.toggle()
                }
            }
        }
    }
}

// MARK: - Ember Sparkles View
struct EmberSparklesView: View {
    private let particles = (0..<24).map { _ in
        Ember(
            id: UUID(),
            x: CGFloat.random(in: 10...380),
            size: CGFloat.random(in: 3...7),
            speed: Double.random(in: 6.0...12.0),
            delay: Double.random(in: 0.0...4.0)
        )
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(particles) { ember in
                    EmberItemView(ember: ember, containerHeight: proxy.size.height)
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct Ember: Identifiable {
    let id: UUID
    let x: CGFloat
    let size: CGFloat
    let speed: Double
    let delay: Double
}

struct EmberItemView: View {
    let ember: Ember
    let containerHeight: CGFloat
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0.85
    @State private var sway: CGFloat = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.65, blue: 0.1), Color(red: 0.95, green: 0.2, blue: 0.0), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: ember.size
                )
            )
            .frame(width: ember.size * 2, height: ember.size * 2)
            .position(x: ember.x + sway, y: containerHeight + 20 - offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .linear(duration: ember.speed)
                    .repeatForever(autoreverses: false)
                    .delay(ember.delay)
                ) {
                    offset = containerHeight + 100
                    opacity = 0.0
                }
                
                withAnimation(
                    .easeInOut(duration: Double.random(in: 2.0...4.0))
                    .repeatForever(autoreverses: true)
                    .delay(ember.delay)
                ) {
                    sway = CGFloat.random(in: -25...25)
                }
            }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
