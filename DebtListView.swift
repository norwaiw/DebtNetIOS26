import SwiftUI
import Combine

struct DebtListView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var showingAddDebt = false
    @State private var selectedFilter: FilterOption = .all

    @State private var archiveOffset: CGFloat = 0
    @State private var showingArchive = false
    @State private var showingNotificationSettings = false
    
    @State private var visibleDebts: [Debt] = []
    
    enum FilterOption: String, CaseIterable {
        case all = "Все"
        case owedToMe = "Мне должны"
        case iOwe = "Я должен"
    }
    
    var filteredDebts: [Debt] {
        switch selectedFilter {
        case .all:
            return debtStore.activeDebts.sorted { $0.dateCreated > $1.dateCreated }
        case .owedToMe:
            return debtStore.activeDebts.filter { $0.type == .owedToMe }.sorted { $0.dateCreated > $1.dateCreated }
        case .iOwe:
            return debtStore.activeDebts.filter { $0.type == .iOwe }.sorted { $0.dateCreated > $1.dateCreated }
        }
    }
    
    var archivedDebts: [Debt] {
        return debtStore.paidDebts.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    var upcomingDebtsCount: Int {
        let calendar = Calendar.current
        let now = Date()
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        
        return debtStore.activeDebts.filter { debt in
            guard let dueDate = debt.dueDate else { return false }
            return dueDate > now && dueDate <= nextWeek
        }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundColor.ignoresSafeArea()
                mainContentView
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddDebt) {
            AddDebtView()
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
                .environmentObject(themeManager)
        }
        .onAppear { updateVisibleDebts() }
        .onChange(of: selectedFilter) { updateVisibleDebts() }
        .onReceive(debtStore.$debts) { _ in updateVisibleDebts() }

    }
    
    private var mainContentView: some View {
        VStack {
            headerView
            
            filterButtonsView
            
            ScrollView {
                VStack(spacing: 20) {
                    summaryCardsView
                    
                    archiveNavigationLinkView
                    
                    // Список долгов
                    debtListContent
                    
                    // Убрали секцию архива, так как теперь переходим на отдельный экран
                }
            }
            .scrollIndicators(.visible)
            .contentShape(Rectangle()) // Добавляем contentShape для всего ScrollView
            .coordinateSpace(name: "scrollView") // Добавляем координатное пространство для лучшего скроллинга
            // Убрали pull-to-refresh для архива
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Долги")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.primaryTextColor)
                
                // Показываем количество долгов
                if !visibleDebts.isEmpty {
                    Text("\(visibleDebts.count) \(visibleDebts.count == 1 ? "долг" : visibleDebts.count < 5 ? "долга" : "долгов")")
                        .font(.caption)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Notification button
            Button(action: {
                showingNotificationSettings = true
            }) {
                ZStack {
                    // Blue circular background
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: notificationManager.isNotificationEnabled ? "bell.fill" : "bell")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                    
                    // Badge for pending notifications
                    if notificationManager.isNotificationEnabled && upcomingDebtsCount > 0 {
                        Text("\(upcomingDebtsCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Circle().fill(Color.red))
                            .offset(x: 12, y: -12)
                    }
                }
            }
            .padding(.trailing, 8)
            
            Button(action: {
                showingAddDebt = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.red))
            }
        }
        .padding(.horizontal)
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
    
    private var filterButtonsView: some View {
        HStack(spacing: 12) {
            ForEach(FilterOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedFilter = option
                }) {
                    Text(option.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedFilter == option ? .white : themeManager.secondaryTextColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedFilter == option ? Color.red : themeManager.cardBackgroundColor)
                                .shadow(color: selectedFilter == option ? Color.red.opacity(0.4) : themeManager.shadowColor, radius: selectedFilter == option ? 6 : 1, x: 0, y: selectedFilter == option ? 2 : 1)
                        )
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
    
    private var summaryCardsView: some View {
        HStack(spacing: 16) {
            owedToMeCard
            iOweCard
        }
        .padding(.horizontal)
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
    
    private var owedToMeCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Мне должны")
                .font(.system(size: 14))
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : themeManager.secondaryTextColor)
            
            // Display amount with interest as the main amount (without the "С %" line)
            Text("\(Int(debtStore.totalOwedToMeWithInterest)) ₽")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.green)
            
            // Add spacing to match the other card height
            Text(" ")
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.owedToMeCardBackground)
                .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
        )
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
    
    private var iOweCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Я должен")
                .font(.system(size: 14))
                .foregroundColor(themeManager.isDarkMode ? .white.opacity(0.7) : themeManager.secondaryTextColor)
            
            Text("\(Int(debtStore.totalIOweWithInterest)) ₽")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.red)
            
            // Add spacing to match the other card height
            Text(" ")
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.iOweCardBackground)
                .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
        )
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
    
    // Новый NavigationLink к экрану архива
    @ViewBuilder
    private var archiveNavigationLinkView: some View {
        if !archivedDebts.isEmpty {
            NavigationLink {
                ArchivedDebtsView()
                    .environmentObject(debtStore)
                    .environmentObject(themeManager)
            } label: {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text("Архив (\(archivedDebts.count))")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.secondaryTextColor)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var debtListContent: some View {
        LazyVStack(spacing: 12) {
            ForEach(visibleDebts) { debt in
                DebtHistoryRowView(debt: debt)
            }
            
            // Добавляем пустое пространство в конце для лучшего UX
            if !visibleDebts.isEmpty {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 20)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20) // Добавляем отступ снизу для лучшего UX
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
    
    private var debtListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(visibleDebts) { debt in
                    DebtHistoryRowView(debt: debt)
                }
                
                // Добавляем пустое пространство в конце для лучшего UX
                if !visibleDebts.isEmpty {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 20)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20) // Добавляем отступ снизу для лучшего UX
        }
        .scrollIndicators(.visible) // Показываем индикаторы скролла
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped() // Обрезаем содержимое чтобы не выходило за границы
        .refreshable {
            // This provides native pull-to-refresh behavior
            if !archivedDebts.isEmpty {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingArchive = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var archiveSection: some View {
        if showingArchive && !archivedDebts.isEmpty {
            VStack(spacing: 16) {
                archiveHeaderView
                archiveListView
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.shadowColor, radius: 3, x: 0, y: 2)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
        }
    }
    
    private var archiveHeaderView: some View {
        HStack {
            Text("Архив погашенных долгов")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.primaryTextColor)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingArchive = false
                }
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(themeManager.secondaryTextColor)
                    .font(.title3)
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
    
    private var archiveListView: some View {
            LazyVStack(spacing: 12) {
                ForEach(archivedDebts) { debt in
                    ArchivedDebtRowView(debt: debt)
                }
            }
            .padding(.horizontal)
            .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
    }
}

private extension DebtListView {
    func updateVisibleDebts() {
        switch selectedFilter {
        case .all:
            visibleDebts = debtStore.activeDebts.sorted { $0.dateCreated > $1.dateCreated }
        case .owedToMe:
            visibleDebts = debtStore.activeDebts.filter { $0.type == .owedToMe }.sorted { $0.dateCreated > $1.dateCreated }
        case .iOwe:
            visibleDebts = debtStore.activeDebts.filter { $0.type == .iOwe }.sorted { $0.dateCreated > $1.dateCreated }
        }
    }
}

struct DebtHistoryRowView: View {
    let debt: Debt
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingStatusChangeAlert = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showingDeleteButton = false
    @State private var showingPayButton = false
    @State private var showingDetail = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    // Split the complex view into smaller computed properties
    private var deleteButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                swipeOffset = 0
                showingDeleteButton = false
            }
            // Add a small delay before showing the alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                debtStore.deleteDebt(debt)
            }
        }) {
            VStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Удалить")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 60)
            .background(Color.red)
            .cornerRadius(12)
        }
        .padding(.trailing, 16)
    }
    
    private var payButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                swipeOffset = 0
                showingPayButton = false
            }
            // Add a small delay before marking as paid
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                debtStore.togglePaidStatus(debt)
            }
        }) {
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Погасить")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 60)
            .background(Color.green)
            .cornerRadius(12)
        }
        .padding(.leading, 16)
    }
    
    private var profileIcon: some View {
        Circle()
            .fill(Color.green.opacity(0.3))
            .frame(width: 40, height: 40)
            .overlay(
                Text(String(debt.debtorName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeManager.primaryTextColor)
            )
    }
    
    private var debtInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(debt.debtorName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
            }
            
            Text(debt.description)
                .font(.system(size: 14))
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(1)
            
            HStack {
                Text(dateFormatter.string(from: debt.dateCreated))
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Spacer()
            }
        }
    }
    
    private var amountSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Show amount with interest if interest rate exists, otherwise show base amount
            if debt.type == .owedToMe {
                if debt.interestRate > 0 {
                    Text("\(Int(debt.amountWithInterest)) ₽")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("\(String(format: "%.1f", debt.interestRate))%")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.secondaryTextColor)
                } else {
                    Text("\(Int(debt.amount)) ₽")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.green)
                }
            } else {
                if debt.interestRate > 0 {
                    Text("-\(Int(debt.amountWithInterest)) ₽")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                    
                    Text("\(String(format: "%.1f", debt.interestRate))%")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.secondaryTextColor)
                } else {
                    Text("-\(Int(debt.amount)) ₽")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            
            // Status icon - same green as stat cards
            Button(action: {
                showingStatusChangeAlert = true
            }) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
                    .background(
                        Circle()
                            .fill(themeManager.isDarkMode ? Color.black : Color.white)
                            .frame(width: 26, height: 26)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                profileIcon
                debtInfo
                amountSection
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: themeManager.shadowColor, radius: 2, x: 0, y: 1)
        )
        .offset(x: swipeOffset)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .simultaneousGesture(swipeGesture)
        .allowsHitTesting(true) // Убеждаемся, что жесты работают правильно
    }
    
    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10) // Увеличиваем минимальное расстояние для активации жеста
            .onChanged { value in
                let translation = value.translation.width
                let verticalTranslation = value.translation.height
                
                // Улучшенная логика: только горизонтальные свайпы с большим порогом
                if abs(translation) > abs(verticalTranslation) * 1.5 && translation < 0 {
                    // Swiping left - show delete button
                    withAnimation(.easeOut(duration: 0.1)) {
                        swipeOffset = max(translation, -100)
                        showingDeleteButton = swipeOffset < -50
                        showingPayButton = false
                    }
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                let verticalTranslation = value.translation.height
                
                // Улучшенная логика: только четкие горизонтальные свайпы
                if abs(translation) > abs(verticalTranslation) * 1.5 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if translation < -80 {
                            // If swiped left far enough, show delete button
                            swipeOffset = -100
                            showingDeleteButton = true
                            showingPayButton = false
                        } else {
                            // Snap back to original position
                            swipeOffset = 0
                            showingDeleteButton = false
                            showingPayButton = false
                        }
                    }
                } else {
                    // Reset swipe state for vertical scrolls
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        swipeOffset = 0
                        showingDeleteButton = false
                        showingPayButton = false
                    }
                }
            }
    }
    
    var body: some View {
        ZStack {
            // Background actions
            HStack {
                Spacer()
                if showingDeleteButton {
                    deleteButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            mainContent
        }
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
        .alert("Отметить долг как погашенный?", isPresented: $showingStatusChangeAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Погасить", role: .destructive) {
                debtStore.togglePaidStatus(debt)
            }
        } message: {
            Text("Вы уверены, что долг от \(debt.debtorName) на сумму \(debt.formattedAmount) погашен?")
        }
        .sheet(isPresented: $showingDetail) {
            DebtDetailView(debt: debt)
                .environmentObject(themeManager)
                .environmentObject(debtStore)
        }
    }
}

