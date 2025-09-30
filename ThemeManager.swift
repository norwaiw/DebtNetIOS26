import SwiftUI
import Foundation

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    init() {
        self.isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
    }
    
    var backgroundColor: Color {
        isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.98, green: 0.98, blue: 0.96)
    }
    
    var primaryTextColor: Color {
        isDarkMode ? .white : .black
    }
    
    var secondaryTextColor: Color {
        isDarkMode ? .gray : Color(red: 0.6, green: 0.6, blue: 0.6)
    }
    
    var navigationBarColor: Color {
        isDarkMode ? Color(red: 0.1, green: 0.1, blue: 0.1) : Color(red: 0.98, green: 0.98, blue: 0.96)
    }
    
    // Новые цвета для карточек и элементов интерфейса
    var cardBackgroundColor: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color.white
    }
    
    var cardSecondaryBackgroundColor: Color {
        isDarkMode ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color(red: 0.95, green: 0.95, blue: 0.93)
    }
    
    var textFieldBackgroundColor: Color {
        isDarkMode ? Color.gray.opacity(0.2) : Color(red: 0.95, green: 0.95, blue: 0.95)
    }
    
    var shadowColor: Color {
        isDarkMode ? Color.clear : Color.black.opacity(0.1)
    }
    
    var borderColor: Color {
        isDarkMode ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
    }
    
    // Цвета для статистических карточек
    var owedToMeCardBackground: Color {
        isDarkMode ? Color.green.opacity(0.15) : Color.green.opacity(0.1)
    }
    
    var iOweCardBackground: Color {
        isDarkMode ? Color.red.opacity(0.15) : Color.red.opacity(0.1)
    }
    
    var overdueCardBackground: Color {
        isDarkMode ? Color.red.opacity(0.1) : Color.red.opacity(0.05)
    }
    
    var overdueCardBorder: Color {
        isDarkMode ? Color.red.opacity(0.3) : Color.red.opacity(0.2)
    }
    
    // Цвета для кнопок и интерактивных элементов
    var buttonTextColor: Color {
        isDarkMode ? .white : .black
    }
    
    var disabledButtonColor: Color {
        isDarkMode ? .gray.opacity(0.5) : .gray.opacity(0.3)
    }
    
    var accentColor: Color {
        isDarkMode ? .blue.opacity(0.8) : .blue
    }
    
    var successColor: Color {
        isDarkMode ? .green.opacity(0.8) : .green
    }
    
    var destructiveColor: Color {
        isDarkMode ? .red.opacity(0.8) : .red
    }
    
    var warningColor: Color {
        isDarkMode ? .orange.opacity(0.8) : .orange
    }
    
    // Цвета для разделителей и границ
    var separatorColor: Color {
        isDarkMode ? .gray.opacity(0.2) : .gray.opacity(0.15)
    }
    
    // Цвета для системных элементов
    var systemGrayColor: Color {
        isDarkMode ? Color(.systemGray) : Color(.systemGray2)
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
    }
}