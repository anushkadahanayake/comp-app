import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var historyManager = SessionHistoryManager.shared
    
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    
    // Calculate total points
    private var totalPoints: Int {
        historyManager.sessions.reduce(0) { $0 + $1.score }
    }
    
    // Calculate rank title and emoji based on total points
    private var playerRank: String {
        if totalPoints < 100 {
            return "Neon Cadet 🛡️"
        } else if totalPoints < 500 {
            return "Pixel Warrior ⚔️"
        } else if totalPoints < 2000 {
            return "Arcade Champion 🏆"
        } else {
            return "Retro Legend 👑"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Gamified Player Profile Badge
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .shadow(color: .cyan.opacity(0.4), radius: 10)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 8)
                    
                    VStack(spacing: 4) {
                        Text(playerRank)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.white)
                            .shadow(color: .cyan.opacity(0.3), radius: 6)
                        
                        Text("Rank Title • \(totalPoints) Total XP")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(red: 0.08, green: 0.08, blue: 0.16))
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(LinearGradient(colors: [.cyan.opacity(0.4), .purple.opacity(0.4)], startPoint: .leading, endPoint: .trailing), lineWidth: 1.5)
                )
                .padding(.horizontal)
                
                // Summary Stats Cards
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("TOTAL GAMES")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.cyan)
                        Text("\(historyManager.sessions.count)")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.06, green: 0.06, blue: 0.12))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1.5)
                    )
                    
                    VStack(spacing: 4) {
                        Text("TOTAL POINTS")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.purple)
                        Text("\(totalPoints)")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(red: 0.06, green: 0.06, blue: 0.12))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1.5)
                    )
                }
                .padding(.horizontal)
                
                // Personal Bests Group
                VStack(alignment: .leading, spacing: 12) {
                    Text("PERSONAL BESTS")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 24)
                    
                    VStack(spacing: 0) {
                        personalBestRow(title: "Tap Frenzy", score: highScoreTapFrenzy, color: .cyan)
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                        personalBestRow(title: "Light It Up", score: highScoreLightItUp, color: .orange)
                        Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                        personalBestRow(title: "Quiz Rush", score: highScoreQuizRush, color: .purple)
                    }
                    .background(Color(red: 0.06, green: 0.06, blue: 0.12))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                // Charts Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("PERFORMANCE CHARTS")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 24)
                    
                    ModeBarChart(
                        title: "Tap Frenzy (Last 6 games)",
                        sessions: historyManager.sessions.filter { $0.mode == "Tap Frenzy" },
                        color: .cyan
                    )
                    .padding(.horizontal)
                    
                    ModeBarChart(
                        title: "Light It Up (Last 6 games)",
                        sessions: historyManager.sessions.filter { $0.mode == "Light It Up" },
                        color: .orange
                    )
                    .padding(.horizontal)
                    
                    ModeBarChart(
                        title: "Quiz Rush (Last 6 games)",
                        sessions: historyManager.sessions.filter { $0.mode == "Quiz Rush" },
                        color: .purple
                    )
                    .padding(.horizontal)
                }
                
                // Recent Games List
                VStack(alignment: .leading, spacing: 12) {
                    Text("RECENT GAMES")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.black)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 24)
                    
                    if historyManager.sessions.isEmpty {
                        Text("No completed sessions yet.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                            .background(Color(red: 0.06, green: 0.06, blue: 0.12))
                            .cornerRadius(18)
                            .padding(.horizontal)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(historyManager.sessions.reversed().prefix(10)) { session in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(session.mode)
                                            .font(.system(.headline, design: .rounded))
                                            .bold()
                                            .foregroundStyle(.white)
                                        Text(formatDate(session.timestamp))
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(session.score) pts")
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundStyle(modeColor(session.mode))
                                }
                                .padding(.all, 16)
                                .contentShape(Rectangle())
                                
                                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                            }
                        }
                        .background(Color(red: 0.06, green: 0.06, blue: 0.12))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 24)
            }
            .padding(.vertical)
        }
        .background(Color(red: 0.03, green: 0.03, blue: 0.07))
        .navigationTitle("Stats")
    }
    
    private func personalBestRow(title: String, score: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
            
            Spacer()
            
            Text("\(score) pts")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(color)
                .shadow(color: color.opacity(0.4), radius: 6)
        }
        .padding(.all, 18)
    }
    
    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Tap Frenzy": return .cyan
        case "Light It Up": return .orange
        case "Quiz Rush": return .purple
        default: return .white
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Bar Chart Component
struct ModeBarChart: View {
    let title: String
    let sessions: [GameSession]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.black)
                .foregroundStyle(.secondary)
            
            if sessions.isEmpty {
                Text("No games completed yet.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
            } else {
                let suffixData = Array(sessions.suffix(6))
                Chart {
                    ForEach(Array(suffixData.enumerated()), id: \.offset) { index, session in
                        BarMark(
                            x: .value("Game", index + 1),
                            y: .value("Score", session.score)
                        )
                        .foregroundStyle(color.gradient)
                        .annotation(position: .top) {
                            Text("\(session.score)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(color)
                        }
                    }
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.white.opacity(0.06))
                        AxisTick().foregroundStyle(Color.white.opacity(0.12))
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("G\(intVal)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1)).foregroundStyle(Color.white.opacity(0.06))
                        AxisValueLabel()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.all, 16)
        .background(Color(red: 0.06, green: 0.06, blue: 0.12))
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(color.opacity(0.2), lineWidth: 1.5)
        )
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
}