struct ArchivedDebtRowView: View {
    let debt: Debt
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingStatusChangeAlert = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showingDeleteButton = false
    @State private var showingRestoreButton = false
    @State private var showingDetail = false
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter
    }
    
    // Split the complex view into smaller computed properties
    private var deleteButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                swipeOffset = 0
                showingDeleteButton = false
            }
            // Add a small delay before deleting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                debtStore.deleteDebt(debt)
            }
        }) {
            VStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Удалить")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 60)
            .background(Color.red)
            .cornerRadius(12)
        }
        .padding(.trailing, 16)
    }
    
    private var restoreButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                swipeOffset = 0
                showingRestoreButton = false
            }
            // Add a small delay before restoring
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                debtStore.togglePaidStatus(debt)
            }
        }) {
            VStack {
                Image(systemName: "arrow.uturn.left.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                Text("Вернуть")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 60)
            .background(Color.orange)
            .cornerRadius(12)
        }
        .padding(.leading, 16)
    }
    
    private var archivedIcon: some View {
        Circle()
            .fill(Color.gray)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
            )
    }
    
    private var archivedDebtInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(debt.debtorName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .strikethrough(true)
                
                Text("ПОГАШЕН")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.opacity(0.2))
                    )
            }
            
            Text(debt.description)
                .font(.system(size: 14))
                .foregroundColor(themeManager.secondaryTextColor)
                .lineLimit(1)
            
            Text(dateFormatter.string(from: debt.dateCreated))
                .font(.system(size: 12))
                .foregroundColor(themeManager.secondaryTextColor)
        }
    }
    
    private var archivedAmountSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(debt.amountWithSign)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.secondaryTextColor)
                .strikethrough(true)
            
            if debt.interestRate > 0 {
                Text(debt.amountWithInterestAndSign)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.8))
                    .strikethrough(true)
                
                Text("\(String(format: "%.1f", debt.interestRate))%")
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.secondaryTextColor)
            } else {
                Text("RUB")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            // Quick status toggle button
            Button(action: {
                showingStatusChangeAlert = true
            }) {
                Image(systemName: "arrow.uturn.left.circle")
                    .foregroundColor(.orange)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var archivedMainContent: some View {
        HStack(spacing: 16) {
            archivedIcon
            archivedDebtInfo
            Spacer()
            archivedAmountSection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.cardSecondaryBackgroundColor)
                .shadow(color: themeManager.shadowColor, radius: 1, x: 0, y: 1)
        )
        .opacity(0.7)
        .offset(x: swipeOffset)
        .contentShape(Rectangle())
        .onTapGesture {
            showingDetail = true
        }
        .simultaneousGesture(archivedSwipeGesture)
        .allowsHitTesting(true) // Убеждаемся, что жесты работают правильно
    }
    
    private var archivedSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 10) // Увеличиваем минимальное расстояние для активации жеста
            .onChanged { value in
                let translation = value.translation.width
                let verticalTranslation = value.translation.height
                
                // Улучшенная логика: только горизонтальные свайпы с большим порогом
                if abs(translation) > abs(verticalTranslation) * 1.5 {
                    if translation < 0 {
                        // Swiping left - show delete button
                        withAnimation(.easeOut(duration: 0.1)) {
                            swipeOffset = max(translation, -100)
                            showingDeleteButton = swipeOffset < -50
                            showingRestoreButton = false
                        }
                    } else if translation > 0 {
                        // Swiping right - show restore button
                        withAnimation(.easeOut(duration: 0.1)) {
                            swipeOffset = min(translation, 100)
                            showingRestoreButton = swipeOffset > 50
                            showingDeleteButton = false
                        }
                    }
                }
            }
            .onEnded { value in
                let translation = value.translation.width
                let verticalTranslation = value.translation.height
                
                // Улучшенная логика: только четкие горизонтальные свайпы
                if abs(translation) > abs(verticalTranslation) * 1.5 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if translation < -80 {
                            // If swiped left far enough, show delete button
                            swipeOffset = -100
                            showingDeleteButton = true
                            showingRestoreButton = false
                        } else if translation > 80 {
                            // If swiped right far enough, show restore button
                            swipeOffset = 100
                            showingRestoreButton = true
                            showingDeleteButton = false
                        } else {
                            // Snap back to original position
                            swipeOffset = 0
                            showingDeleteButton = false
                            showingRestoreButton = false
                        }
                    }
                } else {
                    // Reset swipe state for vertical scrolls
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        swipeOffset = 0
                        showingDeleteButton = false
                        showingRestoreButton = false
                    }
                }
            }
    }
    
    var body: some View {
        ZStack {
            // Background actions
            HStack {
                if showingRestoreButton {
                    restoreButton
                }
                Spacer()
                if showingDeleteButton {
                    deleteButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            archivedMainContent
        }
        .contentShape(Rectangle()) // Добавляем contentShape для лучшего скроллинга
        .alert("Вернуть долг в активное состояние?", isPresented: $showingStatusChangeAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Вернуть", role: .none) {
                debtStore.togglePaidStatus(debt)
            }
        } message: {
            Text("Долг от \(debt.debtorName) на сумму \(debt.formattedAmount) будет возвращён в активное состояние")
        }
        .sheet(isPresented: $showingDetail) {
            DebtDetailView(debt: debt)
                .environmentObject(themeManager)
                .environmentObject(debtStore)
        }
    }
}

#Preview {
    DebtListView()
        .environmentObject(DebtStore())
        .environmentObject(ThemeManager())
}
