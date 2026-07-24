import SwiftUI

struct ContentView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var selectedTab: ArcadeTab = .home
    @State private var hideTabBar = false
    @ObservedObject private var locationService = LocationService.shared

    @State private var isLaunchComplete = false
    @State private var showWelcomeTransition = false
    @State private var welcomeDisplayName = ""

    var body: some View {
        ZStack {
            Group {
                if isLaunchComplete {
                    authenticatedRoot
                } else {
                    ArcadeLaunchSplashView()
                }
            }

            if showWelcomeTransition {
                AuthWelcomeTransitionView(displayName: welcomeDisplayName) {
                    showWelcomeTransition = false
                }
                .zIndex(10)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            guard !isLaunchComplete else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.35)) {
                    isLaunchComplete = true
                }
            }
        }
        .onChange(of: auth.isSignedIn) { wasSignedIn, isSignedIn in
            guard isLaunchComplete, isSignedIn, !wasSignedIn else { return }
            presentWelcomeTransition()
        }
    }

    @ViewBuilder
    private var authenticatedRoot: some View {
        if auth.isSignedIn {
            mainShell
        } else {
            LoginView()
        }
    }

    private func presentWelcomeTransition() {
        welcomeDisplayName = auth.currentPlayer?.displayName ?? "Player"
        withAnimation(.easeInOut(duration: 0.25)) {
            showWelcomeTransition = true
        }
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
