import SwiftUI

struct SettingsView: View {
    @AppStorage("RoundDurationSetting") private var roundDuration: Double = 60.0
    @AppStorage("NotificationsEnabled") private var notificationsEnabled = false
    
    // Default challenge time set to 7:00 PM (19:00)
    @AppStorage("DailyChallengeTime") private var challengeTimeDouble: Double = Date().timeIntervalSince1970
    
    // High Score resets
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    
    @ObservedObject var notifications = NotificationManager.shared
    @State private var showResetConfirmation = false
    
    // Helper property to work with Date in DatePicker and AppStorage
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
    
    var body: some View {
        List {
            Section(
                header: Text("GAMEPLAY SETTINGS"),
                footer: Text("Changing the round duration will automatically adjust the level-up thresholds proportionately in Light It Up.")
            ) {
                Picker("Round Length", selection: $roundDuration) {
                    Text("30 Seconds").tag(30.0)
                    Text("60 Seconds (Default)").tag(60.0)
                    Text("90 Seconds").tag(90.0)
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("DAILY REMINDER")) {
                Toggle("Enable Daily Challenge", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { enabled in
                        if enabled {
                            notifications.requestPermission()
                            notifications.scheduleDailyChallenge(at: Date(timeIntervalSince1970: challengeTimeDouble))
                        } else {
                            notifications.cancelDailyChallenge()
                        }
                    }
                
                if notificationsEnabled {
                    DatePicker("Reminder Time", selection: challengeTimeBinding, displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("DANGER ZONE")) {
                Button(role: .destructive, action: {
                    showResetConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Text("Reset All Scores & Stats")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog(
            "Reset All Stats?",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Everything", role: .destructive) {
                // Reset persistent high scores
                highScoreTapFrenzy = 0
                highScoreLightItUp = 0
                highScoreQuizRush = 0
                
                // Clear session stats logs
                SessionHistoryManager.shared.clearAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently clear your scores, total stats, history, and map pins. This action cannot be undone.")
        }
        .onAppear {
            notifications.checkAuthorizationStatus()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
