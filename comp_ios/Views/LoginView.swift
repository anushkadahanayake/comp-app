import SwiftUI

struct LoginView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var isRegistering = false
    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showGuestSheet = false
    @State private var guestName = ""

    var body: some View {
        ZStack {
            ArcadeTheme.backgroundDeep.ignoresSafeArea()

            Circle()
                .fill(ArcadeTheme.accent.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: -80, y: -220)

            ScrollView {
                VStack(spacing: 24) {
                    Spacer(minLength: 48)

                    brandHeader

                    Text(isRegistering ? "Create a local account" : "Log in to your account")
                        .font(.subheadline)
                        .foregroundStyle(ArcadeTheme.textSecondary)

                    Picker("Mode", selection: $isRegistering) {
                        Text("Log In").tag(false)
                        Text("Sign Up").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    VStack(spacing: 14) {
                        TextField("Username or email", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        passwordField

                        Button {
                            if isRegistering {
                                auth.register(username: username, password: password)
                            } else {
                                auth.login(username: username, password: password)
                            }
                        } label: {
                            Text(isRegistering ? "Create Account" : "Log In")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(ArcadeTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(
                            username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                || password.isEmpty
                        )

                        Button {
                            auth.authError = nil
                            guestName = ""
                            showGuestSheet = true
                        } label: {
                            Text("Continue as Guest")
                                .fontWeight(.semibold)
                                .foregroundStyle(ArcadeTheme.accentSoft)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(ArcadeTheme.accent.opacity(0.45), lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    if let error = auth.authError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    if !auth.savedGuests.isEmpty {
                        savedGuestsSection
                    }

                    Text("Guests are saved on this device for 30 days so you can resume. Upgrade a guest in Settings to keep scores forever with a password.")
                        .font(.caption)
                        .foregroundStyle(ArcadeTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: isRegistering) { _, _ in
            auth.authError = nil
        }
        .sheet(isPresented: $showGuestSheet) {
            guestSheet
        }
    }

    private var savedGuestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resume saved guest")
                .font(.caption.weight(.bold))
                .foregroundStyle(ArcadeTheme.textTertiary)
                .padding(.horizontal, 28)

            ForEach(auth.savedGuests.prefix(6)) { guest in
                Button {
                    auth.resumeGuest(playerId: guest.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: guest.avatarSymbol)
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(ArcadeTheme.accent.opacity(0.35), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(guest.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Guest · last played \(guest.lastPlayedAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundStyle(ArcadeTheme.textTertiary)
                        }

                        Spacer()

                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(ArcadeTheme.accentSoft)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var passwordField: some View {
        HStack(spacing: 10) {
            Group {
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("Password", text: $password)
                }
            }

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(ArcadeTheme.textSecondary)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
        }
        .padding(14)
        .background(ArcadeTheme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var guestSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nickname", text: $guestName)
                        .textInputAutocapitalization(.words)
                } footer: {
                    Text("No password needed. This guest is saved on this device for 30 days — you can resume it from the login screen. Tip: upgrade to a full account in Settings to keep scores with a password.")
                }
            }
            .navigationTitle("Play as Guest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showGuestSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Play") {
                        auth.continueAsGuest(displayName: guestName)
                        if auth.authError == nil {
                            showGuestSheet = false
                        }
                    }
                    .disabled(guestName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var brandHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ArcadeTheme.brandGradient)
                    .frame(width: 88, height: 88)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Arcade Frenzy")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(ArcadeTheme.textPrimary)
        }
    }
}

#Preview {
    LoginView()
}
