import SwiftUI

struct SettingsView: View {
    @AppStorage("RoundDurationSetting") private var roundDuration: Double = 60.0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 28) {
                    // Header Illustration
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "timer")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 24)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ROUND DURATION")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                        
                        VStack(spacing: 0) {
                            durationRow(label: "30 Seconds", value: 30.0)
                            Divider()
                                .padding(.leading, 16)
                            durationRow(label: "60 Seconds (Default)", value: 60.0)
                            Divider()
                                .padding(.leading, 16)
                            durationRow(label: "90 Seconds", value: 90.0)
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(18)
                        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    
                    Text("Changing the round duration will automatically adjust the level-up thresholds proportionately.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(.headline, design: .rounded))
                    .bold()
                }
            }
        }
    }
    
    private func durationRow(label: String, value: Double) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                roundDuration = value
            }
        }) {
            HStack {
                Text(label)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if roundDuration == value {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.all, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
}
