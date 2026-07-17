import SwiftUI
import Combine

struct HomeView: View {
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0

    private let games = ArcadeGame.all

    /// TabView page index. Includes an extra trailing clone of game 0 for circular wrap.
    @State private var carouselPage = 0
    @State private var isAutoScrolling = true
    @State private var isProgrammaticSelection = false
    @State private var resumeAutoScrollWork: DispatchWorkItem?
    @State private var animateHeader = false
    @State private var animateCarousel = false
    /// Frozen game mode used for navigation — never changes while a game is open.
    @State private var activeGameMode: GameMode?

    private let autoScrollTimer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    /// Real game index (0..<games.count), mapped from the looping carousel page.
    private var selectedIndex: Int {
        carouselPage % games.count
    }

    private var selectedGame: ArcadeGame {
        games[selectedIndex]
    }

    /// Last TabView page is a clone of the first game — used for seamless forward wrap.
    private var loopClonePage: Int { games.count }

    /// True while a game screen is pushed — blocks carousel auto-advance.
    private var isPlayingGame: Bool { activeGameMode != nil }

    private func highScore(for game: ArcadeGame) -> Int {
        switch game.mode {
        case .tapFrenzy: return highScoreTapFrenzy
        case .lightItUp: return highScoreLightItUp
        case .quizRush: return highScoreQuizRush
        }
    }

    var body: some View {
        ZStack {
            ZStack {
                LavaPlasmaBackgroundView()
                EmberSparklesView()
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerSection
                    gameLibrarySection
                    carouselSection
                    gamePickerSection
                    selectedGameDetailsSection
                    playButtonSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .navigationDestination(item: $activeGameMode) { mode in
            // Destination is locked to the mode chosen at tap time — each game stays separate.
            gameDestination(for: mode)
        }
        .onAppear {
            migrateLegacyHighScore()
            // Resume browsing carousel only when back on Home (not while a game is open).
            if !isPlayingGame {
                isAutoScrolling = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                animateHeader = true
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.72).delay(0.15)) {
                animateCarousel = true
            }
        }
        .onDisappear {
            // Keep Home carousel frozen under a pushed game so selection can't swap mid-play.
            stopAutoScroll()
        }
        .onReceive(autoScrollTimer) { _ in
            guard isAutoScrolling, !isPlayingGame, games.count > 1 else { return }
            advanceCarouselCircular()
        }
    }

    @ViewBuilder
    private func gameDestination(for mode: GameMode) -> some View {
        switch mode {
        case .tapFrenzy:
            TapFrenzyView()
        case .lightItUp:
            LightItUpView()
        case .quizRush:
            QuizRushView()
        }
    }

    /// Opens exactly one game and freezes the carousel until the user returns.
    private func openGame(_ mode: GameMode) {
        stopAutoScroll()
        activeGameMode = mode
    }

    private func stopAutoScroll() {
        isAutoScrolling = false
        resumeAutoScrollWork?.cancel()
        resumeAutoScrollWork = nil
    }

    /// Always moves forward: 0 → 1 → 2 → clone(0), then snaps to 0 without reverse scroll.
    private func advanceCarouselCircular() {
        isProgrammaticSelection = true

        // If somehow still on the clone page, snap first then continue.
        if carouselPage >= loopClonePage {
            normalizeCarouselIfNeeded()
        }

        withAnimation(.easeInOut(duration: 0.45)) {
            carouselPage = min(carouselPage + 1, loopClonePage)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            normalizeCarouselIfNeeded()
            isProgrammaticSelection = false
        }
    }

    private func selectGame(at index: Int, programmatic: Bool) {
        let clamped = max(0, min(index, games.count - 1))
        guard clamped != selectedIndex || carouselPage == loopClonePage else { return }

        isProgrammaticSelection = programmatic
        withAnimation(.easeInOut(duration: programmatic ? 0.45 : 0.35)) {
            carouselPage = clamped
        }

        if programmatic {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isProgrammaticSelection = false
            }
        } else {
            pauseAutoScrollTemporarily()
        }
    }

