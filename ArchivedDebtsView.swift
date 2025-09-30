import SwiftUI

struct ArchivedDebtsView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    
    private var archivedDebts: [Debt] {
        debtStore.paidDebts.sorted { $0.dateCreated > $1.dateCreated }
    }
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            if archivedDebts.isEmpty {
                Text("Нет погашенных долгов")
                    .foregroundColor(themeManager.secondaryTextColor)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(archivedDebts) { debt in
                            ArchivedDebtRowView(debt: debt)
                                .environmentObject(themeManager)
                                .environmentObject(debtStore)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("Архив")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ArchivedDebtsView()
        .environmentObject(DebtStore())
        .environmentObject(ThemeManager())
}