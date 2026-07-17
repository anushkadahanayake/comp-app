import SwiftUI

struct SettingsView: View {
    @AppStorage("RoundDurationSetting") private var roundDuration: Double = 60.0
    @AppStorage("NotificationsEnabled") private var notificationsEnabled = false
    @AppStorage("DailyChallengeTime") private var challengeTimeDouble: Double = Date().timeIntervalSince1970
    @AppStorage("SoundEnabled") private var soundEnabled = true
    @AppStorage("HapticsEnabled") private var hapticsEnabled = true
    @AppStorage("SaveLocationWithSessions") private var saveLocationWithSessions = true

    @ObservedObject var notifications = NotificationService.shared
    @ObservedObject var locationService = LocationService.shared
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var statsStore = PlayerStatsStore.shared
    @State private var showResetConfirmation = false
    @State private var showSignOutConfirmation = false
    @State private var showUpgradeSheet = false
    @State private var editName = ""
    @State private var upgradeUsername = ""
    @State private var upgradePassword = ""
    @State private var isUpgradePasswordVisible = false

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
            ArcadeTheme.backgroundDeep
                .ignoresSafeArea()

            List {
                profileSection
                gameplaySection
                soundHapticsSection
                notificationsSection
                locationSection
                aboutSection
                dangerSection
            }
            .scrollContentBackground(.hidden)
            .tint(ArcadeTheme.accent)
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Reset All Stats?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset My Stats", role: .destructive) {
                if let id = auth.currentPlayer?.id {
                    statsStore.resetScores(for: id)
                    SessionHistoryManager.shared.clearSessions(for: id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears only this player’s scores, history, and map pins.")
        }
        .confirmationDialog(
            auth.currentPlayer?.isGuest == true ? "Log Out Guest?" : "Log Out?",
            isPresented: $showSignOutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                auth.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if auth.currentPlayer?.isGuest == true {
                Text("Warning: Guests have no password. You can resume this guest from the login screen on this device for 30 days. If you start a brand‑new guest instead, you will not get these scores. Tip: use “Create Account & Keep Scores” before logging out.")
            } else {
                Text("You’ll return to the login screen. Your account stays on this device — log in again with your password.")
            }
        }
        .sheet(isPresented: $showUpgradeSheet) {
            upgradeGuestSheet
        }
        .onAppear {
            notifications.checkAuthorizationStatus()
            locationService.refreshLocation()
            editName = auth.currentPlayer?.displayName ?? ""
        }
    }

