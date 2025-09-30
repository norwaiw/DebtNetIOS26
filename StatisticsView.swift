import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedFilter: DebtFilter = .all
    
    enum DebtFilter {
        case all
        case owedToMe
        case iOwe
        case active
        case overdue
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    HStack {
                        Text("Статистика")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    LazyVStack(spacing: 24) {
                        // Summary Cards
                        SummaryCardsView(selectedFilter: $selectedFilter)
                        
                        // Filtered Debts List
                        if selectedFilter != .all {
                            FilteredDebtsView(filter: selectedFilter)
                        } else {
                            // Category Statistics
                            CategoryStatisticsView()
                            
                            // Overdue Debts Alert
                            if !debtStore.overdueDebts.isEmpty {
                                OverdueDebtsView()
                            }
                            
                            // Recent Activity
                            RecentActivityView()
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct SummaryCardsView: View {
    @EnvironmentObject var debtStore: DebtStore
    @Binding var selectedFilter: StatisticsView.DebtFilter
    
    var body: some View {
        VStack(spacing: 18) {
            // Первый ряд карточек
            HStack(spacing: 18) {
                StatCard(
                    title: "Мне должны",
                    value: debtStore.totalOwedToMeWithInterest,
                    color: .green,
                    icon: "arrow.down.circle.fill",
                    isActive: selectedFilter == .owedToMe
                ) {
                    selectedFilter = selectedFilter == .owedToMe ? .all : .owedToMe
                }
                
                StatCard(
                    title: "Я должен",
                    value: debtStore.totalIOweWithInterest,
                    color: .red,
                    icon: "arrow.up.circle.fill",
                    isActive: selectedFilter == .iOwe
                ) {
                    selectedFilter = selectedFilter == .iOwe ? .all : .iOwe
                }
            }
            
            // Второй ряд карточек  
            HStack(spacing: 18) {
                StatCard(
                    title: "Активных долгов",
                    value: Double(debtStore.activeDebts.count),
                    color: .blue,
                    icon: "list.bullet.circle.fill",
                    isCount: true,
                    isActive: selectedFilter == .active
                ) {
                    selectedFilter = selectedFilter == .active ? .all : .active
                }
                
                StatCard(
                    title: "Просрочено",
                    value: Double(debtStore.overdueDebts.count),
                    color: .orange,
                    icon: "exclamationmark.triangle.fill",
                    isCount: true,
                    isActive: selectedFilter == .overdue
                ) {
                    selectedFilter = selectedFilter == .overdue ? .all : .overdue
                }
            }
        }
    }
}

struct StatCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let value: Double
    let color: Color
    let icon: String
    let isCount: Bool
    let isActive: Bool
    let onTap: () -> Void
    
    init(title: String, value: Double, color: Color, icon: String, isCount: Bool = false, isActive: Bool = false, onTap: @escaping () -> Void) {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
        self.isCount = isCount
        self.isActive = isActive
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Иконка вверху
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(isActive ? .white : color)
                        .font(.title2)
                        .frame(width: 28, height: 28)
                    
                    Spacer()
                }
                
                // Текст и значение снизу
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(title)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(isActive ? .white : (themeManager.isDarkMode ? .white : themeManager.primaryTextColor))
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(formattedValue)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(isActive ? .white : color)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 100,  alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? color.opacity(0.8) : themeManager.cardBackgroundColor)
                    .shadow(color: themeManager.shadowColor, radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? color : themeManager.borderColor, lineWidth: isActive ? 2 : 0.5)
            )
            .scaleEffect(isActive ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedValue: String {
        if isCount {
            return NumberFormatter.countFormatter.string(from: NSNumber(value: value)) ?? "0"
        } else {
            return NumberFormatter.currencyFormatter.string(from: NSNumber(value: value)) ?? "0 ₽"
        }
    }
}

struct FilteredDebtsView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    let filter: StatisticsView.DebtFilter
    
    private var filteredDebts: [Debt] {
        switch filter {
        case .all:
            return debtStore.debts
        case .owedToMe:
            return debtStore.debts.filter { $0.type == .owedToMe && !$0.isPaid }
        case .iOwe:
            return debtStore.debts.filter { $0.type == .iOwe && !$0.isPaid }
        case .active:
            return debtStore.activeDebts
        case .overdue:
            return debtStore.overdueDebts
        }
    }
    
    private var headerTitle: String {
        switch filter {
        case .all:
            return "Все долги"
        case .owedToMe:
            return "Мне должны"
        case .iOwe:
            return "Я должен"
        case .active:
            return "Активные долги"
        case .overdue:
            return "Просроченные долги"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(headerTitle)
                    .font(.headline)
                    .foregroundColor(themeManager.primaryTextColor)
                
                Spacer()
                
                Text("\(filteredDebts.count)")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            if filteredDebts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .font(.largeTitle)
                        .foregroundColor(themeManager.secondaryTextColor)
                    
                    Text("Нет долгов в этой категории")
                        .font(.subheadline)
                        .foregroundColor(themeManager.secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(filteredDebts) { debt in
                        FilteredDebtRow(debt: debt)
                    }
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

struct FilteredDebtRow: View {
    let debt: Debt
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(debt.debtorName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(debt.description)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.secondaryTextColor)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon(for: debt.category))
                            .font(.caption)
                            .foregroundColor(categoryColor(for: debt.category))
                        Text(debt.category.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(categoryColor(for: debt.category))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(categoryColor(for: debt.category).opacity(0.15))
                    .cornerRadius(6)
                    
                    if debt.isOverdue {
                        Text("Просрочен")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if let dueDate = debt.dueDate {
                        Text(dueDate, formatter: shortDateFormatter)
                            .font(.system(size: 12))
                            .foregroundColor(themeManager.secondaryTextColor)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(debt.formattedAmount)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(debt.type == .owedToMe ? .green : .red)
                
                Text(debt.type.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                if !debt.isPaid {
                    Button("Погасить") {
                        withAnimation {
                            debtStore.markAsPaid(debt)
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                } else {
                    Text("Погашен")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }
}

struct CategoryStatisticsView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("По категориям")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            let categoryGroups = debtStore.debtsByCategory()
            let totalAmount = categoryGroups.values.flatMap { $0 }.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
            
            VStack(spacing: 12) {
                ForEach(Debt.DebtCategory.allCases, id: \.self) { category in
                    if let debts = categoryGroups[category], !debts.isEmpty {
                        CategoryRow(category: category, debts: debts, totalGlobalAmount: totalAmount)
                    }
                }
                
                // Показать пустые категории с заглушкой
                ForEach(Debt.DebtCategory.allCases.filter { category in
                    categoryGroups[category]?.isEmpty ?? true
                }, id: \.self) { category in
                    EmptyCategoryRow(category: category)
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

struct CategoryRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let category: Debt.DebtCategory
    let debts: [Debt]
    let totalGlobalAmount: Double
    
    private var categoryAmount: Double {
        debts.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }
    
    private var activeCount: Int {
        debts.filter { !$0.isPaid }.count
    }
    
    private var overdueCount: Int {
        debts.filter { !$0.isPaid && $0.isOverdue }.count
    }
    
    private var categoryIcon: String {
        switch category {
        case .personal:
            return "person.circle.fill"
        case .business:
            return "briefcase.circle.fill"
        case .family:
            return "house.circle.fill"
        case .friend:
            return "heart.circle.fill"
        case .other:
            return "ellipsis.circle.fill"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .personal:
            return .blue
        case .business:
            return .purple
        case .family:
            return .green
        case .friend:
            return .pink
        case .other:
            return .orange
        }
    }
    
    private var progressPercentage: Double {
        guard totalGlobalAmount > 0 else { return 0 }
        return min(categoryAmount / totalGlobalAmount * 100, 100)
    }
    
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                // Иконка категории
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(categoryColor.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.rawValue)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(themeManager.primaryTextColor)
                        
                        Spacer()
                        
                        Text(NumberFormatter.currencyFormatter.string(from: NSNumber(value: categoryAmount)) ?? "0 ₽")
                            .font(.system(size: 19, weight: .bold, design: .rounded))
                            .foregroundColor(categoryColor)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                                .foregroundColor(themeManager.secondaryTextColor)
                            Text("\(activeCount) активных")
                                .font(.system(size: 12))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        if overdueCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text("\(overdueCount) просрочено")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            
                            // Прогресс-бар
                if categoryAmount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Доля от общего объема")
                            .font(.caption)
                            .foregroundColor(themeManager.secondaryTextColor)
                        
                        Spacer()
                        
                        Text(NumberFormatter.percentageFormatter.string(from: NSNumber(value: progressPercentage/100)) ?? "0%")
                            .font(.caption)
                            .foregroundColor(categoryColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(themeManager.isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(categoryColor)
                                .frame(width: geometry.size.width * (progressPercentage / 100), height: 6)
                                .cornerRadius(3)
                                .animation(.easeInOut(duration: 0.8), value: progressPercentage)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(categoryColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EmptyCategoryRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let category: Debt.DebtCategory
    
    private var categoryIcon: String {
        switch category {
        case .personal:
            return "person.circle"
        case .business:
            return "briefcase.circle"
        case .family:
            return "house.circle"
        case .friend:
            return "heart.circle"
        case .other:
            return "ellipsis.circle"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case .personal:
            return .blue
        case .business:
            return .purple
        case .family:
            return .green
        case .friend:
            return .pink
        case .other:
            return .orange
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(categoryColor.opacity(0.5))
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.secondaryTextColor)
                
                Text("Нет долгов")
                    .font(.system(size: 12))
                    .foregroundColor(themeManager.secondaryTextColor.opacity(0.7))
            }
            
            Spacer()
            
            Text("0 ₽")
                .font(.system(size: 14))
                .foregroundColor(themeManager.secondaryTextColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(categoryColor.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(categoryColor.opacity(0.1), lineWidth: 1)
                )
        )
        .opacity(0.6)
    }
}

struct RecentActivityView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    
    private var recentDebts: [Debt] {
        debtStore.debts
            .sorted { $0.dateCreated > $1.dateCreated }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Недавняя активность")
                .font(.headline)
                .foregroundColor(themeManager.primaryTextColor)
            
            if recentDebts.isEmpty {
                Text("Нет недавней активности")
                    .font(.subheadline)
                    .foregroundColor(themeManager.secondaryTextColor)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(recentDebts) { debt in
                        RecentActivityRow(debt: debt)
                    }
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

struct RecentActivityRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    let debt: Debt
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(debt.debtorName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.primaryTextColor)
                
                Text(debt.dateCreated, formatter: recentDateFormatter)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.secondaryTextColor)
            }
            
            Spacer()
            
            HStack {
                if debt.isPaid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                
                Text(debt.formattedAmount)
                    .font(.system(size: 16))
                    .foregroundColor(debt.isPaid ? .green : themeManager.primaryTextColor)
            }
        }
        .padding(.vertical, 4)
    }
}

struct OverdueDebtsView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Просроченные долги")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                ForEach(debtStore.overdueDebts) { debt in
                    OverdueDebtRow(debt: debt)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.overdueCardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.overdueCardBorder, lineWidth: 1)
        )
    }
}

struct OverdueDebtRow: View {
    let debt: Debt
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(debt.debtorName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.primaryTextColor)
                
                if let dueDate = debt.dueDate {
                    Text("Просрочен с \(dueDate, formatter: dateFormatter)")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(debt.formattedAmount)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                
                Button("Погасить") {
                    withAnimation {
                        debtStore.markAsPaid(debt)
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ru_RU")
    formatter.dateStyle = .medium
    return formatter
}()

private let recentDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ru_RU")
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

private let shortDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "ru_RU")
    formatter.dateStyle = .short
    return formatter
}()

// Helper functions for category icons and colors
private func categoryIcon(for category: Debt.DebtCategory) -> String {
    switch category {
    case .personal:
        return "person.circle.fill"
    case .business:
        return "briefcase.circle.fill"
    case .family:
        return "house.circle.fill"
    case .friend:
        return "heart.circle.fill"
    case .other:
        return "ellipsis.circle.fill"
    }
}

private func categoryColor(for category: Debt.DebtCategory) -> Color {
    switch category {
    case .personal:
        return .blue
    case .business:
        return .purple
    case .family:
        return .green
    case .friend:
        return .pink
    case .other:
        return .orange
    }
}

// MARK: - Number Formatters
extension NumberFormatter {
    static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.currencySymbol = "₽"
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = " "
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    static let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()
}

#Preview {
    StatisticsView()
        .environmentObject(DebtStore())
        .environmentObject(ThemeManager())
}
