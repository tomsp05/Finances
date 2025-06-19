//
//  BudgetExtension.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/17/25.
//


import SwiftUI

// Extension to handle budget-related functionality
extension FinanceViewModel {
    // CRUD operations for budgets
    func addBudget(_ budget: Budget) {
        // When adding a budget, ensure the periodStartDate is set correctly
        var newBudget = budget
        newBudget.periodStartDate = getCurrentPeriodStartDate(for: budget.timePeriod, from: budget.startDate)
        budgets.append(newBudget)
        saveBudgets()
        recalculateBudgetSpending()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            var updatedBudget = budget
            
            // If time period changed, we need to recalculate the period start date
            if updatedBudget.timePeriod != budgets[index].timePeriod {
                updatedBudget.periodStartDate = getCurrentPeriodStartDate(for: updatedBudget.timePeriod, from: Date())
            } else {
                // Keep existing period start date
                updatedBudget.periodStartDate = budgets[index].periodStartDate
            }
            
            budgets[index] = updatedBudget
            saveBudgets()
            recalculateBudgetSpending()
        }
    }
    
    func deleteBudget(_ budget: Budget) {
        budgets.removeAll { $0.id == budget.id }
        saveBudgets()
    }
    
    func saveBudgets() {
        DataService.shared.saveBudgets(budgets)
    }
    
    func loadBudgets() {
        if let loadedBudgets = DataService.shared.loadBudgets() {
            // Ensure all budgets have their periodStartDate set correctly
            var updatedBudgets = loadedBudgets
            var needsUpdate = false
            
            for i in 0..<updatedBudgets.count {
                // Check if we need to update the periodStartDate
                let currentPeriodStart = getCurrentPeriodStartDate(
                    for: updatedBudgets[i].timePeriod,
                    from: updatedBudgets[i].startDate
                )
                
                // If periodStartDate is nil or it's not the current period start
                if updatedBudgets[i].periodStartDate == nil ||
                   (updatedBudgets[i].periodStartDate != nil &&
                   !Calendar.current.isDate(updatedBudgets[i].periodStartDate!, inSameDayAs: currentPeriodStart)) {
                    
                    updatedBudgets[i].periodStartDate = currentPeriodStart
                    needsUpdate = true
                }
            }
            
            budgets = updatedBudgets
            
            if needsUpdate {
                saveBudgets()
            }
            
            recalculateBudgetSpending()
        } else {
            budgets = []
        }
    }
    
    // Check and update the period start date for all budgets
    func checkBudgetPeriods() {
        let currentDate = Date()
        var budgetsUpdated = false
        
        for i in 0..<budgets.count {
            let budget = budgets[i]
            
            // Calculate the current period start date
            let currentPeriodStart = getCurrentPeriodStartDate(for: budget.timePeriod, from: budget.startDate)
            
            // If the period start date is different than what's stored, update it
            if budget.periodStartDate == nil ||
               !Calendar.current.isDate(budget.periodStartDate!, inSameDayAs: currentPeriodStart) {
                
                var updatedBudget = budget
                updatedBudget.periodStartDate = currentPeriodStart
                updatedBudget.currentSpent = 0.0 // Reset spending for the new period
                budgets[i] = updatedBudget
                budgetsUpdated = true
            }
        }
        
        if budgetsUpdated {
            saveBudgets()
            recalculateBudgetSpending() // Recalculate spending for the new periods
        }
    }
    
    // Calculate the start date of the current period for a given time period type
    func getCurrentPeriodStartDate(for timePeriod: TimePeriod, from referenceDate: Date) -> Date {
        let currentDate = Date()
        let calendar = Calendar.current
        
        switch timePeriod {
        case .weekly:
            // Find the start of the current week
            let startOfWeek = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
            return calendar.date(from: startOfWeek) ?? currentDate
            
        case .monthly:
            // Find the start of the current month
            let components = calendar.dateComponents([.year, .month], from: currentDate)
            return calendar.date(from: components) ?? currentDate
            
        case .yearly:
            // Find the start of the current year
            let components = calendar.dateComponents([.year], from: currentDate)
            return calendar.date(from: components) ?? currentDate
        }
    }
    
    // When a new transaction is added, update the relevant budgets
    func updateBudgetsWithTransaction(_ transaction: Transaction) {
        // Only track expenses for budgets
        guard transaction.type == .expense else { return }
        
        // Check and update budget periods before processing the transaction
        checkBudgetPeriods()
        
        let transactionDate = transaction.date
        
        // Update budgets
        for i in 0..<budgets.count {
            var budget = budgets[i]
            
            // Only count transactions that are within the current period
            guard let periodStart = budget.periodStartDate, transactionDate >= periodStart else { continue }
            
            // Check if budget applies to this transaction
            switch budget.type {
            case .overall:
                // All expenses count toward overall budget
                budget.currentSpent += transaction.amount
                budgets[i] = budget
                
            case .category:
                // Only count if transaction matches the budget category
                if let budgetCategoryId = budget.categoryId, budgetCategoryId == transaction.categoryId {
                    budget.currentSpent += transaction.amount
                    budgets[i] = budget
                }
                
            case .account:
                // Only count if transaction is from the budget account
                if let budgetAccountId = budget.accountId,
                   let accountIndex = accounts.firstIndex(where: { $0.id == budgetAccountId }),
                   accounts[accountIndex].type == transaction.fromAccount {
                    budget.currentSpent += transaction.amount
                    budgets[i] = budget
                }
            }
        }
        
        saveBudgets()
    }
    
    // Recalculate all budget spending based on transactions
    func recalculateBudgetSpending() {
        // Check and update budget periods first
        checkBudgetPeriods()
        
        // Reset all budgets' current spent amount
        for i in 0..<budgets.count {
            budgets[i].currentSpent = 0.0
        }
        
        // Get all expense transactions
        let expenseTransactions = transactions.filter { $0.type == .expense }
        
        // For each budget, find matching transactions and sum them
        for i in 0..<budgets.count {
            let budget = budgets[i]
            guard let periodStartDate = budget.periodStartDate else { continue }
            
            // Get transactions that fall within the current budget period
            let relevantTransactions = expenseTransactions.filter { $0.date >= periodStartDate }
            
            var totalSpent: Double = 0.0
            
            for transaction in relevantTransactions {
                let amountToCount = transaction.amount
                
                switch budget.type {
                case .overall:
                    // All expenses count toward overall budget
                    totalSpent += amountToCount
                    
                case .category:
                    // Only count if transaction matches the budget category
                    if let budgetCategoryId = budget.categoryId,
                       budgetCategoryId == transaction.categoryId {
                        totalSpent += amountToCount
                    }
                    
                case .account:
                    // Only count if transaction is from the budget account
                    if let budgetAccountId = budget.accountId,
                       let accountIndex = accounts.firstIndex(where: { $0.id == budgetAccountId }),
                       accounts[accountIndex].type == transaction.fromAccount {
                        totalSpent += amountToCount
                    }
                }
            }
            
            budgets[i].currentSpent = totalSpent
        }
        
        saveBudgets()
    }
}
