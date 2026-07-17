import SwiftUI

struct ContentView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var selectedTab: ArcadeTab = .home
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
                    NavigationStack { HomeView() }
                case .stats:
                    NavigationStack { StatsView() }
                case .map:
                    NavigationStack { GameMapView() }
                case .settings:
                    NavigationStack { SettingsView() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 72)

            ArcadeTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.keyboard)
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
