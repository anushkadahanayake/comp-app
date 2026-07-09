import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "gamecontroller")
            }
            
            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            
            NavigationStack {
                GameMapView()
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .onAppear {
            // Request location permission immediately on app launch
            LocationService.shared.requestPermission()
        }
    }
}

#Preview {
    ContentView()
}
