import SwiftUI

struct SettingsView: View {
    @AppStorage("RoundDurationSetting") private var roundDuration: Double = 60.0
    @AppStorage("NotificationsEnabled") private var notificationsEnabled = false
    @AppStorage("DailyChallengeTime") private var challengeTimeDouble: Double = Date().timeIntervalSince1970
    @AppStorage("SoundEnabled") private var soundEnabled = true
    @AppStorage("HapticsEnabled") private var hapticsEnabled = true
    @AppStorage("SaveLocationWithSessions") private var saveLocationWithSessions = true

    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0

    @ObservedObject var notifications = NotificationService.shared
    @ObservedObject var locationService = LocationService.shared
    @State private var showResetConfirmation = false

    private var challengeTimeBinding: Binding<Date> {
        Binding<Date>(
            get: { Date(timeIntervalSince1970: challengeTimeDouble) },
            set: { newDate in
                challengeTimeDouble = newDate.timeIntervalSince1970
                if notificationsEnabled {
                    notifications.scheduleDailyChallenge(at: newDate)
                }
            }
        )
    }

    init() {
        UITableView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.07)
                .ignoresSafeArea()

            List {
                gameplaySection
                soundHapticsSection
                notificationsSection
                locationSection
                aboutSection
                dangerSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Reset All Stats?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                highScoreTapFrenzy = 0
                highScoreLightItUp = 0
                highScoreQuizRush = 0
                SessionHistoryManager.shared.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently clear your scores, history, and map pins. This cannot be undone.")
        }
        .onAppear {
            notifications.checkAuthorizationStatus()
            locationService.refreshLocation()
        }
    }

    private var gameplaySection: some View {
        Section(
            header: sectionHeader("GAMEPLAY", color: .cyan),
            footer: Text("Round length adjusts Light It Up level-up thresholds.")
                .foregroundStyle(.secondary)
        ) {
            Picker("Round Length", selection: $roundDuration) {
                Text("30 Seconds").tag(30.0)
                Text("60 Seconds (Default)").tag(60.0)
                Text("90 Seconds").tag(90.0)
            }
            .pickerStyle(.menu)
            .foregroundStyle(.white)
        }
        .listRowBackground(rowBackground)
    }

    private var soundHapticsSection: some View {
        Section(header: sectionHeader("SOUND & HAPTICS", color: .mint)) {
            Toggle(isOn: $soundEnabled) {
                Label("Game Sounds", systemImage: "speaker.wave.2.fill")
            }
            .tint(.cyan)
            .onChange(of: soundEnabled) { _, enabled in
                if enabled { AppFeedback.playTap() }
            }

            Toggle(isOn: $hapticsEnabled) {
                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
            }
            .tint(.cyan)
            .onChange(of: hapticsEnabled) { _, enabled in
                if enabled { AppFeedback.impact(.medium) }
            }

            Button {
                AppFeedback.notify(.success)
            } label: {
                Label("Test Sound & Haptics", systemImage: "waveform")
            }
            .foregroundStyle(.cyan)
        }
        .listRowBackground(rowBackground)
    }

    private var notificationsSection: some View {
        Section(
            header: sectionHeader("NOTIFICATIONS", color: .purple),
            footer: Text(notificationsFooter)
                .foregroundStyle(.secondary)
        ) {
            HStack {
                Label("Permission", systemImage: "bell.badge.fill")
                Spacer()
                Text(notifications.statusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(notifications.isAuthorized ? .green : .orange)
            }

            Toggle(isOn: $notificationsEnabled) {
                Label("Daily Challenge Reminder", systemImage: "alarm.fill")
            }
            .tint(.cyan)
            .onChange(of: notificationsEnabled) { _, enabled in
                if enabled {
                    notifications.requestPermission { granted in
                        if granted {
                            notifications.scheduleDailyChallenge(at: Date(timeIntervalSince1970: challengeTimeDouble))
                        } else {
                            notificationsEnabled = false
                        }
                    }
                } else {
                    notifications.cancelDailyChallenge()
                }
            }

            if notificationsEnabled {
                DatePicker("Reminder Time", selection: challengeTimeBinding, displayedComponents: .hourAndMinute)
                    .foregroundStyle(.white)
            }

            if notifications.authorizationStatus == .denied {
                Button {
                    notifications.openSystemSettings()
                } label: {
                    Label("Open iOS Settings", systemImage: "gear")
                }
                .foregroundStyle(.orange)
            } else if notifications.authorizationStatus == .notDetermined {
                Button {
                    notifications.requestPermission()
                } label: {
                    Label("Request Notification Access", systemImage: "bell")
                }
                .foregroundStyle(.cyan)
            }
        }
        .listRowBackground(rowBackground)
    }

    private var locationSection: some View {
        Section(
            header: sectionHeader("LOCATION", color: .orange),
            footer: Text("Location is used to drop map pins when you finish a game.")
                .foregroundStyle(.secondary)
        ) {
            HStack {
                Label("Permission", systemImage: "location.fill")
                Spacer()
                Text(locationService.statusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(locationService.isAuthorized ? .green : .orange)
            }

            if let label = locationService.coordinateLabel {
                HStack {
                    Label("Last Fix", systemImage: "mappin.and.ellipse")
                    Spacer()
                    Text(label)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
            } else if let error = locationService.locationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Toggle(isOn: $saveLocationWithSessions) {
                Label("Save Location With Scores", systemImage: "map.fill")
            }
            .tint(.cyan)

            if locationService.isDenied {
                Button {
                    locationService.openSystemSettings()
                } label: {
                    Label("Open iOS Settings", systemImage: "gear")
                }
                .foregroundStyle(.orange)
            } else {
                Button {
                    locationService.refreshLocation()
                } label: {
                    Label(locationService.authorizationStatus == .notDetermined ? "Request Location Access" : "Refresh Location", systemImage: "location.circle")
                }
                .foregroundStyle(.cyan)
            }
        }
        .listRowBackground(rowBackground)
    }

    private var aboutSection: some View {
        Section(header: sectionHeader("ABOUT", color: .blue)) {
            HStack {
                Text("App")
                Spacer()
                Text("Arcade Frenzy")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Games")
                Spacer()
                Text("\(ArcadeGame.all.count)")
                    .foregroundStyle(.secondary)
            }
        }
        .listRowBackground(rowBackground)
    }

    private var dangerSection: some View {
        Section(header: sectionHeader("DANGER ZONE", color: .red)) {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Reset All Scores & Stats")
                        .fontWeight(.black)
                    Spacer()
                }
            }
        }
        .listRowBackground(rowBackground)
    }

    private var notificationsFooter: String {
        if notifications.authorizationStatus == .denied {
            return "Notifications are denied. Enable them in iOS Settings to receive daily reminders."
        }
        return "Get a daily reminder to play and beat your high scores."
    }

    private var rowBackground: Color {
        Color(red: 0.08, green: 0.08, blue: 0.15)
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(.caption, design: .rounded))
            .fontWeight(.black)
            .foregroundStyle(color)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
