import SwiftUI

struct ContentView: View {
    @State private var selectedTab: ArcadeTab = .home
    @ObservedObject private var locationService = LocationService.shared

    var body: some View {
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
        .preferredColorScheme(.dark)
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
