//
//  BudgetType.swift
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
    
    func getNextResetDate(from date: Date) -> Date {
        let calendar = Calendar.current
        switch self {
        case .weekly:
            var components = DateComponents()
            components.weekOfYear = 1
            return calendar.date(byAdding: components, to: date) ?? date
        case .monthly:
            var components = DateComponents()
            components.month = 1
            return calendar.date(byAdding: components, to: date) ?? date
        case .yearly:
            var components = DateComponents()
            components.year = 1
            return calendar.date(byAdding: components, to: date) ?? date
        }
    }
}
