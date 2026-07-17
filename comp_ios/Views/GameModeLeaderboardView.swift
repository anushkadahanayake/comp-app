import SwiftUI

/// Compact in-game top scores for one mode (idle / lobby / results).
struct GameModeLeaderboardCard: View {
    let mode: GameMode
    var limit: Int = 5

    @ObservedObject private var statsStore = PlayerStatsStore.shared
    @ObservedObject private var historyManager = SessionHistoryManager.shared
    @ObservedObject private var auth = AuthService.shared

    private var entries: [LeaderboardEntry] {
        _ = statsStore.revision
        _ = historyManager.sessions.count
        return statsStore.leaderboard(for: mode, limit: limit)
    }

    private var accent: Color { mode.leaderboardAccent }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(accent)
                Text("\(mode.rawValue) Top Scores")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }

            if entries.isEmpty {
                Text("Be the first on this board — play a round!")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.vertical, 4)
            } else {
                ForEach(entries) { entry in
                    row(entry)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accent.opacity(0.4), lineWidth: 1)
        )
    }

    private func row(_ entry: LeaderboardEntry) -> some View {
        let isMe = entry.playerId == auth.currentPlayer?.id
        return HStack(spacing: 10) {
            Text("#\(entry.rank)")
                .font(.caption.bold())
                .foregroundStyle(entry.rank <= 3 ? accent : .white.opacity(0.45))
                .frame(width: 26, alignment: .leading)

            Text(entry.displayName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            if isMe {
                Text("YOU")
                    .font(.caption2.bold())
                    .foregroundStyle(accent)
            }

            Spacer()

            Text("\(entry.bestScore)")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}

/// Full-screen sheet leaderboard opened from a game toolbar.
struct GameModeLeaderboardSheet: View {
    let mode: GameMode
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var statsStore = PlayerStatsStore.shared
    @ObservedObject private var historyManager = SessionHistoryManager.shared
    @ObservedObject private var auth = AuthService.shared

    private var entries: [LeaderboardEntry] {
        _ = statsStore.revision
        _ = historyManager.sessions.count
        return statsStore.leaderboard(for: mode, limit: 15)
    }

    private var accent: Color { mode.leaderboardAccent }

    var body: some View {
        NavigationStack {
            ZStack {
                ArcadeTheme.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Best scores for \(mode.rawValue) on this device.")
                            .font(.subheadline)
                            .foregroundStyle(ArcadeTheme.textSecondary)

                        if entries.isEmpty {
                            Text("No scores yet. Finish a game to appear here.")
                                .font(.body)
                                .foregroundStyle(ArcadeTheme.textTertiary)
                                .padding(.top, 24)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                    if index > 0 {
                                        Divider().overlay(ArcadeTheme.border)
                                    }
                                    sheetRow(entry)
                                }
                            }
                            .padding(14)
                            .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(accent.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("\(mode.rawValue) Leaders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func sheetRow(_ entry: LeaderboardEntry) -> some View {
        let isMe = entry.playerId == auth.currentPlayer?.id
        return HStack(spacing: 12) {
            Text("#\(entry.rank)")
                .font(.subheadline.bold())
                .foregroundStyle(entry.rank <= 3 ? accent : ArcadeTheme.textTertiary)
                .frame(width: 36, alignment: .leading)

            Image(systemName: entry.avatarSymbol)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(accent.opacity(isMe ? 0.55 : 0.28), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                    if isMe {
                        Text("YOU")
                            .font(.caption2.bold())
                            .foregroundStyle(accent)
                    }
                }
                Text("\(entry.gamesPlayed) games played")
                    .font(.caption2)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.bestScore)")
                    .font(.title3.bold())
                    .foregroundStyle(ArcadeTheme.textPrimary)
                Text("Best")
                    .font(.caption2)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            }
        }
        .padding(.vertical, 10)
    }
}

extension GameMode {
    var leaderboardAccent: Color {
        switch self {
        case .tapFrenzy: return ArcadeTheme.tapFrenzy
        case .lightItUp: return ArcadeTheme.lightItUp
        case .quizRush: return ArcadeTheme.quizRush
        }
    }
}
