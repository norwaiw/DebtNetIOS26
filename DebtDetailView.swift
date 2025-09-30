import SwiftUI

struct DebtDetailView: View {
    let debt: Debt
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditDebt = false
    @State private var showingDeleteAlert = false
    @State private var showingStatusChangeAlert = false
    @State private var showingAddPaymentAlert = false
    @State private var showingPaymentErrorAlert = false
    @State private var paymentErrorMessage: String = ""
    
    // Temporary state for new payment amount
    @State private var paymentAmountText: String = ""
    
    private var currentDebt: Debt {
        debtStore.debts.first(where: { $0.id == debt.id }) ?? debt
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                headerSection
                    .padding()
                    .background(themeManager.backgroundColor)
                
                // Scrollable Content
                ScrollView {
                    VStack(spacing: 24) {
                        amountSection
                        detailsSection
                        datesSection
                        actionsSection
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .alert("Удалить долг", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                debtStore.deleteDebt(currentDebt)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Вы уверены, что хотите удалить долг от \(currentDebt.debtorName) на сумму \(currentDebt.formattedAmount)?")
        }
        .alert(currentDebt.isPaid ? "Вернуть долг в активное состояние?" : "Отметить долг как погашенный?", isPresented: $showingStatusChangeAlert) {
            Button("Отмена", role: .cancel) { }
            Button(currentDebt.isPaid ? "Вернуть" : "Погасить") {
                debtStore.togglePaidStatus(currentDebt)
            }
        } message: {
            Text(currentDebt.isPaid ? 
                 "Долг от \(currentDebt.debtorName) на сумму \(currentDebt.formattedAmount) будет возвращён в активное состояние" :
                 "Вы уверены, что долг от \(currentDebt.debtorName) на сумму \(currentDebt.formattedAmount) погашен?")
        }
        .sheet(isPresented: $showingEditDebt) {
            EditDebtView(debt: currentDebt)
                .environmentObject(debtStore)
                .environmentObject(themeManager)
        }
        .overlay(alignment: .center) {
            if showingAddPaymentAlert {
                PaymentInputAlert(
                    title: "Новый платеж",
                    message: "Введите сумму частичного платежа",
                    amountText: $paymentAmountText,
                    maxAmount: currentDebt.remainingAmount,
                    onCancel: {
                        showingAddPaymentAlert = false
                        paymentAmountText = ""
                    },
                    onConfirm: {
                        commitPayment()
                    }
                )
                .ignoresSafeArea(.keyboard)
                .environmentObject(themeManager)
            }
        }
        .alert("Ошибка", isPresented: $showingPaymentErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(paymentErrorMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(themeManager.primaryTextColor)
                        .font(.title2)
                }
                
                Spacer()
                
                Text("Детали долга")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Button(action: {
                    showingEditDebt = true
                }) {
                    Image(systemName: "pencil")
                        .foregroundColor(themeManager.systemGrayColor)
                        .font(.title2)
                }
            }
            
            // Status indicator
            if currentDebt.isPaid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("ПОГАШЕН")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.2))
                )
            }
        }
    }
    
    private var amountSection: some View {
        VStack(spacing: 16) {
            // Large amount display
            VStack(spacing: 8) {
                Text(currentDebt.amountWithSign)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(currentDebt.type == .owedToMe ? .green : .red)
                
                Text("RUB")
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Type indicator
            HStack {
                Circle()
                    .fill(currentDebt.type == .owedToMe ? Color.green : Color.red)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: currentDebt.type == .owedToMe ? "arrow.down" : "arrow.up")
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .bold))
                    )
                
                Text(currentDebt.type.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.primaryTextColor)
            }
            
            // Progress bar for partial payments
            if !currentDebt.isPaid {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: currentDebt.progress)
                        .tint(Color.green)
                    Text("Погашено: \(currentDebt.formattedAmountPaid) / \(currentDebt.formattedAmount)")
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: themeManager.shadowColor, radius: 3, x: 0, y: 2)
        )
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Информация")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            VStack(spacing: 12) {
                DetailRow(title: "Должник", value: currentDebt.debtorName)
                DetailRow(title: "Описание", value: currentDebt.description.isEmpty ? "Не указано" : currentDebt.description)
                DetailRow(title: "Категория", value: currentDebt.category.rawValue)
                
                if currentDebt.isOverdue && !currentDebt.isPaid {
                    HStack {
                        Text("Статус")
                            .font(.system(size: 14))
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                        
                        Text("ПРОСРОЧЕН")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red.opacity(0.2))
                            )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
            )
        }
    }
    
    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Даты")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Дата создания",
                    value: "\(dateFormatter.string(from: currentDebt.dateCreated)) в \(timeFormatter.string(from: currentDebt.dateCreated))"
                )
                
                if let dueDate = currentDebt.dueDate {
                    DetailRow(
                        title: "Срок возврата",
                        value: dateFormatter.string(from: dueDate),
                        valueColor: currentDebt.isOverdue && !currentDebt.isPaid ? .red : nil
                    )
                } else {
                    DetailRow(title: "Срок возврата", value: "Не установлен")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
            )
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Add partial payment button
            if !currentDebt.isPaid {
                Button(action: {
                    showingAddPaymentAlert = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                        Text("Добавить платеж")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                }
            }
            
            // Mark as paid/unpaid button
            Button(action: {
                showingStatusChangeAlert = true
            }) {
                HStack {
                    Image(systemName: currentDebt.isPaid ? "arrow.uturn.left.circle" : "checkmark.circle")
                        .font(.system(size: 20))
                    
                    Text(currentDebt.isPaid ? "Вернуть в активные" : "Отметить как погашенный")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(currentDebt.isPaid ? Color.orange : Color.green)
                )
            }
            
            // Delete button
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                    
                    Text("Удалить долг")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red)
                )
            }
        }
    }

    private var parsedPaymentAmount: Double {
        Double(paymentAmountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func commitPayment() {
        let amount = parsedPaymentAmount
        guard amount > 0 else {
            paymentErrorMessage = "Введите корректную сумму платежа"
            showingPaymentErrorAlert = true
            return
        }
        guard amount <= currentDebt.remainingAmount else {
            paymentErrorMessage = "Сумма не должна превышать остаток долга (\(Int(currentDebt.remainingAmount)) ₽)"
            showingPaymentErrorAlert = true
            return
        }
        debtStore.addPayment(amount: amount, to: currentDebt)
        paymentAmountText = ""
        showingAddPaymentAlert = false
    }
}

struct DetailRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: String
    var valueColor: Color?
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(themeManager.secondaryTextColor)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(valueColor ?? themeManager.primaryTextColor)
                .multilineTextAlignment(.trailing)
        }
    }
}