    /// After landing on the cloned first page, jump to the real first page with no animation.
    private func normalizeCarouselIfNeeded() {
        guard carouselPage >= loopClonePage else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            carouselPage = 0
        }
    }

    private func pauseAutoScrollTemporarily() {
        guard !isPlayingGame else { return }
        isAutoScrolling = false
        resumeAutoScrollWork?.cancel()
        let work = DispatchWorkItem {
            // Timer handler also checks isPlayingGame, so a late resume is safe.
            isAutoScrolling = true
        }
        resumeAutoScrollWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 6, execute: work)
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: .cyan.opacity(0.6), radius: 20)

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .scaleEffect(animateHeader ? 1.0 : 0.5)
            .opacity(animateHeader ? 1.0 : 0.0)

            Text("ARCADE FRENZY")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.black)
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: .cyan.opacity(0.5), radius: 10)
                .offset(y: animateHeader ? 0 : -20)
                .opacity(animateHeader ? 1.0 : 0.0)

            Text("TAP SPEED • REFLEX • TRIVIA RUSH")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.cyan)
                .tracking(3)
                .opacity(animateHeader ? 1.0 : 0.0)
        }
        .padding(.top, 24)
    }

    private var gameLibrarySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game Library")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Tap a game image to play • 3 separate games")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Text("\(games.count) Games")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.15))
                )
        }
        .opacity(animateCarousel ? 1 : 0)
        .offset(y: animateCarousel ? 0 : 20)
    }

    private var carouselSection: some View {
        VStack(spacing: 14) {
            TabView(selection: $carouselPage) {
                ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                    Button {
                        openGame(game.mode)
                    } label: {
                        GameHeroCard(game: game, isSelected: selectedIndex == index)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .tag(index)
                }

                // Extra copy of the first game so wrap always animates forward (circular).
                if let first = games.first {
                    Button {
                        openGame(first.mode)
                    } label: {
                        GameHeroCard(game: first, isSelected: selectedIndex == 0)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 8)
                    .tag(loopClonePage)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 260)
            .onChange(of: carouselPage) { _, newPage in
                if newPage >= loopClonePage {
                    // User swiped onto the clone page — snap to real first without reverse scroll.
                    if !isProgrammaticSelection {
                        pauseAutoScrollTemporarily()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            normalizeCarouselIfNeeded()
                        }
                    }
                    // Auto-scroll snap is handled in advanceCarouselCircular after the forward animation.
                    return
                }

                if !isProgrammaticSelection {
                    pauseAutoScrollTemporarily()
                }
            }

            HStack(spacing: 8) {
                ForEach(Array(games.enumerated()), id: \.element.id) { index, _ in
                    Capsule()
                        .fill(index == selectedIndex ? Color.cyan : Color.white.opacity(0.25))
                        .frame(width: index == selectedIndex ? 24 : 8, height: 8)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }

            Text("\(selectedIndex + 1) of \(games.count) • \(selectedGame.title)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .opacity(animateCarousel ? 1 : 0)
        .offset(y: animateCarousel ? 0 : 30)
    }

    private var gamePickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                    Button {
                        selectGame(at: index, programmatic: false)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: game.icon)
                            Text(game.title)
                                .lineLimit(1)
                        }
                        .font(.caption.bold())
                        .foregroundStyle(selectedIndex == index ? .white : .white.opacity(0.75))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(
                                    selectedIndex == index
                                        ? LinearGradient(colors: game.gradient, startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(.white.opacity(selectedIndex == index ? 0.25 : 0.08))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var selectedGameDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedGame.title)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(selectedGame.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("BEST")
                        .font(.caption2.bold())
                        .foregroundStyle(.cyan)
                    Text("\(highScore(for: selectedGame))")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 10) {
                Label(isAutoScrolling ? "Auto-scroll on" : "Auto-scroll paused", systemImage: isAutoScrolling ? "play.circle.fill" : "pause.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text("Tap image or Play — opens only that game")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.08))
        )
    }

    private var playButtonSection: some View {
        Button {
            openGame(selectedGame.mode)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "play.fill")
                Text("Play \(selectedGame.title)")
                    .fontWeight(.bold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: selectedGame.gradient, startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: selectedGame.gradient.first?.opacity(0.35) ?? .clear, radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func migrateLegacyHighScore() {
        let savedFrenzy = UserDefaults.standard.integer(forKey: "HighScore_TapFrenzy")
        if savedFrenzy == 0 {
            let old = UserDefaults.standard.integer(forKey: "HighScoreKey")
            if old > 0 {
                highScoreTapFrenzy = old
            }
        }
    }
}

struct GameHeroCard: View {
    let game: ArcadeGame
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if UIImage(named: game.imageName) != nil {
                    Image(game.imageName)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(colors: game.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(game.title, systemImage: game.icon)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.35), in: Capsule())

                    Spacer()

                    Text(isSelected ? "TAP TO PLAY" : "TAP")
                        .font(.caption2.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isSelected ? Color.cyan : Color.white.opacity(0.85), in: Capsule())
                }

                Text(game.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text(game.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
            }
            .padding(18)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isSelected ? Color.cyan.opacity(0.8) : .white.opacity(0.10), lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isSelected ? 1.0 : 0.96)
        .animation(.spring(response: 0.4, dampingFraction: 0.82), value: isSelected)
        .shadow(color: .black.opacity(isSelected ? 0.45 : 0.25), radius: isSelected ? 18 : 10, y: 10)
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
                Circle()
                    .fill(Color(red: 0.75, green: 0.05, blue: 0.05).opacity(0.42))
                    .frame(width: 360, height: 360)
                    .offset(x: animateBlob1 ? -70 : 70, y: animateBlob1 ? -110 : 110)
                    .scaleEffect(animateBlob1 ? 1.12 : 0.88)
                    .blur(radius: 60)

                Circle()
                    .fill(Color(red: 0.95, green: 0.3, blue: 0.0).opacity(0.38))
                    .frame(width: 320, height: 320)
                    .offset(x: animateBlob2 ? 80 : -80, y: animateBlob2 ? 60 : -60)
                    .scaleEffect(animateBlob2 ? 0.92 : 1.15)
                    .blur(radius: 50)

                Circle()
                    .fill(Color(red: 0.95, green: 0.65, blue: 0.0).opacity(0.28))
                    .frame(width: 270, height: 270)
                    .offset(x: animateBlob3 ? -90 : 90, y: animateBlob3 ? 70 : -70)
                    .scaleEffect(animateBlob3 ? 1.2 : 0.85)
                    .blur(radius: 45)

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
