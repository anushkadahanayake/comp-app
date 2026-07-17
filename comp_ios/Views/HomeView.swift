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
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ArcadeTheme.borderStrong, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
                .scaleEffect(animateHeader ? 1.0 : 0.5)
                .opacity(animateHeader ? 1.0 : 0.0)

            Text("ARCADE FRENZY")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.heavy)
                .foregroundStyle(ArcadeTheme.textPrimary)
                .offset(y: animateHeader ? 0 : -20)
                .opacity(animateHeader ? 1.0 : 0.0)

            Text("Tap · Reflex · Trivia")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(ArcadeTheme.textSecondary)
                .opacity(animateHeader ? 1.0 : 0.0)
        }
        .padding(.top, 24)
    }

    private var gameLibrarySection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game Library")
                    .font(.title3.bold())
                    .foregroundStyle(ArcadeTheme.textPrimary)
                Text("Tap a game card to play")
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textSecondary)
            }

            Spacer()

            Text("\(games.count) Games")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ArcadeTheme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ArcadeTheme.surfaceElevated, in: Capsule())
                .overlay(Capsule().strokeBorder(ArcadeTheme.border))
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
                        .fill(index == selectedIndex ? ArcadeTheme.accent : ArcadeTheme.textTertiary.opacity(0.5))
                        .frame(width: index == selectedIndex ? 22 : 7, height: 7)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }

            Text("\(selectedIndex + 1) of \(games.count) • \(selectedGame.title)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ArcadeTheme.textSecondary)
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(selectedIndex == index ? ArcadeTheme.backgroundDeep : ArcadeTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(selectedIndex == index ? ArcadeTheme.accent : ArcadeTheme.surfaceElevated)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(ArcadeTheme.border)
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
                        .foregroundStyle(ArcadeTheme.textPrimary)
                    Text(selectedGame.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ArcadeTheme.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("BEST")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(ArcadeTheme.accent)
                    Text("\(highScore(for: selectedGame))")
                        .font(.title3.bold())
                        .foregroundStyle(ArcadeTheme.textPrimary)
                }
            }

            HStack(spacing: 10) {
                Label(isAutoScrolling ? "Auto-scroll on" : "Auto-scroll paused", systemImage: isAutoScrolling ? "play.circle.fill" : "pause.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textTertiary)

                Spacer()

                Text("Tap card or Play")
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            }
        }
        .padding(16)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ArcadeTheme.border)
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
            .foregroundStyle(ArcadeTheme.backgroundDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(ArcadeTheme.brandGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: ArcadeTheme.accent.opacity(0.25), radius: 10, y: 4)
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
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(ArcadeTheme.backgroundDeep)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(isSelected ? ArcadeTheme.accent : Color.white.opacity(0.9), in: Capsule())
                }

                Text(game.title)
                    .font(.title.bold())
                    .foregroundStyle(ArcadeTheme.textPrimary)

                Text(game.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ArcadeTheme.textSecondary)
            }
            .padding(18)
        }
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isSelected ? ArcadeTheme.accent.opacity(0.7) : ArcadeTheme.border, lineWidth: isSelected ? 1.5 : 1)
        )
        .scaleEffect(isSelected ? 1.0 : 0.97)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .shadow(color: .black.opacity(0.28), radius: isSelected ? 14 : 8, y: 6)
    }
}

// MARK: - Soft ambient background (eye-friendly, low saturation)
struct LavaPlasmaBackgroundView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ArcadeTheme.backgroundDeep
                .ignoresSafeArea()

            Circle()
                .fill(ArcadeTheme.ambientA)
                .frame(width: 340, height: 340)
                .offset(x: animate ? -40 : 50, y: animate ? -90 : -40)
                .blur(radius: 70)

            Circle()
                .fill(ArcadeTheme.ambientB)
                .frame(width: 300, height: 300)
                .offset(x: animate ? 60 : -40, y: animate ? 80 : 40)
                .blur(radius: 65)

            Circle()
                .fill(ArcadeTheme.ambientC)
                .frame(width: 240, height: 240)
                .offset(x: animate ? -30 : 40, y: animate ? 20 : -60)
                .blur(radius: 55)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

// Soft dust motes — much quieter than neon embers
struct EmberSparklesView: View {
    private let particles = (0..<10).map { _ in
        Ember(
            id: UUID(),
            x: CGFloat.random(in: 10...380),
            size: CGFloat.random(in: 2...4),
            speed: Double.random(in: 8.0...14.0),
            delay: Double.random(in: 0.0...5.0)
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
        .allowsHitTesting(false)
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
    @State private var opacity: Double = 0.35

    var body: some View {
        Circle()
            .fill(ArcadeTheme.accent.opacity(0.45))
            .frame(width: ember.size, height: ember.size)
            .position(x: ember.x, y: containerHeight + 20 - offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .linear(duration: ember.speed)
                    .repeatForever(autoreverses: false)
                    .delay(ember.delay)
                ) {
                    offset = containerHeight + 80
                    opacity = 0.0
                }
            }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
