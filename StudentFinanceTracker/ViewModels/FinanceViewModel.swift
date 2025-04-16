import Foundation
import Combine
import SwiftUI

class FinanceViewModel: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var transactions: [Transaction] = []
    @Published var incomeCategories: [Category] = []
    @Published var expenseCategories: [Category] = []
    @Published var incomes: [IncomeSource] = []
    
    // Add a signal property that changes whenever balance changes
    @Published var balanceDidChange: Bool = false
    
    // New theme color stored as a name (string). Default is "Blue".
    @Published var themeColorName: String = "Blue"
    
    /// Returns a SwiftUI Color based on the selected theme color name.
    var themeColor: Color {
        switch themeColorName {
        case "Blue":
             return Color(red: 0.20, green: 0.40, blue: 0.70) // Darker Blue
        case "Green":
             return Color(red: 0.20, green: 0.55, blue: 0.30) // Darker Green
        case "Orange":
             return Color(red: 0.80, green: 0.40, blue: 0.20) // Darker Orange
        case "Purple":
             return Color(red: 0.50, green: 0.25, blue: 0.70) // Darker Purple
        case "Red":
             return Color(red: 0.70, green: 0.20, blue: 0.20) // Darker Red
        case "Teal":
             return Color(red: 0.20, green: 0.50, blue: 0.60) // Darker Teal
        default:
             return Color(red: 0.20, green: 0.40, blue: 0.70) // Default to Blue
        }
    }
    
    init() {
        loadInitialData()
    }
    
    func loadInitialData() {
            // Load accounts
            if let loadedAccounts = DataService.shared.loadAccounts() {
                // Handle migration from old account types if needed
                accounts = migrateOldAccountTypes(loadedAccounts)
            } else {
                accounts = [
                    Account(name: "Savings Account", type: .savings, initialBalance: 0.0, balance: 0.0),
                    Account(name: "Current Account", type: .current, initialBalance: 0.0, balance: 0.0),
                    Account(name: "Amex Credit Card", type: .credit, initialBalance: 0.0, balance: 0.0),
                    Account(name: "HSBC Credit Card", type: .credit, initialBalance: 0.0, balance: 0.0)
                ]
            }
            
            // Load categories
            if let loadedIncomeCategories = DataService.shared.loadCategories(type: .income) {
                incomeCategories = loadedIncomeCategories
            } else {
                incomeCategories = Category.defaultIncomeCategories
            }
            
            if let loadedExpenseCategories = DataService.shared.loadCategories(type: .expense) {
                expenseCategories = loadedExpenseCategories
            } else {
                expenseCategories = Category.defaultExpenseCategories
            }
            
            // Load transactions
            if let loadedTransactions = DataService.shared.loadTransactions() {
                // Migrate old transactions to use new account types
                transactions = migrateOldTransactionAccountTypes(loadedTransactions)
                
                // For backward compatibility: If there are any transactions with the old category format,
                // assign them to a default category
                migrateOldTransactions()
            } else {
                transactions = []
            }
            
            // Load theme color; default to "Blue" if none exists.
            if let loadedTheme = DataService.shared.loadThemeColor() {
                themeColorName = loadedTheme
            } else {
                themeColorName = "Blue"
            }
            
            // Recalculate account balances with existing transactions.
            recalcAccounts()
        }
        
        // Helper method to migrate old account types to new ones
        private func migrateOldAccountTypes(_ oldAccounts: [Account]) -> [Account] {
            return oldAccounts.map { account in
                var newAccount = account
                
                // Check if the type information is using the old enum values
                // This relies on the raw string value stored in the JSON
                if let rawValue = account.type.rawValue as String?,
                   rawValue == "creditAmex" || rawValue == "credit_amex" {
                    // Create a new account with the updated type
                    newAccount = Account(
                        id: account.id,
                        name: "Amex Credit Card",
                        type: .credit,
                        initialBalance: account.initialBalance,
                        balance: account.balance
                    )
                } else if let rawValue = account.type.rawValue as String?,
                          rawValue == "creditHSBC" || rawValue == "credit_hsbc" {
                    // Create a new account with the updated type
                    newAccount = Account(
                        id: account.id,
                        name: "HSBC Credit Card",
                        type: .credit,
                        initialBalance: account.initialBalance,
                        balance: account.balance
                    )
                }
                
                return newAccount
            }
        }
        
        // Helper method to migrate transactions with old account types
        private func migrateOldTransactionAccountTypes(_ oldTransactions: [Transaction]) -> [Transaction] {
            return oldTransactions.map { transaction in
                var newTransaction = transaction
                
                // Update fromAccount if it uses old credit card types
                if let fromAccount = transaction.fromAccount {
                    let fromRawValue = String(describing: fromAccount)
                    if fromRawValue == "creditAmex" || fromRawValue == "credit_amex" ||
                       fromRawValue == "creditHSBC" || fromRawValue == "credit_hsbc" {
                        newTransaction.fromAccount = .credit
                    }
                }
                
                // Update toAccount if it uses old credit card types
                if let toAccount = transaction.toAccount {
                    let toRawValue = String(describing: toAccount)
                    if toRawValue == "creditAmex" || toRawValue == "credit_amex" ||
                       toRawValue == "creditHSBC" || toRawValue == "credit_hsbc" {
                        newTransaction.toAccount = .credit
                    }
                }
                
                return newTransaction
            }
        }
    
    // Helper to migrate old transaction data
    private func migrateOldTransactions() {
        for i in 0..<transactions.count {
            let transaction = transactions[i]
            
            // Check if we need to migrate this transaction
            if transaction.categoryId == UUID() {
                let defaultCategoryId: UUID
                
                if transaction.type == .income {
                    defaultCategoryId = incomeCategories.first { $0.name == "Other" }?.id ?? incomeCategories[0].id
                } else {
                    defaultCategoryId = expenseCategories.first { $0.name == "Other" }?.id ?? expenseCategories[0].id
                }
                
                transactions[i].categoryId = defaultCategoryId
            }
        }
    }
    
    // Get a category by its ID
    func getCategory(id: UUID) -> Category? {
        if let category = incomeCategories.first(where: { $0.id == id }) {
            return category
        }
        return expenseCategories.first(where: { $0.id == id })
    }
    
    // Get appropriate categories based on transaction type
    func getCategoriesForTransactionType(_ type: TransactionType) -> [Category] {
        if type == .income {
            return incomeCategories
        } else if type == .expense {
            return expenseCategories
        } else {
            // For transfers, return a mix or just expense categories
            return expenseCategories
        }
    }
    
    // CRUD operations for categories
    func addCategory(_ category: Category) {
        if category.type == .income {
            incomeCategories.append(category)
            DataService.shared.saveCategories(incomeCategories, type: .income)
        } else {
            expenseCategories.append(category)
            DataService.shared.saveCategories(expenseCategories, type: .expense)
        }
    }
    
    func updateCategory(_ category: Category) {
        if category.type == .income {
            if let index = incomeCategories.firstIndex(where: { $0.id == category.id }) {
                incomeCategories[index] = category
                DataService.shared.saveCategories(incomeCategories, type: .income)
            }
        } else {
            if let index = expenseCategories.firstIndex(where: { $0.id == category.id }) {
                expenseCategories[index] = category
                DataService.shared.saveCategories(expenseCategories, type: .expense)
            }
        }
    }
    
    func deleteCategory(_ category: Category) {
        if category.type == .income {
            incomeCategories.removeAll { $0.id == category.id }
            DataService.shared.saveCategories(incomeCategories, type: .income)
        } else {
            expenseCategories.removeAll { $0.id == category.id }
            DataService.shared.saveCategories(expenseCategories, type: .expense)
        }
    }
    
    // MARK: - Added signalBalanceChange method
    
    /// Signals that a balance change has occurred to trigger animations
    private func signalBalanceChange() {
        // Toggle the signal property to trigger @Published updates
        balanceDidChange.toggle()
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        updateAccounts(with: transaction)
        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveAccounts(accounts)
        signalBalanceChange()
    }
    
    // MARK: - Editing / Deleting Transactions
    
    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        recalcAccounts()
        DataService.shared.saveTransactions(transactions)
        signalBalanceChange()
    }
    
    func updateTransaction(_ updatedTransaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            transactions[index] = updatedTransaction
            recalcAccounts()
            DataService.shared.saveTransactions(transactions)
            signalBalanceChange()
        }
    }
    
    // Replace the existing recalcAccounts method with this updated version:

    /// Resets each account's balance to its preset initialBalance and then applies all transactions.
    func recalcAccounts() {
        for i in accounts.indices {
            accounts[i].balance = accounts[i].initialBalance
        }
        for transaction in transactions {
            apply(transaction)
        }
        DataService.shared.saveAccounts(accounts)
        
        // Always signal the balance change regardless of whether the balance actually changed
        signalBalanceChange()
    }
    
    private func apply(_ transaction: Transaction) {
        switch transaction.type {
        case .income:
            if let to = transaction.toAccount,
               let toId = transaction.toAccountId,
               let index = accounts.firstIndex(where: { $0.id == toId || ($0.type == to && toId == nil) }) {
                accounts[index].balance += transaction.amount
            }
        case .expense:
            if let from = transaction.fromAccount,
               let fromId = transaction.fromAccountId,
               let index = accounts.firstIndex(where: { $0.id == fromId || ($0.type == from && fromId == nil) }) {
                if from == .credit {
                    // For credit cards, the full amount (including friend's portion) increases the balance
                    accounts[index].balance += transaction.isSplit ? transaction.totalAmount : transaction.amount
                } else {
                    // For other accounts, only deduct the user's portion
                    accounts[index].balance -= transaction.amount
                }
            }
            
            // Handle friend's payment destination if it went to one of user's accounts
            if transaction.isSplit && transaction.friendPaymentIsAccount,
               let destAccountId = transaction.friendPaymentAccountId,
               let destIndex = accounts.firstIndex(where: { $0.id == destAccountId }) {
                // Credit the destination account with the friend's portion
                accounts[destIndex].balance += transaction.friendAmount
            }
        case .transfer:
            if let from = transaction.fromAccount,
               let to = transaction.toAccount,
               let fromId = transaction.fromAccountId,
               let toId = transaction.toAccountId,
               let fromIndex = accounts.firstIndex(where: { $0.id == fromId || ($0.type == from && fromId == nil) }),
               let toIndex = accounts.firstIndex(where: { $0.id == toId || ($0.type == to && toId == nil) }) {
                accounts[fromIndex].balance -= transaction.amount
                if to == .credit {
                    accounts[toIndex].balance -= transaction.amount // Paying off credit card
                } else {
                    accounts[toIndex].balance += transaction.amount // Adding to other accounts
                }
            }
        }
    }

    private func updateAccounts(with transaction: Transaction) {
        switch transaction.type {
        case .income:
            if let to = transaction.toAccount,
               let toId = transaction.toAccountId,
               let index = accounts.firstIndex(where: { $0.id == toId || ($0.type == to && toId == nil) }) {
                accounts[index].balance += transaction.amount
            }
        case .expense:
            if let from = transaction.fromAccount,
               let fromId = transaction.fromAccountId,
               let index = accounts.firstIndex(where: { $0.id == fromId || ($0.type == from && fromId == nil) }) {
                if from == .credit {
                    // For credit cards, the full amount (including friend's portion) increases the balance
                    accounts[index].balance += transaction.isSplit ? transaction.totalAmount : transaction.amount
                } else {
                    // For other accounts, only deduct the user's portion
                    accounts[index].balance -= transaction.amount
                }
            }
            
            // Handle friend's payment destination if it went to one of user's accounts
            if transaction.isSplit && transaction.friendPaymentIsAccount,
               let destAccountId = transaction.friendPaymentAccountId,
               let destIndex = accounts.firstIndex(where: { $0.id == destAccountId }) {
                // Credit the destination account with the friend's portion
                accounts[destIndex].balance += transaction.friendAmount
            }
        case .transfer:
            if let from = transaction.fromAccount,
               let to = transaction.toAccount,
               let fromId = transaction.fromAccountId,
               let toId = transaction.toAccountId,
               let fromIndex = accounts.firstIndex(where: { $0.id == fromId || ($0.type == from && fromId == nil) }),
               let toIndex = accounts.firstIndex(where: { $0.id == toId || ($0.type == to && toId == nil) }) {
                accounts[fromIndex].balance -= transaction.amount
                if to == .credit {
                    accounts[toIndex].balance -= transaction.amount // Paying off credit card
                } else {
                    accounts[toIndex].balance += transaction.amount // Adding to other accounts
                }
            }
        }
    }
    
    // MARK: - Settings updates
    
    func updateAccountsSettings(updatedAccounts: [Account]) {
        accounts = updatedAccounts
        DataService.shared.saveAccounts(accounts)
        recalcAccounts()
    }
    
    /// Updates the theme color (by its name) and persists the change.
    func updateThemeColor(newColorName: String) {
        themeColorName = newColorName
        DataService.shared.saveThemeColor(newColorName)
    }
}

