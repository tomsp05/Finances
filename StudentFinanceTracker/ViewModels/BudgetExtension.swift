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
        budgets.append(budget)
        saveBudgets()
        recalculateBudgetSpending()
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets()
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
        } else {
            budgets = []
        }
    }
    
    // When a new transaction is added, update the relevant budgets
    func updateBudgetsWithTransaction(_ transaction: Transaction) {
        // Only track expenses for budgets
        guard transaction.type == .expense else { return }
        
        let transactionDate = transaction.date
        
        // Update overall budgets
        for i in 0..<budgets.count {
            var budget = budgets[i]
            
            // Skip if the transaction date is before the budget start date
            guard transactionDate >= budget.startDate else { continue }
            
            // For split transactions, only count the user's portion (transaction.amount)
            // which is already properly set when the transaction is created
            
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
        // Reset all budgets' current spent amount
        for i in 0..<budgets.count {
            budgets[i].currentSpent = 0.0
        }
        
        // Get all expense transactions
        let expenseTransactions = transactions.filter { $0.type == .expense }
        
        // For each budget, find matching transactions and sum them
        for i in 0..<budgets.count {
            let budget = budgets[i]
            
            // Get transactions that fall within this budget's time period
            let relevantTransactions = expenseTransactions.filter { $0.date >= budget.startDate }
            
            var totalSpent: Double = 0.0
            
            for transaction in relevantTransactions {
                // For each transaction, add the proper amount to the budget
                // For split transactions, use only the user's portion
                // For regular transactions, the amount already represents the full expense
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
