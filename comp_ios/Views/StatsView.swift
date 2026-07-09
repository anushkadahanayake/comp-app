import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject var historyManager = SessionHistoryManager.shared
    
    @AppStorage("HighScore_TapFrenzy") private var highScoreTapFrenzy: Int = 0
    @AppStorage("HighScore_LightItUp") private var highScoreLightItUp: Int = 0
    @AppStorage("HighScore_QuizRush") private var highScoreQuizRush: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary Stats Cards
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("TOTAL GAMES")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.secondary)
                        Text("\(historyManager.sessions.count)")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 4) {
                        Text("TOTAL POINTS")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.secondary)
                        Text("\(historyManager.sessions.reduce(0) { $0 + $1.score })")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(18)
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
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
                        personalBestRow(title: "Tap Frenzy", score: highScoreTapFrenzy, color: .blue)
                        Divider().padding(.leading, 16)
                        personalBestRow(title: "Light It Up", score: highScoreLightItUp, color: .orange)
                        Divider().padding(.leading, 16)
                        personalBestRow(title: "Quiz Rush", score: highScoreQuizRush, color: .purple)
                    }
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 3)
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
                        color: .blue
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
                            .background(Color(.secondarySystemGroupedBackground))
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
                                        Text(formatDate(session.timestamp))
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(session.score)")
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundStyle(modeColor(session.mode))
                                }
                                .padding(.all, 16)
                                .contentShape(Rectangle())
                                
                                Divider().padding(.leading, 16)
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 3)
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 24)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stats")
    }
    
    private func personalBestRow(title: String, score: Int, color: Color) -> some View {
        HStack {
            Text(title)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(score) pts")
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
        .padding(.all, 18)
    }
    
    private func modeColor(_ mode: String) -> Color {
        switch mode {
        case "Tap Frenzy": return .blue
        case "Light It Up": return .orange
        case "Quiz Rush": return .purple
        default: return .primary
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
                .fontWeight(.bold)
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
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let intVal = value.as(Int.self) {
                                Text("G\(intVal)")
                            }
                        }
                    }
                }
            }
        }
        .padding(.all, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
}
