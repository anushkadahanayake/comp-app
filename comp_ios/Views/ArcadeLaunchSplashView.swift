import SwiftUI
import Combine

/// Brief branded splash while the app initializes.
struct ArcadeLaunchSplashView: View {
    @State private var logoScale: CGFloat = 0.72
    @State private var logoOpacity: Double = 0
    @State private var ringPulse = false
    @State private var titleOffset: CGFloat = 16
    @State private var dotPhase = 0

    private let timer = Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ArcadeTheme.backgroundDeep.ignoresSafeArea()

            Circle()
                .fill(ArcadeTheme.accent.opacity(0.2))
                .frame(width: 340, height: 340)
                .blur(radius: 70)
                .offset(y: -120)

            Circle()
                .fill(ArcadeTheme.accentSecondary.opacity(0.15))
                .frame(width: 260, height: 260)
                .blur(radius: 50)
                .offset(x: 100, y: 180)

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .strokeBorder(ArcadeTheme.accent.opacity(0.35), lineWidth: 2)
                        .frame(width: ringPulse ? 118 : 100, height: ringPulse ? 118 : 100)
                        .opacity(0.9)

                    Circle()
                        .fill(ArcadeTheme.brandGradient)
                        .frame(width: 92, height: 92)
                        .shadow(color: ArcadeTheme.accent.opacity(0.45), radius: 20, y: 8)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 10) {
                    Text("Arcade Frenzy")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(ArcadeTheme.textPrimary)
                        .offset(y: titleOffset)
                        .opacity(logoOpacity)

                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(ArcadeTheme.accentSoft)
                                .frame(width: 7, height: 7)
                                .opacity(dotPhase == index ? 1 : 0.35)
                        }
                    }
                    .opacity(logoOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                logoScale = 1
                logoOpacity = 1
                titleOffset = 0
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                ringPulse = true
            }
        }
        .onReceive(timer) { _ in
            dotPhase = (dotPhase + 1) % 3
        }
    }
}
