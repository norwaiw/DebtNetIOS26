import SwiftUI
import UserNotifications

@main
struct DebtNetApp: App {
    @StateObject private var debtStore = DebtStore()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(debtStore)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        // Устанавливаем делегат для обработки уведомлений
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Проверяем статус разрешений
        NotificationManager.shared.checkNotificationStatus()
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Обработка уведомлений когда приложение активно
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Показываем уведомление даже когда приложение активно
        completionHandler([.banner, .sound, .badge])
    }
    
    // Обработка тапа по уведомлению
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationManager.shared.handleNotificationAction(response: response)
        completionHandler()
    }
}