import SwiftUI
import MapKit

struct MapPinItem: Identifiable, Hashable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
    let mode: String
    
    static func == (lhs: MapPinItem, rhs: MapPinItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct GameMapView: View {
    @ObservedObject var historyManager = SessionHistoryManager.shared
    @ObservedObject var locationService = LocationService.shared
    
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedPinId: UUID?
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
            Map(position: $position, selection: $selectedPinId) {
                // Pins for each played session using standard MapKit Markers
                ForEach(pins) { pin in
                    Marker(pin.title, coordinate: pin.coordinate)
                        .tint(modeColor(pin.mode))
                        .tag(pin.id)
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
                            selectedPinId = nil
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
        .onChange(of: selectedPinId) { newId in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedPin = pins.first(where: { $0.id == newId })
            }
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
}

#Preview {
    NavigationStack {
        GameMapView()
    }
}
