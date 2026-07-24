import SwiftUI

/// Full-screen transition after sign-in (auto-dismisses; tap to skip).
struct AuthWelcomeTransitionView: View {
    let displayName: String
    var onFinished: () -> Void

    @State private var progress: CGFloat = 0
    @State private var iconRotation: Double = -8
    @State private var glow = false
    @State private var didFinish = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ArcadeTheme.backgroundDeep,
                    Color(red: 0.08, green: 0.14, blue: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(ArcadeTheme.accent.opacity(glow ? 0.28 : 0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(y: -80)

            VStack(spacing: 26) {
                ZStack {
                    Circle()
                        .fill(ArcadeTheme.brandGradient)
                        .frame(width: 96, height: 96)
                        .shadow(color: ArcadeTheme.accent.opacity(0.5), radius: 16, y: 6)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(iconRotation))
                }

                VStack(spacing: 8) {
                    Text("Welcome back")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ArcadeTheme.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1.2)

                    Text(displayName)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 24)

                    Text("Loading your arcade…")
                        .font(.subheadline)
                        .foregroundStyle(ArcadeTheme.textTertiary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(ArcadeTheme.brandGradient)
                            .frame(width: max(8, geo.size.width * progress))
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 48)
                .padding(.top, 8)

                Button("Skip") {
                    finish()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ArcadeTheme.accentSoft)
                .padding(.top, 8)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            finish()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55)) {
                iconRotation = 0
            }
            withAnimation(.easeInOut(duration: 1.0)) {
                progress = 1
            }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                finish()
            }
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        withAnimation(.easeOut(duration: 0.3)) {
            onFinished()
        }
    }
}