import Foundation
import SwiftUI

extension FinanceViewModel {
    
    // Helper to determine if a transaction is in the future
    func isFutureTransaction(_ transaction: Transaction) -> Bool {
        let currentDate = Calendar.current.startOfDay(for: Date())
        return Calendar.current.startOfDay(for: transaction.date) > currentDate
    }
    
    // Returns all transactions that are scheduled for the future (date > current date)
    var futureTransactions: [Transaction] {
        let currentDate = Calendar.current.startOfDay(for: Date())
        return transactions.filter { Calendar.current.startOfDay(for: $0.date) > currentDate }
    }
    
    // Returns all recurring transactions
    var recurringTransactions: [Transaction] {
        return transactions.filter { $0.isRecurring }
    }
    
    // Generate recurring transactions based on a parent transaction
    func generateRecurringTransactions(from transaction: Transaction, upToDate: Date = Date().addingTimeInterval(60*60*24*365)) {
        guard transaction.isRecurring, transaction.recurrenceInterval != .none else { return }
        
        // Define the end date (either the recurrence end date or our default maximum)
        let endDate = transaction.recurrenceEndDate ?? upToDate
        
        // Start from the original transaction date
        var currentDate = transaction.date
        
        // Generate recurring transactions
        while currentDate <= endDate {
            // Calculate the next occurrence date based on recurrence interval
            if let nextDate = calculateNextRecurrenceDate(from: currentDate, interval: transaction.recurrenceInterval) {
                // Don't create if we've reached the end date
                if nextDate > endDate { break }
                
                // Create a new transaction instance
                var newTransaction = transaction
                newTransaction.id = UUID() // New ID for this instance
                newTransaction.date = nextDate
                newTransaction.parentTransactionId = transaction.id
                newTransaction.isFutureTransaction = true
                
                // Add the new transaction
                transactions.append(newTransaction)
                
                // Move to the next date
                currentDate = nextDate
            } else {
                break
            }
        }
        
        // Save transactions after generating all instances
        DataService.shared.saveTransactions(transactions)
    }
    
