import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var pendingNotifications: [UNNotificationRequest] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                
                List {
                // Секция статуса уведомлений
                Section {
                    HStack {
                        Image(systemName: notificationManager.isNotificationEnabled ? "bell.fill" : "bell.slash")
                            .foregroundColor(notificationManager.isNotificationEnabled ? themeManager.successColor : themeManager.destructiveColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Уведомления")
                                .font(.headline)
                            Text(notificationManager.isNotificationEnabled ? "Включены" : "Отключены")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        if !notificationManager.isNotificationEnabled {
                            Button("Включить") {
                                notificationManager.requestNotificationPermission()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Статус")
                } footer: {
                    Text("Разрешите уведомления для получения напоминаний о сроках долгов")
                }
                
                // Секция управления уведомлениями
                if notificationManager.isNotificationEnabled {
                    Section {
                        Button {
                            scheduleAllNotifications()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.plus")
                                    .foregroundColor(themeManager.accentColor)
                                Text("Запланировать уведомления")
                                Spacer()
                                Text("\(activeDebtsWithDueDates.count) долгов")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                        
                        Button {
                            cancelAllNotifications()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.minus")
                                    .foregroundColor(themeManager.destructiveColor)
                                Text("Отменить все уведомления")
                                Spacer()
                                Text("\(pendingNotifications.count)")
                                    .font(.caption)
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                        

                    } header: {
                        Text("Управление")
                    } footer: {
                        Text("Автоматические уведомления за неделю, день и в день платежа")
                    }
                    
                    // Секция запланированных уведомлений
                    if !pendingNotifications.isEmpty {
                        Section {
                            ForEach(pendingNotifications, id: \.identifier) { notification in
                                NotificationRowView(notification: notification)
                            }
                        } header: {
                            Text("Запланированные уведомления (\(pendingNotifications.count))")
                        }
                    }
                    
                    // Секция долгов с датами
                    Section {
                        ForEach(activeDebtsWithDueDates, id: \.id) { debt in
                            DebtNotificationRowView(debt: debt)
                        }
                    } header: {
                        Text("Долги с установленными сроками")
                    } footer: {
                        if activeDebtsWithDueDates.isEmpty {
                            Text("Нет долгов с установленными сроками платежа")
                        }
                    }
                }
                
                // Секция информации
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Типы уведомлений:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(themeManager.warningColor)
                                    .frame(width: 20)
                                Text("За 7 дней до срока")
                                    .font(.caption)
                            }
                            
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.yellow)
                                    .frame(width: 20)
                                Text("За 1 день до срока")
                                    .font(.caption)
                            }
                            
                            HStack {
                                Image(systemName: "alarm")
                                    .foregroundColor(themeManager.destructiveColor)
                                    .frame(width: 20)
                                Text("В день платежа")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Информация")
                }
            }
            .navigationTitle("Уведомления")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadPendingNotifications()
            }
            .alert("Уведомления", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var activeDebtsWithDueDates: [Debt] {
        debtStore.activeDebts.filter { $0.dueDate != nil }
    }
    
    // MARK: - Functions
    private func scheduleAllNotifications() {
        notificationManager.scheduleNotificationsForDebts(debtStore.activeDebts)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadPendingNotifications()
            alertMessage = "Уведомления запланированы для \(activeDebtsWithDueDates.count) долгов"
            showingAlert = true
        }
    }
    
    private func cancelAllNotifications() {
        notificationManager.cancelAllNotifications()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            loadPendingNotifications()
            alertMessage = "Все уведомления отменены"
            showingAlert = true
        }
    }
    
    private func loadPendingNotifications() {
        notificationManager.getPendingNotifications { notifications in
            self.pendingNotifications = notifications.sorted { 
                let date1 = ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
                let date2 = ($1.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() ?? Date.distantFuture
                return date1 < date2
            }
        }
    }
}

// MARK: - Supporting Views
struct NotificationRowView: View {
    let notification: UNNotificationRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(notification.content.title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(notification.content.body)
                .font(.caption)
                .foregroundColor(Color.secondary)
                .lineLimit(2)
            
            if let triggerDate = (notification.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() {
                Text(formatDate(triggerDate))
                    .font(.caption)
                    .foregroundColor(Color.blue)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}

struct DebtNotificationRowView: View {
    let debt: Debt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(debt.debtorName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(debt.formattedAmountWithInterest)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(debt.type == .owedToMe ? .green : .red)
            }
            
            if let dueDate = debt.dueDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text("Срок: \(formatDueDate(dueDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if debt.isOverdue {
                        Text("Просрочено")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(Color.red)
                    } else {
                        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
                        Text("\(daysLeft) дн.")
                            .font(.caption)
                            .foregroundColor(daysLeft <= 7 ? Color.orange : Color.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
}



#Preview {
    NotificationSettingsView()
        .environmentObject(DebtStore())
        .environmentObject(ThemeManager())
}