    private var profileSection: some View {
        Section(
            header: sectionHeader("PLAYER PROFILE", color: ArcadeTheme.accent),
            footer: Text(
                auth.currentPlayer?.isGuest == true
                    ? "Guest tip: create an account to keep your high scores with a password. Guests can be resumed on this device for 30 days after log out."
                    : "Accounts are saved on this device only. Sign out to switch players."
            )
            .foregroundStyle(.secondary)
        ) {
            if let player = auth.currentPlayer {
                HStack(spacing: 12) {
                    Image(systemName: player.avatarSymbol)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(ArcadeTheme.accent.opacity(0.4), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.displayName)
                            .font(.headline)
                        Text(player.isGuest ? "Guest (saved on this device)" : player.username)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                TextField("Display name", text: $editName)
                    .onSubmit {
                        auth.updateDisplayName(editName)
                    }

                Button("Save Display Name") {
                    auth.updateDisplayName(editName)
                }
                .foregroundStyle(ArcadeTheme.accent)

                if player.isGuest {
                    Button {
                        auth.authError = nil
                        upgradeUsername = ""
                        upgradePassword = ""
                        showUpgradeSheet = true
                    } label: {
                        Label("Create Account & Keep Scores", systemImage: "person.badge.plus")
                    }
                    .foregroundStyle(ArcadeTheme.accentSoft)
                }

                Button("Log Out", role: .destructive) {
                    showSignOutConfirmation = true
                }
            }
        }
        .listRowBackground(rowBackground)
    }

    private var upgradeGuestSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Username or email", text: $upgradeUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        Group {
                            if isUpgradePasswordVisible {
                                TextField("Password", text: $upgradePassword)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("Password", text: $upgradePassword)
                            }
                        }
                        Button {
                            isUpgradePasswordVisible.toggle()
                        } label: {
                            Image(systemName: isUpgradePasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    Text("Your guest high scores, stats, and map pins stay on this same player. You’ll log in with this username and password next time.")
                }

                if let error = auth.authError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Keep My Scores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showUpgradeSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Account") {
                        auth.upgradeGuest(username: upgradeUsername, password: upgradePassword)
                        if auth.authError == nil {
                            showUpgradeSheet = false
                            editName = auth.currentPlayer?.displayName ?? editName
                        }
                    }
                    .disabled(
                        upgradeUsername.trimmingCharacters(in: .whitespacesAndNewlines).count < 3
                            || upgradePassword.count < 4
                    )
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var gameplaySection: some View {
        Section(
            header: sectionHeader("GAMEPLAY", color: ArcadeTheme.accent),
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
        Section(header: sectionHeader("SOUND & HAPTICS", color: ArcadeTheme.accentSecondary)) {
            Toggle(isOn: $soundEnabled) {
                Label("Game Sounds", systemImage: "speaker.wave.2.fill")
            }
            .tint(ArcadeTheme.accent)
            .onChange(of: soundEnabled) { _, enabled in
                if enabled { AppFeedback.playTap() }
            }

            Toggle(isOn: $hapticsEnabled) {
                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
            }
            .tint(ArcadeTheme.accent)
            .onChange(of: hapticsEnabled) { _, enabled in
                if enabled { AppFeedback.impact(.medium) }
            }

            Button {
                AppFeedback.notify(.success)
            } label: {
                Label("Test Sound & Haptics", systemImage: "waveform")
            }
            .foregroundStyle(ArcadeTheme.accent)
        }
        .listRowBackground(rowBackground)
    }

    private var notificationsSection: some View {
        Section(
            header: sectionHeader("NOTIFICATIONS", color: ArcadeTheme.accentSecondary),
            footer: Text(notificationsFooter)
                .foregroundStyle(.secondary)
        ) {
            HStack {
                Label("Permission", systemImage: "bell.badge.fill")
                Spacer()
                Text(notifications.statusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(notifications.isAuthorized ? ArcadeTheme.success : ArcadeTheme.warning)
            }

            Toggle(isOn: $notificationsEnabled) {
                Label("Daily Challenge Reminder", systemImage: "alarm.fill")
            }
            .tint(ArcadeTheme.accent)
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
                .foregroundStyle(ArcadeTheme.warning)
            } else if notifications.authorizationStatus == .notDetermined {
                Button {
                    notifications.requestPermission()
                } label: {
                    Label("Request Notification Access", systemImage: "bell")
                }
                .foregroundStyle(ArcadeTheme.accent)
            }
        }
        .listRowBackground(rowBackground)
    }

    private var locationSection: some View {
        Section(
            header: sectionHeader("LOCATION", color: ArcadeTheme.accentSecondary),
            footer: Text("Location is used to drop map pins when you finish a game.")
                .foregroundStyle(.secondary)
        ) {
            HStack {
                Label("Permission", systemImage: "location.fill")
                Spacer()
                Text(locationService.statusLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(locationService.isAuthorized ? ArcadeTheme.success : ArcadeTheme.warning)
            }

            if let place = locationService.placeLabel {
                HStack {
                    Label("Place", systemImage: "globe.asia.australia.fill")
                    Spacer()
                    Text(place)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
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
            .tint(ArcadeTheme.accent)

            if locationService.isDenied {
                Button {
                    locationService.openSystemSettings()
                } label: {
                    Label("Open iOS Settings", systemImage: "gear")
                }
                .foregroundStyle(ArcadeTheme.warning)
            } else {
                Button {
                    locationService.refreshLocation()
                } label: {
                    Label(locationService.authorizationStatus == .notDetermined ? "Request Location Access" : "Refresh Location", systemImage: "location.circle")
                }
                .foregroundStyle(ArcadeTheme.accent)
            }
        }
        .listRowBackground(rowBackground)
    }

    private var aboutSection: some View {
        Section(header: sectionHeader("ABOUT", color: ArcadeTheme.textSecondary)) {
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
        Section(header: sectionHeader("DANGER ZONE", color: ArcadeTheme.danger)) {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Reset My Scores & Stats")
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
        ArcadeTheme.surface
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(.caption, design: .rounded))
            .fontWeight(.semibold)
            .foregroundStyle(color)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
