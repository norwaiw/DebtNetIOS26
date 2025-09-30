import SwiftUI

struct ContentView: View {
    @EnvironmentObject var debtStore: DebtStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content
                Group {
                    switch selectedTab {
                    case 0:
                        DebtListView()
                    case 1:
                        StatisticsView()
                    case 2:
                        SettingsView()
                    default:
                        DebtListView()
                    }
                }
                
                // Custom Bottom Navigation
                HStack {
                    // Debts
                    Button(action: {
                        selectedTab = 0
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == 0 ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                            
                            Text("Долги")
                                .font(.system(size: 12))
                                .foregroundColor(selectedTab == 0 ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Statistics
                    Button(action: {
                        selectedTab = 1
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == 1 ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                            
                            Text("Статистика")
                                .font(.system(size: 12))
                                .foregroundColor(selectedTab == 1 ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Settings
                    Button(action: {
                        selectedTab = 2
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(selectedTab == 2 ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                            
                            Text("Настройки")
                                .font(.system(size: 12))
                                .foregroundColor(selectedTab == 2 ? themeManager.primaryTextColor : themeManager.secondaryTextColor)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(themeManager.navigationBarColor)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(themeManager.borderColor),
                    alignment: .top
                )
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var notificationManager = NotificationManager.shared
    @State private var showingNotificationSettings = false
    
    var body: some View {
        ZStack {
            themeManager.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Настройки")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.primaryTextColor)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Settings Content
                VStack(spacing: 16) {
                    // Theme Toggle Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Тема приложения")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(themeManager.primaryTextColor)
                            
                            Text(themeManager.isDarkMode ? "Темная тема" : "Светлая тема")
                                .font(.system(size: 14))
                                .foregroundColor(themeManager.secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $themeManager.isDarkMode)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(themeManager.isDarkMode ? 
                                  Color(red: 0.15, green: 0.15, blue: 0.15) : 
                                  Color(red: 0.95, green: 0.95, blue: 0.93))
                    )
                    .padding(.horizontal, 20)
                    
                    // Notifications Section
                    Button(action: {
                        showingNotificationSettings = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Уведомления")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(themeManager.primaryTextColor)
                                
                                Text(notificationManager.isNotificationEnabled ? "Включены" : "Отключены")
                                    .font(.system(size: 14))
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Image(systemName: notificationManager.isNotificationEnabled ? "bell.fill" : "bell.slash")
                                    .foregroundColor(notificationManager.isNotificationEnabled ? .green : .gray)
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(themeManager.secondaryTextColor)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(themeManager.isDarkMode ? 
                                      Color(red: 0.15, green: 0.15, blue: 0.15) : 
                                      Color(red: 0.95, green: 0.95, blue: 0.93))
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    Text("Настройки приложения")
                        .foregroundColor(themeManager.secondaryTextColor)
                        .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
                .environmentObject(themeManager)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DebtStore())
        .environmentObject(ThemeManager())
}
