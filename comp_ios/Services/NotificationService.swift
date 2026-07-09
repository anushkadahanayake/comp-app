import Foundation
import UserNotifications
import Combine

final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func scheduleDailyChallenge(at date: Date) {
        // Clear existing notifications first
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Arcade Frenzy Daily Challenge! 🎮"
            content.body = "It's time for your daily dose of Arcade Frenzy! Can you beat your personal best today?"
            content.sound = .default
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "DailyChallengeNotification", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func cancelDailyChallenge() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
}
