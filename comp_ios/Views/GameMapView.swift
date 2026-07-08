import SwiftUI
import MapKit

struct MapPinItem: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let mode: String
}

struct GameMapView: View {
    @ObservedObject var historyManager = SessionHistoryManager.shared
    @ObservedObject var locationManager = LocationManager.shared
    
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPin: MapPinItem?
    
    // Map items from completed sessions
    private var pins: [MapPinItem] {
        historyManager.sessions.compactMap { session -> MapPinItem? in
            guard let lat = session.latitude, let lon = session.longitude else { return nil }
            return MapPinItem(
                id: session.id,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                title: session.mode,
                subtitle: "Score: \(session.score) pts",
                mode: session.mode
            )
        }
    }
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                // Pins for each played session
                ForEach(pins) { pin in
                    Annotation(pin.title, coordinate: pin.coordinate) {
                        Image(systemName: modeIcon(pin.mode))
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.all, 8)
                            .background(modeColor(pin.mode))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.15), radius: 3)
                            .onTapGesture {
                                selectedPin = pin
                            }
                    }
                }
                
                // Show user location dot if authorized
                UserAnnotation()
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
            }
            
            // Selected Pin Details overlay
            if let pin = selectedPin {
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pin.title)
                                .font(.system(.headline, design: .rounded))
                                .bold()
                            Text(pin.subtitle)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selectedPin = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.all, 20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                    .padding(.all, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle("Map of Games")
        .onAppear {
            locationManager.requestPermission()
        }
    }
    
    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Tap Frenzy": return .blue
        case "Light It Up": return .orange
        case "Quiz Rush": return .purple
        default: return .red
        }
    }
    
    private func modeIcon(_ mode: String) -> String {
        switch mode {
        case "Tap Frenzy": return "bolt.fill"
        case "Light It Up": return "lightbulb.fill"
        case "Quiz Rush": return "questionmark.bubble.fill"
        default: return "gamecontroller.fill"
        }
    }
}

#Preview {
    NavigationStack {
        GameMapView()
    }
}
