import SwiftUI

enum ArcadeTab: Int, CaseIterable, Identifiable {
    case home, stats, map, settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .stats: return "Stats"
        case .map: return "Map"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "gamecontroller.fill"
        case .stats: return "chart.bar.fill"
        case .map: return "map.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct ArcadeTabBar: View {
    @Binding var selectedTab: ArcadeTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ArcadeTab.allCases) { tab in
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundStyle(selectedTab == tab ? ArcadeTheme.accent : ArcadeTheme.textTertiary)
                            .frame(height: 26)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedTab == tab ? ArcadeTheme.textPrimary : ArcadeTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selectedTab == tab {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(ArcadeTheme.accentMuted)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(ArcadeTheme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(ArcadeTheme.border, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
