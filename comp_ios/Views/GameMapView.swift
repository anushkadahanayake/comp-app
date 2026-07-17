import SwiftUI
import MapKit
import CoreLocation

struct MapPinItem: Identifiable, Hashable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let title: String
    let subtitle: String
    let mode: String
    let date: Date

    var coordinate: CLLocationCoordinate2D {
        AFCoordinateMake(latitude, longitude)
    }

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

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedPinId: UUID?
    @State private var selectedPin: MapPinItem?

    private var pins: [MapPinItem] {
        historyManager.sessions.compactMap { session -> MapPinItem? in
            guard let lat = session.latitude, let lon = session.longitude else { return nil }
            return MapPinItem(
                id: session.id,
                latitude: lat,
                longitude: lon,
                title: session.mode,
                subtitle: "Score: \(session.score) pts",
                mode: session.mode,
                date: session.timestamp
            )
        }
    }

    var body: some View {
        ZStack {
            Map(position: $position, selection: $selectedPinId) {
                ForEach(pins) { pin in
                    Marker(pin.title, coordinate: pin.coordinate)
                        .tint(modeColor(pin.mode))
                        .tag(pin.id)
                }

                if locationService.isAuthorized {
                    UserAnnotation()
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll, elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                if locationService.isDenied {
                    permissionBanner
                } else if pins.isEmpty {
                    emptyStateBanner
                }

                Spacer()

                if let pin = selectedPin {
                    pinDetailCard(pin)
                }

                mapToolbar
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .navigationTitle("Map of Games")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            locationService.refreshLocation()
            fitMapContent()
        }
        .onChange(of: selectedPinId) { _, newId in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedPin = pins.first(where: { $0.id == newId })
            }
            if let pin = pins.first(where: { $0.id == newId }) {
                withAnimation {
                    position = .region(
                        MKCoordinateRegion(
                            center: pin.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
        .onChange(of: historyManager.sessions.count) { _, _ in
            fitMapContent()
        }
        .onChange(of: locationService.authorizationStatus) { _, _ in
            if locationService.isAuthorized {
                locationService.startUpdating()
                fitMapContent()
            }
        }
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Location Access Needed", systemImage: "location.slash.fill")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Enable location so finished games can appear as pins on this map.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Button {
                locationService.openSystemSettings()
            } label: {
                Text("Open Settings")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.orange, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.5))
        )
    }

    private var emptyStateBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("No Game Pins Yet", systemImage: "mappin.slash")
                .font(.headline)
                .foregroundStyle(.white)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.cyan.opacity(0.35))
        )
    }

    private var emptyStateMessage: String {
        if !locationService.isAuthorized {
            return "Allow location access, then finish a game to drop your first pin."
        }
        if !locationService.hasFix {
            return "Waiting for a GPS fix. Play a game outdoors or set a simulated location in the Simulator."
        }
        return "Finish any game to drop a pin at your current location."
    }

    private func pinDetailCard(_ pin: MapPinItem) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(modeColor(pin.mode))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(pin.title)
                    .font(.system(.headline, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
                Text(pin.subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                Text(pin.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                selectedPinId = nil
                selectedPin = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(modeColor(pin.mode).opacity(0.45))
        )
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var mapToolbar: some View {
        HStack(spacing: 12) {
            Button {
                fitMapContent()
            } label: {
                Label(pins.isEmpty ? "My Location" : "Show All Pins", systemImage: pins.isEmpty ? "location.fill" : "map.fill")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.35)))
            }
            .foregroundStyle(.cyan)

            Spacer()

            Text("\(pins.count) pin\(pins.count == 1 ? "" : "s")")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.purple.opacity(0.55)))
        }
    }

    private func fitMapContent() {
        if !pins.isEmpty {
            let coordinates = pins.map(\.coordinate)
            var rect = MKMapRect.null
            for coordinate in coordinates {
                let point = MKMapPoint(coordinate)
                let pointRect = MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1)
                rect = rect.union(pointRect)
            }
            // Pad the rect a bit
            rect = rect.insetBy(dx: -rect.size.width * 0.35, dy: -rect.size.height * 0.35)
            withAnimation(.easeInOut(duration: 0.4)) {
                position = .rect(rect)
            }
        } else if let coordinate = locationService.currentCoordinate {
            withAnimation(.easeInOut(duration: 0.4)) {
                position = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                    )
                )
            }
        } else {
            position = .userLocation(fallback: .automatic)
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
