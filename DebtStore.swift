import Foundation
import SwiftUI

class DebtStore: ObservableObject {
    @Published var debts: [Debt] = []
    
    private let saveKey = "SavedDebts"
    
    init() {
        loadDebts()
    }
    
    func addDebt(_ debt: Debt) {
        debts.append(debt)
        saveDebts()
        scheduleNotificationsIfEnabled()
    }
    
    func updateDebt(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index] = debt
            saveDebts()
            scheduleNotificationsIfEnabled()
        }
    }
    
    func deleteDebt(_ debt: Debt) {
        // Отменяем уведомления для удаляемого долга
        NotificationManager.shared.cancelNotificationForDebt(debt)
        debts.removeAll { $0.id == debt.id }
        saveDebts()
    }
    
    func clearAllData() {
        debts.removeAll()
        saveDebts()
    }
    
    func markAsPaid(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index].isPaid = true
            debts[index].amountPaid = debts[index].amount
            // Отменяем уведомления для погашенного долга
            NotificationManager.shared.cancelNotificationForDebt(debt)
            saveDebts()
        }
    }
    
    func markAsUnpaid(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index].isPaid = false
            debts[index].amountPaid = 0
            saveDebts()
            scheduleNotificationsIfEnabled()
        }
    }
    
    func togglePaidStatus(_ debt: Debt) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            let wasPaid = debts[index].isPaid
            debts[index].isPaid.toggle()
            
            if debts[index].isPaid {
                // Помечаем как погашенный
                debts[index].amountPaid = debts[index].amount
            } else {
                // Возвращаем в активные
                debts[index].amountPaid = 0
            }
            
            if debts[index].isPaid {
                // Долг погашен - отменяем уведомления
                NotificationManager.shared.cancelNotificationForDebt(debt)
            } else if !wasPaid {
                // Долг снова активен - планируем уведомления
                scheduleNotificationsIfEnabled()
            }
            
            saveDebts()
        }
    }
    
    // MARK: - Statistics
    var totalOwedToMe: Double {
        debts.filter { !$0.isPaid && $0.type == .owedToMe }.reduce(0) { $0 + $1.amount }
    }
    
    var totalIOwe: Double {
        debts.filter { !$0.isPaid && $0.type == .iOwe }.reduce(0) { $0 + $1.amount }
    }
    
    // Суммы с процентами
    var totalOwedToMeWithInterest: Double {
        debts.filter { !$0.isPaid && $0.type == .owedToMe }.reduce(0) { $0 + $1.amountWithInterest }
    }
    
    var totalIOweWithInterest: Double {
        debts.filter { !$0.isPaid && $0.type == .iOwe }.reduce(0) { $0 + $1.amountWithInterest }
    }
    
    var totalDebtAmount: Double {
        debts.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var totalPaidAmount: Double {
        debts.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    var overdueDebts: [Debt] {
        debts.filter { $0.isOverdue }
    }
    
    var activeDebts: [Debt] {
        debts.filter { !$0.isPaid }
    }
    
    var paidDebts: [Debt] {
        debts.filter { $0.isPaid }
    }
    
    var debtsOwedToMe: [Debt] {
        debts.filter { $0.type == .owedToMe }
    }
    
    var debtsIOwe: [Debt] {
        debts.filter { $0.type == .iOwe }
    }
    
    func debtsByCategory() -> [Debt.DebtCategory: [Debt]] {
        Dictionary(grouping: debts) { $0.category }
    }
    
    // MARK: - Partial Payments
    /// Добавляет частичный платёж к долгу. Если сумма выплат достигает полной суммы, долг помечается как погашенный.
    func addPayment(amount: Double, to debt: Debt) {
        guard amount > 0 else { return }
        guard let index = debts.firstIndex(where: { $0.id == debt.id }) else { return }
        debts[index].amountPaid += amount
        // Не допускаем превышения полной суммы
        if debts[index].amountPaid >= debts[index].amount {
            debts[index].amountPaid = debts[index].amount
            debts[index].isPaid = true
            // Отменяем уведомления, если долг погашен
            NotificationManager.shared.cancelNotificationForDebt(debt)
        }
        saveDebts()
    }
    
    // MARK: - Notifications
    private func scheduleNotificationsIfEnabled() {
        // Планируем уведомления только если они включены
        if NotificationManager.shared.isNotificationEnabled {
            NotificationManager.shared.scheduleNotificationsForDebts(activeDebts)
        }
    }
    
    // MARK: - Persistence
    private func saveDebts() {
        if let encoded = try? JSONEncoder().encode(debts) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadDebts() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Debt].self, from: data) {
            debts = decoded
        }
    }
}