#if DEBUG
#Preview {
    DebtDetailView(debt: Debt(
        debtorName: "Фадей",
        amount: 10000,
        description: "Тестовый пример",
        dateCreated: Date(),
        dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
        category: .personal,
        type: .owedToMe
    ))
    .environmentObject(DebtStore())
    .environmentObject(ThemeManager())
}
#endif

struct PaymentInputAlert: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let message: String
    @Binding var amountText: String
    let maxAmount: Double
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    private var isValid: Bool {
        let normalized = amountText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized) else { return false }
        return value > 0 && value <= maxAmount
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
                
                HStack {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(ThemedTextFieldStyle())
                    
                    Text("₽")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.trailing, 12)
                }
                
                Text("Остаток: \(Int(maxAmount)) ₽")
                    .font(.caption)
                    .foregroundColor(themeManager.secondaryTextColor)
                
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Отмена")
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(themeManager.cardSecondaryBackgroundColor)
                            )
                    }
                    .foregroundColor(themeManager.primaryTextColor)
                    
                    Button(action: onConfirm) {
                        Text("Добавить")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .foregroundColor(.white)
                    .disabled(!isValid)
                    .opacity(isValid ? 1.0 : 0.6)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.shadowColor, radius: 3, x: 0, y: 2)
            )
            .padding(.horizontal, 24)
        }
    }
}

