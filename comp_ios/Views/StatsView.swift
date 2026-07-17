import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var historyManager = SessionHistoryManager.shared
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var statsStore = PlayerStatsStore.shared

    private var mySessions: [GameSession] {
        guard let id = auth.currentPlayer?.id else { return [] }
        return historyManager.sessions.filter { $0.playerId == id || $0.playerId == nil }
    }

    private var highScoreTapFrenzy: Int {
        guard let id = auth.currentPlayer?.id else { return 0 }
        return statsStore.highScore(for: .tapFrenzy, playerId: id)
    }

    private var highScoreLightItUp: Int {
        guard let id = auth.currentPlayer?.id else { return 0 }
        return statsStore.highScore(for: .lightItUp, playerId: id)
    }

    private var highScoreQuizRush: Int {
        guard let id = auth.currentPlayer?.id else { return 0 }
        return statsStore.highScore(for: .quizRush, playerId: id)
    }

    private var totalPoints: Int {
        mySessions.reduce(0) { $0 + $1.score }
    }

    private var gamesPlayed: Int { mySessions.count }

    private var averageScore: Int {
        guard gamesPlayed > 0 else { return 0 }
        return totalPoints / gamesPlayed
    }

    private var favoriteMode: String {
        let counts = Dictionary(grouping: mySessions, by: \.mode).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "—"
    }

    private var leaderboard: [LeaderboardEntry] {
        _ = statsStore.revision
        _ = historyManager.sessions.count
        return statsStore.leaderboard()
    }

    private var rank: (title: String, icon: String, nextAt: Int, progress: Double) {
        if totalPoints < 100 {
            return ("Neon Cadet", "shield.fill", 100, Double(totalPoints) / 100)
        } else if totalPoints < 500 {
            return ("Pixel Warrior", "bolt.shield.fill", 500, Double(totalPoints - 100) / 400)
        } else if totalPoints < 2000 {
            return ("Arcade Champion", "trophy.fill", 2000, Double(totalPoints - 500) / 1500)
        } else {
            return ("Retro Legend", "crown.fill", totalPoints, 1)
        }
    }

    var body: some View {
        ZStack {
            ArcadeTheme.backgroundDeep
                .ignoresSafeArea()

            // Soft blue ambient glow
            Circle()
                .fill(ArcadeTheme.accent.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 50)
                .offset(x: 120, y: -180)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    profileCard
                    leaderboardCard
                    summaryGrid
                    personalBestsCard
                    chartsSection
                    recentGamesCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Profile

    private var profileCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(ArcadeTheme.brandGradient)
                        .frame(width: 72, height: 72)

                    Image(systemName: auth.currentPlayer?.avatarSymbol ?? rank.icon)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(auth.currentPlayer?.displayName ?? "Player")
                        .font(.title3.bold())
                        .foregroundStyle(ArcadeTheme.textPrimary)

                    Text("\(rank.title) · \(totalPoints) XP")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ArcadeTheme.textSecondary)

                    if let username = auth.currentPlayer?.username {
                        Text("@\(username)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(ArcadeTheme.accentSoft)
                    }

                    if rank.progress < 1 {
                        VStack(alignment: .leading, spacing: 4) {
                            ProgressView(value: min(max(rank.progress, 0), 1))
                                .tint(ArcadeTheme.accent)
                            Text("\(max(0, rank.nextAt - totalPoints)) XP to next rank")
                                .font(.caption2)
                                .foregroundStyle(ArcadeTheme.textTertiary)
                        }
                    } else {
                        Text("Max rank unlocked")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(ArcadeTheme.accentSoft)
                    }
                }

                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ArcadeTheme.borderStrong, lineWidth: 1)
        )
    }

    // MARK: - Leaderboard

    private var leaderboardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Top Players", icon: "trophy.fill")

            if leaderboard.isEmpty {
                Text("Play a few games to build the leaderboard.")
                    .font(.subheadline)
                    .foregroundStyle(ArcadeTheme.textSecondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(leaderboard.prefix(8).enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Divider().overlay(ArcadeTheme.border)
                        }
                        leaderboardRow(entry)
                    }
                }
            }
        }
        .padding(16)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(ArcadeTheme.borderStrong, lineWidth: 1)
        )
    }

    private func leaderboardRow(_ entry: LeaderboardEntry) -> some View {
        let isMe = entry.playerId == auth.currentPlayer?.id
        return HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.caption.bold())
                .foregroundStyle(entry.rank <= 3 ? ArcadeTheme.accentSoft : ArcadeTheme.textTertiary)
                .frame(width: 28, alignment: .leading)

            Image(systemName: entry.avatarSymbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(ArcadeTheme.accent.opacity(isMe ? 0.55 : 0.28), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                    if isMe {
                        Text("YOU")
                            .font(.caption2.bold())
                            .foregroundStyle(ArcadeTheme.accentSoft)
                    }
                }
                Text("\(entry.gamesPlayed) games · best \(entry.bestScore)")
                    .font(.caption2)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalXP)")
                    .font(.subheadline.bold())
                    .foregroundStyle(ArcadeTheme.textPrimary)
                Text("XP")
                    .font(.caption2)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            }
        }
        .padding(.vertical, 10)
    }

    // MARK: - Summary

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryTile(title: "Games", value: "\(gamesPlayed)", icon: "gamecontroller.fill", color: ArcadeTheme.accent)
            summaryTile(title: "Total Points", value: "\(totalPoints)", icon: "star.fill", color: ArcadeTheme.accentSoft)
            summaryTile(title: "Avg Score", value: "\(averageScore)", icon: "chart.line.uptrend.xyaxis", color: ArcadeTheme.accentSecondary)
            summaryTile(title: "Favorite", value: shortModeName(favoriteMode), icon: "heart.fill", color: ArcadeTheme.success)
        }
    }

    private func summaryTile(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(ArcadeTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ArcadeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ArcadeTheme.border, lineWidth: 1)
        )
    }

    // MARK: - Personal Bests

    private var personalBestsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Personal Bests", icon: "medal.fill")

            VStack(spacing: 0) {
                personalBestRow(
                    title: "Tap Frenzy",
                    icon: "bolt.fill",
                    score: highScoreTapFrenzy,
                    color: ArcadeTheme.tapFrenzy
                )
                Divider().overlay(ArcadeTheme.border)
                personalBestRow(
                    title: "Light It Up",
                    icon: "lightbulb.fill",
                    score: highScoreLightItUp,
                    color: ArcadeTheme.lightItUp
                )
                Divider().overlay(ArcadeTheme.border)
                personalBestRow(
                    title: "Quiz Rush",
                    icon: "questionmark.circle.fill",
                    score: highScoreQuizRush,
                    color: ArcadeTheme.quizRush
                )
            }
            .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(ArcadeTheme.border, lineWidth: 1)
            )
        }
    }

    private func personalBestRow(title: String, icon: String, score: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15), in: Circle())

            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(ArcadeTheme.textPrimary)

            Spacer()

            Text("\(score)")
                .font(.headline.bold())
                .foregroundStyle(color)

            Text("pts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ArcadeTheme.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    // MARK: - Charts

    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Performance", icon: "chart.bar.fill")

            ModeBarChart(
                title: "Tap Frenzy",
                sessions: mySessions.filter { $0.mode == "Tap Frenzy" },
                color: ArcadeTheme.tapFrenzy
            )

            ModeBarChart(
                title: "Light It Up",
                sessions: mySessions.filter { $0.mode == "Light It Up" },
                color: ArcadeTheme.lightItUp
            )

            ModeBarChart(
                title: "Quiz Rush",
                sessions: mySessions.filter { $0.mode == "Quiz Rush" },
                color: ArcadeTheme.quizRush
            )
        }
    }

    // MARK: - Recent

    private var recentGamesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Recent Games", icon: "clock.fill")

            if mySessions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(mySessions.reversed().prefix(10).enumerated()), id: \.element.id) { index, session in
                        recentRow(session)
                        if index < min(9, mySessions.count - 1) {
                            Divider().overlay(ArcadeTheme.border)
                        }
                    }
                }
                .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ArcadeTheme.border, lineWidth: 1)
                )
            }
        }
    }

    private func recentRow(_ session: GameSession) -> some View {
        let color = modeColor(session.mode)
        return HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 10, height: 10)
                .overlay(Circle().strokeBorder(color.opacity(0.7), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(session.mode)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ArcadeTheme.textPrimary)
                Text(formatDate(session.timestamp))
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            }

            Spacer()

            Text("\(session.score) pts")
                .font(.subheadline.bold())
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color.opacity(0.12), in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 28))
                .foregroundStyle(ArcadeTheme.accentSecondary)
            Text("No games yet")
                .font(.headline)
                .foregroundStyle(ArcadeTheme.textPrimary)
            Text("Finish a run to see your stats here.")
                .font(.caption)
                .foregroundStyle(ArcadeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ArcadeTheme.border, lineWidth: 1)
        )
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(ArcadeTheme.accent)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ArcadeTheme.textSecondary)
        }
        .padding(.leading, 4)
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Tap Frenzy": return ArcadeTheme.tapFrenzy
        case "Light It Up": return ArcadeTheme.lightItUp
        case "Quiz Rush": return ArcadeTheme.quizRush
        default: return ArcadeTheme.accent
        }
    }

    private func shortModeName(_ mode: String) -> String {
        switch mode {
        case "Tap Frenzy": return "Tap"
        case "Light It Up": return "Light"
        case "Quiz Rush": return "Quiz"
        default: return mode == "—" ? "—" : mode
        }
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - Bar Chart Component
struct ModeBarChart: View {
    let title: String
    let sessions: [GameSession]
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ArcadeTheme.textPrimary)
                Spacer()
                Text(sessions.isEmpty ? "No data" : "Last \(min(6, sessions.count))")
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            }

            if sessions.isEmpty {
                Text("Play this mode to unlock the chart.")
                    .font(.caption)
                    .foregroundStyle(ArcadeTheme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 20)
            } else {
                let suffixData = Array(sessions.suffix(6))
                Chart {
                    ForEach(Array(suffixData.enumerated()), id: \.offset) { index, session in
                        BarMark(
                            x: .value("Game", index + 1),
                            y: .value("Score", session.score)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.55)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                        .annotation(position: .top) {
                            Text("\(session.score)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(color)
                        }
                    }
                }
                .frame(height: 130)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(ArcadeTheme.border)
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("G\(intVal)")
                                    .foregroundStyle(ArcadeTheme.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                            .foregroundStyle(ArcadeTheme.border)
                        AxisValueLabel()
                            .foregroundStyle(ArcadeTheme.textTertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
}
