import Foundation
import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isNotificationEnabled = false
    
    private init() {
        checkNotificationStatus()
    }
    
    // MARK: - Запрос разрешений
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isNotificationEnabled = granted
            }
            
            if let error = error {
                print("Ошибка при запросе разрешений на уведомления: \(error)")
            }
        }
    }
    
    // MARK: - Проверка статуса разрешений
    func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isNotificationEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Планирование уведомлений для всех долгов
    func scheduleNotificationsForDebts(_ debts: [Debt]) {
        // Очищаем все существующие уведомления
        cancelAllNotifications()
        
        guard isNotificationEnabled else { return }
        
        for debt in debts {
            if !debt.isPaid {
                scheduleNotificationForDebt(debt)
            }
        }
    }
    
    // MARK: - Планирование уведомления для конкретного долга
    private func scheduleNotificationForDebt(_ debt: Debt) {
        guard let dueDate = debt.dueDate else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Уведомление за неделю
        if let weekBefore = calendar.date(byAdding: .day, value: -7, to: dueDate),
           weekBefore > now {
            scheduleNotification(
                for: debt,
                at: weekBefore,
                title: "Напоминание о долге",
                body: createWeeklyReminderMessage(for: debt),
                identifier: "\(debt.id)_week"
            )
        }
        
        // Уведомление за день
        if let dayBefore = calendar.date(byAdding: .day, value: -1, to: dueDate),
           dayBefore > now {
            scheduleNotification(
                for: debt,
                at: dayBefore,
                title: "Срочное напоминание о долге",
                body: createDailyReminderMessage(for: debt),
                identifier: "\(debt.id)_day"
            )
        }
        
        // Уведомление в день платежа
        if dueDate > now {
            scheduleNotification(
                for: debt,
                at: dueDate,
                title: "Сегодня день платежа!",
                body: createDueDateMessage(for: debt),
                identifier: "\(debt.id)_due"
            )
        }
    }
    
    // MARK: - Создание уведомления
    private func scheduleNotification(for debt: Debt, at date: Date, title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Добавляем данные о долге в userInfo для обработки тапа
        content.userInfo = [
            "debtId": debt.id.uuidString,
            "debtorName": debt.debtorName,
            "amount": debt.amount,
            "type": debt.type.rawValue
        ]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка при планировании уведомления: \(error)")
            }
        }
    }
    
    // MARK: - Немедленные уведомления
    func showImmediateNotification(title: String, body: String) {
        guard isNotificationEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        // Используем минимальный интервал для немедленного показа
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.01, repeats: false)
        let identifier = "immediate_\(UUID().uuidString)"
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Ошибка при отправке немедленного уведомления: \(error)")
            } else {
                print("Уведомление отправлено: \(title)")
            }
        }
    }
    

    
    // MARK: - Создание сообщений для уведомлений
    private func createWeeklyReminderMessage(for debt: Debt) -> String {
        if debt.type == .owedToMe {
            return "Через неделю истекает срок долга. \(debt.debtorName) должен вам \(debt.formattedAmountWithInterest)."
        } else {
            return "Через неделю истекает срок платежа. Вы должны \(debt.debtorName) \(debt.formattedAmountWithInterest)."
        }
    }
    
    private func createDailyReminderMessage(for debt: Debt) -> String {
        if debt.type == .owedToMe {
            return "Завтра истекает срок долга! \(debt.debtorName) должен вам \(debt.formattedAmountWithInterest)."
        } else {
            return "Завтра крайний срок платежа! Вы должны \(debt.debtorName) \(debt.formattedAmountWithInterest)."
        }
    }
    
    private func createDueDateMessage(for debt: Debt) -> String {
        if debt.type == .owedToMe {
            return "Сегодня крайний день! \(debt.debtorName) должен вам \(debt.formattedAmountWithInterest)."
        } else {
            return "Сегодня крайний день платежа! Вы должны \(debt.debtorName) \(debt.formattedAmountWithInterest)."
        }
    }
    
    // MARK: - Отмена уведомлений
    func cancelNotificationForDebt(_ debt: Debt) {
        let identifiers = [
            "\(debt.id)_week",
            "\(debt.id)_day",
            "\(debt.id)_due"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Получение запланированных уведомлений
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { notifications in
            DispatchQueue.main.async {
                completion(notifications)
            }
        }
    }
    
    // MARK: - Обработка действий с уведомлениями
    func handleNotificationAction(response: UNNotificationResponse) {
        // Здесь можно добавить логику обработки тапа по уведомлению
        // Например, открытие конкретного долга в приложении
        let userInfo = response.notification.request.content.userInfo
        
        if let debtIdString = userInfo["debtId"] as? String,
           let debtId = UUID(uuidString: debtIdString) {
            // Можно отправить уведомление для навигации к конкретному долгу
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenDebtDetail"),
                object: nil,
                userInfo: ["debtId": debtId]
            )
        }
    }
}
