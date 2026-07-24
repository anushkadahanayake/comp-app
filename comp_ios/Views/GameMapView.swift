import SwiftUI
import MapKit
import CoreLocation

enum MapPinKind: Hashable {
    case session
    case personalBest
    case deviceChampion
}

enum MapPinFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case sessions = "Plays"
    case myBest = "My best"
    case champions = "Top spot"

    var id: String { rawValue }
}

struct MapPinItem: Identifiable, Hashable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let title: String
    let subtitle: String
    let mode: String
    let date: Date
    let kind: MapPinKind
    let score: Int

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
    @ObservedObject private var statsStore = PlayerStatsStore.shared
    @ObservedObject private var auth = AuthService.shared

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: LocationService.sriLankaFallback,
            span: MKCoordinateSpan(latitudeDelta: 2.8, longitudeDelta: 2.8)
        )
    )
    @State private var selectedPinId: UUID?
    @State private var selectedPin: MapPinItem?
    @State private var didAutoCenterOnUser = false
    @State private var mapFilter: MapPinFilter = .all
    @State private var showTopScores = false
    @State private var flyToSelection = false

    private var sessionPins: [MapPinItem] {
        historyManager.sessions.compactMap { session -> MapPinItem? in
            guard let lat = session.latitude, let lon = session.longitude else { return nil }
            let playerBit = session.playerName.map { " · \($0)" } ?? ""
            return MapPinItem(
                id: session.id,
                latitude: lat,
                longitude: lon,
                title: session.mode,
                subtitle: "Score: \(session.score) pts\(playerBit)",
                mode: session.mode,
                date: session.timestamp,
                kind: .session,
                score: session.score
            )
        }
    }

    private var personalBestPins: [MapPinItem] {
        guard let playerId = auth.currentPlayer?.id else { return [] }
        return statsStore.personalBestLocations(for: playerId).compactMap { record -> MapPinItem? in
            guard let mode = GameMode(rawValue: record.mode) else { return nil }
            return MapPinItem(
                id: MapPinStableID.personal(mode),
                latitude: record.latitude,
                longitude: record.longitude,
                title: "Your best · \(record.mode)",
                subtitle: "\(record.score) pts · Personal record",
                mode: record.mode,
                date: record.recordedAt,
                kind: .personalBest,
                score: record.score
            )
        }
    }

    private var championPins: [MapPinItem] {
        GameMode.allCases.compactMap { mode -> MapPinItem? in
            guard let session = statsStore.deviceChampionSession(for: mode),
                  let lat = session.latitude,
                  let lon = session.longitude else { return nil }
            let name = session.playerName ?? "Player"
            return MapPinItem(
                id: MapPinStableID.champion(mode),
                latitude: lat,
                longitude: lon,
                title: "Top score · \(mode.rawValue)",
                subtitle: "\(name) · \(session.score) pts",
                mode: mode.rawValue,
                date: session.timestamp,
                kind: .deviceChampion,
                score: session.score
            )
        }
    }

    private var allSpecialPins: [MapPinItem] {
        championPins + personalBestPins
    }

    private var visiblePins: [MapPinItem] {
        switch mapFilter {
        case .all:
            let specialIds = Set(allSpecialPins.map(\.id))
            let plays = sessionPins.filter { !specialIds.contains($0.id) }
            return allSpecialPins + plays
        case .sessions:
            return sessionPins
        case .myBest:
            return personalBestPins
        case .champions:
            return championPins
        }
    }

    private var pinsLookRemote: Bool {
        guard let lat = locationService.currentLatitude,
              let lon = locationService.currentLongitude,
              !sessionPins.isEmpty else { return false }
        let userLoc = CLLocation(latitude: lat, longitude: lon)
        return sessionPins.contains { pin in
            let pinLoc = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
            return userLoc.distance(from: pinLoc) > 500_000
        }
    }

    var body: some View {
        Map(position: $position, selection: $selectedPinId) {
            ForEach(visiblePins) { pin in
                if pin.kind == .session {
                    Marker(pin.title, coordinate: pin.coordinate)
                        .tint(modeColor(pin.mode))
                        .tag(pin.id)
                } else {
                    Annotation(pin.title, coordinate: pin.coordinate, anchor: .bottom) {
                        Button {
                            selectedPinId = pin.id
                            selectedPin = pin
                        } label: {
                            mapPinGlyph(pin)
                        }
                        .buttonStyle(.plain)
                    }
                    .tag(pin.id)
                }
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
        .safeAreaInset(edge: .top, spacing: 8) {
            mapTopOverlay
        }
        .safeAreaInset(edge: .bottom, spacing: 8) {
            mapBottomOverlay
        }
        .navigationTitle("Map of Games")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showTopScores = true
                } label: {
                    Image(systemName: "trophy.fill")
                }
                .foregroundStyle(ArcadeTheme.accent)
                .accessibilityLabel("Top scores and locations")
            }
        }
        .sheet(isPresented: $showTopScores) {
            MapTopScoresSheet { pinId in
                focusOnPin(id: pinId)
            }
        }
        .onAppear {
            locationService.refreshLocation()
            centerOnUser(animated: false)
        }
        .onChange(of: selectedPinId) { _, newId in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedPin = visiblePins.first(where: { $0.id == newId })
                    ?? allSpecialPins.first(where: { $0.id == newId })
                    ?? sessionPins.first(where: { $0.id == newId })
            }
            if flyToSelection, let pin = selectedPin {
                flyTo(pin.coordinate)
                flyToSelection = false
            }
        }
        .onChange(of: mapFilter) { _, _ in
            if let id = selectedPinId,
               !visiblePins.contains(where: { $0.id == id }) {
                selectedPinId = nil
                selectedPin = nil
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

    private var mapTopOverlay: some View {
        VStack(spacing: 10) {
            if locationService.isDenied {
                permissionBanner
            } else if pinsLookRemote {
                remotePinsBanner
            } else if visiblePins.isEmpty {
                emptyStateBanner
            }

            filterStrip

            if auth.currentPlayer != nil {
                personalBestStrip
            }

            mapLegend
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var mapBottomOverlay: some View {
        VStack(spacing: 10) {
            if let place = locationService.placeLabel ?? locationService.coordinateLabel {
                locationChip(place)
            }

            if let pin = selectedPin {
                pinDetailCard(pin)
            }

            mapToolbar
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private var filterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MapPinFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            mapFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                mapFilter == filter
                                    ? ArcadeTheme.accent.opacity(0.85)
                                    : Color.white.opacity(0.12),
                                in: Capsule()
                            )
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private var personalBestStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GameMode.allCases) { mode in
                    if let playerId = auth.currentPlayer?.id {
                        let best = statsStore.highScore(for: mode, playerId: playerId)
                        let hasPin = statsStore.personalBestLocation(for: mode, playerId: playerId) != nil
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shortMode(mode))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(mode.leaderboardAccent)
                            Text("\(best)")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                            HStack(spacing: 4) {
                                Image(systemName: hasPin ? "mappin.circle.fill" : "mappin.slash")
                                    .font(.caption2)
                                Text(hasPin ? "On map" : "No GPS")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(mode.leaderboardAccent.opacity(0.35), lineWidth: 1)
                        )
                        .onTapGesture {
                            if hasPin {
                                mapFilter = .myBest
                                focusOnPin(id: MapPinStableID.personal(mode))
                            }
                        }
                    }
                }
            }
        }
    }

    private var mapLegend: some View {
        HStack(spacing: 12) {
            legendItem(color: .yellow, icon: "trophy.fill", label: "Top spot")
            legendItem(color: ArcadeTheme.accentSoft, icon: "star.fill", label: "Your best")
            legendItem(color: .white.opacity(0.9), icon: "circle.fill", label: "Play")
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.white.opacity(0.75))
    }

    private func legendItem(color: Color, icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.caption2)
            Text(label)
        }
    }

    @ViewBuilder
    private func mapPinGlyph(_ pin: MapPinItem) -> some View {
        let tint = pinTint(pin)
        let symbol: String = {
            switch pin.kind {
            case .deviceChampion: return "trophy.fill"
            case .personalBest: return "star.fill"
            case .session: return "gamecontroller.fill"
            }
        }()

        ZStack {
            Circle()
                .fill(tint.opacity(0.25))
                .frame(width: pin.kind == .session ? 34 : 42, height: pin.kind == .session ? 34 : 42)
            Circle()
                .strokeBorder(tint, lineWidth: pin.kind == .session ? 1.5 : 2.5)
                .frame(width: pin.kind == .session ? 34 : 42, height: pin.kind == .session ? 34 : 42)
            Image(systemName: symbol)
                .font(.system(size: pin.kind == .session ? 12 : 14, weight: .bold))
                .foregroundStyle(tint)
        }
        .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
    }

    private func pinTint(_ pin: MapPinItem) -> Color {
        switch pin.kind {
        case .deviceChampion:
            return .yellow
        case .personalBest:
            return ArcadeTheme.accentSoft
        case .session:
            return modeColor(pin.mode)
        }
    }

    private func shortMode(_ mode: GameMode) -> String {
        switch mode {
        case .tapFrenzy: return "Tap"
        case .lightItUp: return "Light"
        case .quizRush: return "Quiz"
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
            Label("No Pins in This View", systemImage: "mappin.slash")
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
        switch mapFilter {
        case .myBest:
            return "Set a new personal best with location enabled to see your star pins."
        case .champions:
            return "Finish games with GPS on — the best score per game gets a trophy pin."
        case .sessions, .all:
            if !locationService.isAuthorized {
                return "Allow location access, then finish a game to drop your first pin."
            }
            if !locationService.hasFix {
                return "Waiting for GPS… On Simulator: Features → Location → Custom Location."
            }
            return "Finish any game to drop a pin, or open the trophy for top scores."
        }
    }

    private func pinDetailCard(_ pin: MapPinItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(pinTint(pin).opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: pin.kind == .deviceChampion ? "trophy.fill" : (pin.kind == .personalBest ? "star.fill" : "gamecontroller.fill"))
                    .foregroundStyle(pinTint(pin))
            }

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
                .strokeBorder(pinTint(pin).opacity(0.45))
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

            if !visiblePins.isEmpty {
                Button {
                    showAllPins()
                } label: {
                    Label("Fit Pins", systemImage: "map.fill")
                        .font(.subheadline.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.2)))
                }
                .foregroundStyle(.white)
            }

            Spacer()

            Text("\(visiblePins.count) pin\(visiblePins.count == 1 ? "" : "s")")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Capsule().fill(ArcadeTheme.accent.opacity(0.55)))
        }
    }

    private func focusOnPin(id: UUID) {
        if championPins.contains(where: { $0.id == id }) {
            mapFilter = .champions
        } else if personalBestPins.contains(where: { $0.id == id }) {
            mapFilter = .myBest
        }
        flyToSelection = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            selectedPinId = id
        }
    }

    private func flyTo(_ coordinate: CLLocationCoordinate2D) {
        withAnimation {
            position = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                )
            )
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
        let pins = visiblePins
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
