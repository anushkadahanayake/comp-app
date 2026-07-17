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

                    Text("Saved only on this device. Guests only need a nickname.")
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
                    Text("No password needed. You’ll still get your own scores and a spot on the leaderboard.")
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
