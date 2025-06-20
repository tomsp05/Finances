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
        var newBudget = budget
        newBudget.periodStartDate = getCurrentPeriodStartDate(for: budget.timePeriod, from: budget.startDate)
        budgets.append(newBudget)
        saveBudgets()
        recalculateBudgetSpending()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            var updatedBudget = budget
            
            // If time period changed, recalculate the period start date
            if updatedBudget.timePeriod != budgets[index].timePeriod {
                updatedBudget.periodStartDate = getCurrentPeriodStartDate(for: updatedBudget.timePeriod, from: Date())
                updatedBudget.currentSpent = 0.0 // Reset spending when period changes
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
            budgets = loadedBudgets
            // Check for period resets after loading
            checkAndResetBudgetPeriods()
            recalculateBudgetSpending()
        } else {
            budgets = []
        }
    }
    
    // Proper period checking and resetting
    func checkAndResetBudgetPeriods() {
        let currentDate = Date()
        var budgetsUpdated = false
        
        for i in 0..<budgets.count {
            let budget = budgets[i]
            let currentPeriodStart = getCurrentPeriodStartDate(for: budget.timePeriod, from: budget.startDate)
            
            // Check if we need to reset the budget period
            if shouldResetBudgetPeriod(budget: budget, currentPeriodStart: currentPeriodStart) {
                var updatedBudget = budget
                updatedBudget.periodStartDate = currentPeriodStart
                updatedBudget.currentSpent = 0.0 // Reset spending for new period
                budgets[i] = updatedBudget
                budgetsUpdated = true
                
                print("Budget '\(budget.name)' period reset. New period starts: \(currentPeriodStart)")
            }
        }
        
        if budgetsUpdated {
            saveBudgets()
        }
    }
    
    // Better logic for determining if a budget period should reset
    private func shouldResetBudgetPeriod(budget: Budget, currentPeriodStart: Date) -> Bool {
        guard let budgetPeriodStart = budget.periodStartDate else {
            return true // First time setup
        }
        
        let calendar = Calendar.current
        
        switch budget.timePeriod {
        case .weekly:
            // Check if we're in a different week
            let budgetWeek = calendar.component(.weekOfYear, from: budgetPeriodStart)
            let currentWeek = calendar.component(.weekOfYear, from: currentPeriodStart)
            let budgetYear = calendar.component(.yearForWeekOfYear, from: budgetPeriodStart)
            let currentYear = calendar.component(.yearForWeekOfYear, from: currentPeriodStart)
            return budgetWeek != currentWeek || budgetYear != currentYear
            
        case .monthly:
            // Check if we're in a different month
            let budgetMonth = calendar.component(.month, from: budgetPeriodStart)
            let currentMonth = calendar.component(.month, from: currentPeriodStart)
            let budgetYear = calendar.component(.year, from: budgetPeriodStart)
            let currentYear = calendar.component(.year, from: currentPeriodStart)
            return budgetMonth != currentMonth || budgetYear != currentYear
            
        case .yearly:
            // Check if we're in a different year
            let budgetYear = calendar.component(.year, from: budgetPeriodStart)
            let currentYear = calendar.component(.year, from: currentPeriodStart)
            return budgetYear != currentYear
        }
    }
    
    // More accurate period start date calculation
    func getCurrentPeriodStartDate(for timePeriod: TimePeriod, from referenceDate: Date) -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        
        switch timePeriod {
        case .weekly:
            // Get the start of the current week (Monday)
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
            components.weekday = 2 // Monday
            return calendar.date(from: components) ?? currentDate
            
        case .monthly:
            // Get the start of the current month
            let components = calendar.dateComponents([.year, .month], from: currentDate)
            return calendar.date(from: components) ?? currentDate
            
        case .yearly:
            // Get the start of the current year
            let components = calendar.dateComponents([.year], from: currentDate)
            return calendar.date(from: components) ?? currentDate
        }
    }

    // This should be called whenever transactions are modified
    func handleTransactionChange() {
        checkAndResetBudgetPeriods()
        recalculateBudgetSpending()
    }
    
    // More robust budget spending calculation
    func recalculateBudgetSpending() {
        // First check for period resets
        checkAndResetBudgetPeriods()
        
        // Reset all budgets' current spent amount
        for i in 0..<budgets.count {
            budgets[i].currentSpent = 0.0
        }
        
        // Get all expense transactions
        let expenseTransactions = transactions.filter { $0.type == .expense }
        
        // Calculate spending for each budget
        for i in 0..<budgets.count {
            let budget = budgets[i]
            guard let periodStartDate = budget.periodStartDate else { continue }
            
            var totalSpent: Double = 0.0
            
            for transaction in expenseTransactions {
                // Only count transactions within the current budget period
                guard transaction.date >= periodStartDate else { continue }
                
                let shouldCount = shouldTransactionCountForBudget(transaction: transaction, budget: budget)
                if shouldCount {
                    totalSpent += transaction.amount
                }
            }
            
            budgets[i].currentSpent = totalSpent
        }
        
        saveBudgets()
    }
    
    // Cleaner transaction matching logic
    private func shouldTransactionCountForBudget(transaction: Transaction, budget: Budget) -> Bool {
        switch budget.type {
        case .overall:
            return true // All expenses count
            
        case .category:
            guard let budgetCategoryId = budget.categoryId else { return false }
            return budgetCategoryId == transaction.categoryId
            
        case .account:
            guard let budgetAccountId = budget.accountId else { return false }
            guard let account = accounts.first(where: { $0.id == budgetAccountId }) else { return false }
            return account.type == transaction.fromAccount
        }
    }
    
    // Call this method from your transaction add/edit/delete methods
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        DataService.shared.saveTransactions(transactions)
        handleTransactionChange() // This will update budgets
    }
    
    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            transactions[index] = transaction
            DataService.shared.saveTransactions(transactions)
            handleTransactionChange() // This will update budgets
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
        DataService.shared.saveTransactions(transactions)
        handleTransactionChange() // This will update budgets
    }
}