    // Calculate the next date based on recurrence interval
    private func calculateNextRecurrenceDate(from date: Date, interval: RecurrenceInterval) -> Date? {
        let calendar = Calendar.current
        
        switch interval {
        case .none:
            return nil
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }
    
    // Update a recurring transaction and all its future instances
    func updateRecurringTransaction(_ updatedTransaction: Transaction) {
        // First update the parent transaction
        if let index = transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            transactions[index] = updatedTransaction
            
            // Then update all child transactions
            let childTransactions = transactions.filter { $0.parentTransactionId == updatedTransaction.id }
            for child in childTransactions {
                if let childIndex = transactions.firstIndex(where: { $0.id == child.id }) {
                    var updatedChild = updatedTransaction
                    updatedChild.id = child.id
                    updatedChild.date = child.date
                    updatedChild.parentTransactionId = updatedTransaction.id
                    transactions[childIndex] = updatedChild
                }
            }
        }
        
        // Recalculate account balances and save
        recalcAccounts()
        DataService.shared.saveTransactions(transactions)
    }
    
    // Delete a recurring transaction and optionally all its future instances
    func deleteRecurringTransaction(_ transaction: Transaction, deleteAllFutureInstances: Bool = false) {
        // If this is a recurring transaction and we want to delete all future instances
        if transaction.isRecurring && transaction.parentTransactionId == nil && deleteAllFutureInstances {
            // Remove this transaction
            transactions.removeAll { $0.id == transaction.id }
            
            // Remove all child transactions
            transactions.removeAll { $0.parentTransactionId == transaction.id }
        } else {
            // Just remove this single transaction
            transactions.removeAll { $0.id == transaction.id }
        }
        
        // Update account balances and save
        recalcAccounts()
        DataService.shared.saveTransactions(transactions)
        signalBalanceChange()
    }
}
