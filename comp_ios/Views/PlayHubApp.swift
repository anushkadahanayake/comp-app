import SwiftUI

@main
struct PlayHubApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabs()
        }
    }
}

struct RootTabs: View {
    var body: some View {
        TabView {
            NavigationStack { HomeTab() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { StatsTab() }
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }

            NavigationStack { MapTab() }
                .tabItem { Label("Map", systemImage: "map.fill") }

            NavigationStack { SettingsTab() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
