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

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: LocationService.sriLankaFallback,
            span: MKCoordinateSpan(latitudeDelta: 2.8, longitudeDelta: 2.8)
        )
    )
    @State private var selectedPinId: UUID?
    @State private var selectedPin: MapPinItem?
    @State private var didAutoCenterOnUser = false

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

    /// Pins far from the live GPS (often Simulator / old US test data).
    private var pinsLookRemote: Bool {
        guard let lat = locationService.currentLatitude,
              let lon = locationService.currentLongitude,
              !pins.isEmpty else { return false }
        let userLoc = CLLocation(latitude: lat, longitude: lon)
        return pins.contains { pin in
            let pinLoc = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
            return userLoc.distance(from: pinLoc) > 500_000 // 500 km
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
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea(edges: .top)

            VStack(spacing: 12) {
                if locationService.isDenied {
                    permissionBanner
                } else if pinsLookRemote {
                    remotePinsBanner
                } else if pins.isEmpty {
                    emptyStateBanner
                }

                Spacer()

                if let place = locationService.placeLabel ?? locationService.coordinateLabel {
                    locationChip(place)
                }

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
            centerOnUser(animated: false)
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
        .onChange(of: locationService.currentLatitude) { _, newLat in
            guard newLat != nil, !didAutoCenterOnUser else { return }
            didAutoCenterOnUser = true
            centerOnUser(animated: true)
        }
        .onChange(of: locationService.authorizationStatus) { _, _ in
            if locationService.isAuthorized {
                locationService.startUpdating()
            }
        }
    }

    private func locationChip(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "location.fill")
                .foregroundStyle(ArcadeTheme.accent)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(ArcadeTheme.accent.opacity(0.4)))
    }

    private var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Location Access Needed", systemImage: "location.slash.fill")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Enable location so finished games can appear as pins near you.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Button {
                locationService.openSystemSettings()
            } label: {
                Text("Open Settings")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ArcadeTheme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private var remotePinsBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Pins Are Far Away", systemImage: "globe.americas.fill")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Some game pins look like old Simulator / US test data. Your live location is used for new games. Tap My Location, or clear history in Settings.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            Button {
                centerOnUser(animated: true)
            } label: {
                Text("Center on Me")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ArcadeTheme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ArcadeTheme.accent.opacity(0.45))
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
                .strokeBorder(ArcadeTheme.accent.opacity(0.35))
        )
    }

    private var emptyStateMessage: String {
        if !locationService.isAuthorized {
            return "Allow location access, then finish a game to drop your first pin."
        }
        if !locationService.hasFix {
            return "Waiting for GPS… On Simulator: Features → Location → Custom Location (Sri Lanka)."
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
        HStack(spacing: 10) {
            Button {
                locationService.refreshLocation()
                centerOnUser(animated: true)
            } label: {
                Label("My Location", systemImage: "location.fill")
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().strokeBorder(ArcadeTheme.accent.opacity(0.35)))
            }
            .foregroundStyle(ArcadeTheme.accent)

            if !pins.isEmpty {
                Button {
                    showAllPins()
                } label: {
                    Label("All Pins", systemImage: "map.fill")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.2)))
                }
                .foregroundStyle(.white)
            }

            Spacer()

            Text("\(pins.count) pin\(pins.count == 1 ? "" : "s")")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Capsule().fill(ArcadeTheme.accent.opacity(0.55)))
        }
    }

    private func centerOnUser(animated: Bool) {
        let coordinate = locationService.preferredMapCoordinate
        let span = locationService.hasFix
            ? MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            : MKCoordinateSpan(latitudeDelta: 2.8, longitudeDelta: 2.8)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        if animated {
            withAnimation(.easeInOut(duration: 0.4)) {
                position = .region(region)
            }
        } else {
            position = .region(region)
        }
    }

    private func showAllPins() {
        guard !pins.isEmpty else {
            centerOnUser(animated: true)
            return
        }
        let coordinates = pins.map(\.coordinate)
        var rect = MKMapRect.null
        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1)
            rect = rect.union(pointRect)
        }
        rect = rect.insetBy(dx: -max(rect.size.width * 0.35, 2000), dy: -max(rect.size.height * 0.35, 2000))
        withAnimation(.easeInOut(duration: 0.4)) {
            position = .rect(rect)
        }
    }

    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Tap Frenzy": return ArcadeTheme.accent
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
