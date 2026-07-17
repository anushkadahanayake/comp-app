import SwiftUI

struct ContentView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var selectedTab: ArcadeTab = .home
    /// Hidden while a game is pushed so HUD / results are not cramped by the tab bar.
    @State private var hideTabBar = false
    @ObservedObject private var locationService = LocationService.shared

    var body: some View {
        Group {
            if auth.isSignedIn {
                mainShell
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var mainShell: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack { HomeView(hideTabBar: $hideTabBar) }
                case .stats:
                    NavigationStack { StatsView() }
                case .map:
                    NavigationStack { GameMapView() }
                case .settings:
                    NavigationStack { SettingsView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, hideTabBar ? 0 : 72)

            if !hideTabBar {
                ArcadeTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { _, _ in
            hideTabBar = false
        }
        .onAppear {
            locationService.requestPermission()
            locationService.startUpdating()
            NotificationService.shared.checkAuthorizationStatus()
        }
    }
}

#Preview {
    ContentView()
}
