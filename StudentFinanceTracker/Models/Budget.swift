//
//  Budget.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/17/25.
//

import Foundation

enum BudgetType: String, Codable, CaseIterable {
    case overall
    case category
    case account
}

struct Budget: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var type: BudgetType
    var timePeriod: TimePeriod
    var categoryId: UUID?    // For category-based budgets
    var accountId: UUID?     // For account-based budgets
    var startDate: Date      // The original creation date of the budget
    var periodStartDate: Date? // The start date of the current period (week, month, year)
    var currentSpent: Double = 0.0
    
    var remainingAmount: Double {
        return max(0, amount - currentSpent)
    }
    
    var percentUsed: Double {
        guard amount > 0 else { return 0 }
        return min(1.0, currentSpent / amount)
    }
    
    // FIXED: Helper method to check if budget is over
    var isOverBudget: Bool {
        return currentSpent > amount
    }
    
    // FIXED: Helper method to get days remaining in current period
    var daysRemainingInPeriod: Int {
        guard let periodStart = periodStartDate else { return 0 }
        
        let nextResetDate = timePeriod.getNextResetDate(from: periodStart)
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: nextResetDate).day ?? 0
        return max(0, days)
    }
}

enum TimePeriod: String, Codable, CaseIterable {
    case weekly
    case monthly
    case yearly
    
    func displayName() -> String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    // FIXED: More accurate next reset date calculation
    func getNextResetDate(from date: Date) -> Date {
        let calendar = Calendar.current
        
        switch self {
        case .weekly:
            // Find the start of next week (Monday)
            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: date) else { return date }
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: nextWeek)
            components.weekday = 2 // Monday
            return calendar.date(from: components) ?? date
            
        case .monthly:
            // Find the start of next month
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: date) else { return date }
            let components = calendar.dateComponents([.year, .month], from: nextMonth)
            return calendar.date(from: components) ?? date
            
        case .yearly:
            // Find the start of next year
            guard let nextYear = calendar.date(byAdding: .year, value: 1, to: date) else { return date }
            let components = calendar.dateComponents([.year], from: nextYear)
            return calendar.date(from: components) ?? date
        }
    }
    
    // FIXED: Helper method to get the duration in days for better UI feedback
    var approximateDaysInPeriod: Int {
        switch self {
        case .weekly: return 7
        case .monthly: return 30
        case .yearly: return 365
        }
    }
}
