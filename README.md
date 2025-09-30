# DebtNet - Debt Tracking App

## Overview
DebtNet is a SwiftUI-based iOS app for tracking personal debts. The app has been redesigned with a dark theme and enhanced functionality to match the design shown in Image 2.

## Key Features

### ✨ Dark Theme Design
- Complete dark theme with black background and gray accents
- Modern card-based layout
- Red accent colors for primary actions

### 💰 Debt Types
- **"Мне должны"** (They owe me) - Green indicators for money owed to you
- **"Я должен"** (I owe) - Red indicators for money you owe

### 📊 Smart Dashboard
- Summary cards showing total amounts for each debt type
- Filter buttons: "Все" (All), "Мне должны" (Owed to me), "Я должен" (I owe)
- Transaction history with visual indicators
- **Tap on any debt item to view detailed information**

### 🎯 Key Screens

#### Debt History (Main Screen)
- Header with app title and add button (+)
- Filter toggles for debt types
- Summary cards with green/red amounts
- Transaction list with icons and amounts
- Bottom navigation (Debts, Statistics, Settings)

#### Add Debt
- Dark-themed form with modern styling
- Debt type selection (owed to me / I owe)
- Amount, description, and category inputs
- Due date selection

#### Debt Details
- **New screen** showing comprehensive debt information
- Large amount display with debt type indicator
- Complete debt information (debtor, description, category)
- Creation date and due date (with overdue warnings)
- Actions: Mark as paid/unpaid, delete debt
- Back navigation to return to main list

#### Statistics
- Overview of debt breakdown
- Category-based analytics
- Recent activity tracking
- Overdue debt alerts

## Technical Implementation

### Data Model
```swift
struct Debt {
    // ... existing properties ...
    var type: DebtType  // New property for debt direction
    
    enum DebtType {
        case owedToMe    // Money owed to me
        case iOwe        // Money I owe
    }
}
```

### Architecture
- SwiftUI with MVVM pattern
- `@EnvironmentObject` for state management
- UserDefaults for persistence
- Dark theme throughout the app

### UI Components
- Custom dark text field styles
- Gradient cards for summaries
- Icon-based transaction indicators
- Custom bottom navigation

## Color Scheme
- **Background**: Black (#000000)
- **Cards**: Gray with opacity (10%)
- **Positive amounts**: Green
- **Negative amounts**: Red
- **Accent**: Blue for selections
- **Text**: White and gray variants

## Sample Data
The app includes sample data on first launch:
- Ivan Petrov: 5,000₽ (owed to me)
- Maria Sidorova: 15,000₽ (I owe)
- Alexey Kozlov: 3,000₽ (owed to me)

## Navigation
Bottom navigation with three tabs:
1. **Debts** - Main debt tracking interface
2. **Statistics** - Analytics and reporting
3. **Settings** - App configuration