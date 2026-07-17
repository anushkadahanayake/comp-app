import SwiftUI

/// Consistent game HUD pill: icon on top, label, then value.
struct GameStatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let accent: Color
    var valueFont: Font = .system(.title2, design: .rounded).weight(.black)

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accent)
                .frame(height: 20)

            Text(title)
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(accent.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(value)
                .font(valueFont)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(minHeight: 28)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1.5)
        )
    }
}

/// Lives card with hearts under a top icon.
struct GameLivesCard: View {
    let lives: Int
    let maxLives: Int

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.red)
                .frame(height: 20)

            Text("LIVES")
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.red.opacity(0.9))

            HStack(spacing: 4) {
                ForEach(1...maxLives, id: \.self) { heartIndex in
                    Image(systemName: heartIndex <= lives ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(heartIndex <= lives ? .red : .gray.opacity(0.4))
                }
            }
            .frame(minHeight: 28)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.red.opacity(0.35), lineWidth: 1.5)
        )
    }
}
