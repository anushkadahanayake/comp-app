import SwiftUI
import MapKit

/// Map tab: per-game top scores + personal / device-record locations.
struct MapTopScoresSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var statsStore = PlayerStatsStore.shared
    @ObservedObject private var auth = AuthService.shared

    @State private var selectedMode: GameMode = .tapFrenzy

    var onFocusPin: (UUID) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                ArcadeTheme.backgroundDeep.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Top scores on this device. Champion pins show where the best run was played.")
                            .font(.subheadline)
                            .foregroundStyle(ArcadeTheme.textSecondary)

                        Picker("Game", selection: $selectedMode) {
                            ForEach(GameMode.allCases) { mode in
                                Text(shortName(mode)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        locationCards(for: selectedMode)

                        leaderboardSection(for: selectedMode)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Map Top Scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(selectedMode.leaderboardAccent)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func shortName(_ mode: GameMode) -> String {
        switch mode {
        case .tapFrenzy: return "Tap"
        case .lightItUp: return "Light"
        case .quizRush: return "Quiz"
        }
    }

    @ViewBuilder
    private func locationCards(for mode: GameMode) -> some View {
        VStack(spacing: 12) {
            if let playerId = auth.currentPlayer?.id,
               let personal = statsStore.personalBestLocation(for: mode, playerId: playerId) {
                locationCard(
                    title: "Your personal best",
                    subtitle: "\(personal.score) pts · \(mode.rawValue)",
                    icon: "star.circle.fill",
                    accent: ArcadeTheme.accentSoft,
                    pinId: MapPinStableID.personal(mode),
                    date: personal.recordedAt
                )
            } else if auth.currentPlayer != nil {
                emptyLocationCard(
                    title: "Your personal best",
                    message: "Beat your high score with location on to drop a pin."
                )
            }

            if let champion = statsStore.deviceChampionSession(for: mode),
               champion.latitude != nil,
               champion.longitude != nil {
                let name = champion.playerName ?? "Player"
                locationCard(
                    title: "Device record spot",
                    subtitle: "\(name) · \(champion.score) pts",
                    icon: "trophy.fill",
                    accent: mode.leaderboardAccent,
                    pinId: MapPinStableID.champion(mode),
                    date: champion.timestamp
                )
            } else {
                emptyLocationCard(
                    title: "Device record spot",
                    message: "No located champion yet — finish a game with GPS enabled."
                )
            }
        }
    }

    private func locationCard(
        title: String,
        subtitle: String,
        icon: String,
        accent: Color,
        pinId: UUID,
        date: Date
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ArcadeTheme.textSecondary)
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(ArcadeTheme.textTertiary)
                }
                Spacer()
            }

            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onFocusPin(pinId)
                }
            } label: {
                Label("Show on map", systemImage: "map.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(accent.opacity(0.22), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(accent)
            }
        }
        .padding(14)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1)
        )
    }

    private func emptyLocationCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ArcadeTheme.textPrimary)
            Text(message)
                .font(.caption)
                .foregroundStyle(ArcadeTheme.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ArcadeTheme.surfaceMuted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func leaderboardSection(for mode: GameMode) -> some View {
        let entries = statsStore.leaderboard(for: mode, limit: 8)
        let accent = mode.leaderboardAccent

        return VStack(alignment: .leading, spacing: 12) {
            Label("\(mode.rawValue) leaderboard", systemImage: "list.number")
                .font(.headline)
                .foregroundStyle(ArcadeTheme.textPrimary)

            if entries.isEmpty {
                Text("Play this game to appear on the board.")
                    .font(.subheadline)
                    .foregroundStyle(ArcadeTheme.textTertiary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Divider().overlay(ArcadeTheme.border)
                        }
                        HStack(spacing: 12) {
                            Text("#\(entry.rank)")
                                .font(.caption.bold())
                                .foregroundStyle(entry.rank <= 3 ? accent : ArcadeTheme.textTertiary)
                                .frame(width: 28, alignment: .leading)

                            Image(systemName: entry.avatarSymbol)
                                .foregroundStyle(.white)
                                .frame(width: 32, height: 32)
                                .background(accent.opacity(0.28), in: Circle())

                            Text(entry.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ArcadeTheme.textPrimary)

                            if entry.playerId == auth.currentPlayer?.id {
                                Text("YOU")
                                    .font(.caption2.bold())
                                    .foregroundStyle(accent)
                            }

                            Spacer()

                            Text("\(entry.bestScore)")
                                .font(.headline.bold())
                                .foregroundStyle(ArcadeTheme.textPrimary)
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding(.horizontal, 14)
                .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(accent.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

enum MapPinStableID {
    /// Fixed IDs for map selection — must be valid RFC-4122 hex (0–9, A–F only).
    static func champion(_ mode: GameMode) -> UUID {
        switch mode {
        case .tapFrenzy: return uuid("C1000001-0000-4000-8000-000000000001")
        case .lightItUp: return uuid("C1000002-0000-4000-8000-000000000002")
        case .quizRush: return uuid("C1000003-0000-4000-8000-000000000003")
        }
    }

    static func personal(_ mode: GameMode) -> UUID {
        switch mode {
        case .tapFrenzy: return uuid("A1000001-0000-4000-8000-000000000001")
        case .lightItUp: return uuid("A1000002-0000-4000-8000-000000000002")
        case .quizRush: return uuid("A1000003-0000-4000-8000-000000000003")
        }
    }

    private static func uuid(_ string: String) -> UUID {
        guard let id = UUID(uuidString: string) else {
            assertionFailure("Invalid stable map pin UUID: \(string)")
            return UUID()
        }
        return id
    }
}
