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

    var accent: Color {
        switch self {
        case .home: return .cyan
        case .stats: return .purple
        case .map: return .orange
        case .settings: return .mint
        }
    }
}

struct ArcadeTabBar: View {
    @Binding var selectedTab: ArcadeTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ArcadeTab.allCases) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        ZStack {
                            if selectedTab == tab {
                                Circle()
                                    .fill(tab.accent.opacity(0.22))
                                    .frame(width: 44, height: 44)
                                    .blur(radius: 0.5)

                                Circle()
                                    .stroke(tab.accent.opacity(0.55), lineWidth: 1)
                                    .frame(width: 44, height: 44)
                            }

                            Image(systemName: tab.icon)
                                .font(.system(size: selectedTab == tab ? 20 : 18, weight: .semibold))
                                .foregroundStyle(selectedTab == tab ? tab.accent : .white.opacity(0.45))
                                .shadow(color: selectedTab == tab ? tab.accent.opacity(0.7) : .clear, radius: 8)
                        }
                        .frame(height: 44)

                        Text(tab.title)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedTab == tab ? tab.accent : .white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.cyan.opacity(0.06),
                                    Color.purple.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.cyan.opacity(0.45), .purple.opacity(0.35), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .cyan.opacity(0.18), radius: 16, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}
