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
    
    // User preferences
    @Published var userPreferences: UserPreferences = UserPreferences.defaultPreferences
    
    // Theme color getter from user preferences
    var themeColorName: String {
        get { userPreferences.themeColorName }
        set {
            userPreferences.themeColorName = newValue
            DataService.shared.saveUserPreferences(userPreferences)
            // Also save via the previous method for backward compatibility
            DataService.shared.saveThemeColor(newValue)
        }
    }
    
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
    
    // Add this property to your FinanceViewModel class
    @Published var budgets: [Budget] = []
    
    init() {
        loadUserPreferences()
        loadInitialData()
    }
    
    func loadUserPreferences() {
        if let preferences = DataService.shared.loadUserPreferences() {
            userPreferences = preferences
        } else {
            userPreferences = UserPreferences.defaultPreferences
            
            // Check if legacy theme color exists and migrate it
            if let legacyTheme = DataService.shared.loadThemeColor() {
                userPreferences.themeColorName = legacyTheme
            }
            
            DataService.shared.saveUserPreferences(userPreferences)
        }
    }
    
    func saveUserPreferences() {
        DataService.shared.saveUserPreferences(userPreferences)
    }
    
    func completeOnboarding() {
        userPreferences.hasCompletedOnboarding = true
        saveUserPreferences()
    }
    
    // Update addTransaction method to include budget calculations
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        updateAccounts(with: transaction)
        updateBudgetsWithTransaction(transaction)
        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveAccounts(accounts)
        signalBalanceChange()
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
                Account(name: "Credit Card", type: .credit, initialBalance: 0.0, balance: 0.0),
            ]
        }
        
        loadBudgets()
            
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
        recalculateBudgetSpending()
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
    func signalBalanceChange() {
        // Toggle the signal property to trigger @Published updates
        balanceDidChange.toggle()
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
        userPreferences.themeColorName = newColorName
        saveUserPreferences()
    }
    
    // Format currency using user preferences
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = userPreferences.currencySymbol
        formatter.locale = Locale(identifier: userPreferences.locale)
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(userPreferences.currencySymbol)0.00"
    }
}

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
    
    // Add these methods to your FinanceViewModel class

    func deleteAllTransactions() {
        // Remove all transactions
        transactions = []
        
        // Reset account balances to their initial values
        for i in 0..<accounts.count {
            accounts[i].balance = accounts[i].initialBalance
        }
        
        // Save if you have persistence methods
        // saveData()
    }

    func resetAllData() {
        // Clear all data
        transactions = []
        accounts = []
        
        // Reset theme to default if needed
        themeColorName = "Blue"
        
        // Reset any other state as needed
        
        // Save if you have persistence methods
        // saveData()
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
                switch budget.type {
                case .overall:
                    // All expenses count toward overall budget
                    totalSpent += transaction.amount
                    
                case .category:
                    // Only count if transaction matches the budget category
                    if let budgetCategoryId = budget.categoryId,
                       budgetCategoryId == transaction.categoryId {
                        totalSpent += transaction.amount
                    }
                    
                case .account:
                    // Only count if transaction is from the budget account
                    if let budgetAccountId = budget.accountId,
                       let accountIndex = accounts.firstIndex(where: { $0.id == budgetAccountId }),
                       accounts[accountIndex].type == transaction.fromAccount {
                        totalSpent += transaction.amount
                    }
                }
            }
            
            budgets[i].currentSpent = totalSpent
        }
        
        saveBudgets()
    }
}

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

// Add this extension to FinanceViewModel.swift

extension FinanceViewModel {
    // Generate test data for the app
    func generateTestData() {
        // First, ensure we have categories to use
        if incomeCategories.isEmpty {
            incomeCategories = Category.defaultIncomeCategories
        }
        
        if expenseCategories.isEmpty {
            expenseCategories = Category.defaultExpenseCategories
        }
        
        // Make sure we have accounts
        if accounts.isEmpty {
            accounts = [
                Account(name: "Savings Account", type: .savings, initialBalance: 1500.0, balance: 1500.0),
                Account(name: "Current Account", type: .current, initialBalance: 2000.0, balance: 2000.0),
                Account(name: "Credit Card", type: .credit, initialBalance: 0.0, balance: 0.0)
            ]
        }
        
        // Get current date for reference
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Generate 6 months of data
        var newTransactions: [Transaction] = []
        
        // Get account IDs
        let savingsId = accounts.first(where: { $0.type == .savings })?.id
        let currentId = accounts.first(where: { $0.type == .current })?.id
        let creditId = accounts.first(where: { $0.type == .credit })?.id
        
        // Get category IDs
        let salaryId = incomeCategories.first(where: { $0.name == "Salary" })?.id ?? incomeCategories[0].id
        let loanId = incomeCategories.first(where: { $0.name == "Student Loan" })?.id ?? incomeCategories[0].id
        let giftId = incomeCategories.first(where: { $0.name == "Gift" })?.id ?? incomeCategories[0].id
        
        let foodId = expenseCategories.first(where: { $0.name == "Food" })?.id ?? expenseCategories[0].id
        let transportId = expenseCategories.first(where: { $0.name == "Transport" })?.id ?? expenseCategories[0].id
        let entertainmentId = expenseCategories.first(where: { $0.name == "Entertainment" })?.id ?? expenseCategories[0].id
        let shoppingId = expenseCategories.first(where: { $0.name == "Shopping" })?.id ?? expenseCategories[0].id
        let billsId = expenseCategories.first(where: { $0.name == "Bills" })?.id ?? expenseCategories[0].id
        let housingId = expenseCategories.first(where: { $0.name == "Housing" })?.id ?? expenseCategories[0].id
        
        // Generate monthly income (standard transactions)
        for monthOffset in 0..<6 {
            // Calculate date for this month
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate)!
            
            // Salary - monthly on the 25th
            let salaryDay = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: getDateForDay(25, in: monthDate))!
            let salaryAmount = Double.random(in: 1800...2200)
            newTransactions.append(
                Transaction(
                    date: salaryDay,
                    amount: salaryAmount,
                    description: "Monthly Salary",
                    fromAccount: nil,
                    toAccount: .current,
                    fromAccountId: nil,
                    toAccountId: currentId,
                    type: .income,
                    categoryId: salaryId
                )
            )
            
            // Student loan - quarterly
            if monthOffset % 3 == 0 {
                let loanDay = calendar.date(bySettingHour: 10, minute: 15, second: 0, of: getDateForDay(15, in: monthDate))!
                newTransactions.append(
                    Transaction(
                        date: loanDay,
                        amount: 2500.0,
                        description: "Student Loan Installment",
                        fromAccount: nil,
                        toAccount: .current,
                        fromAccountId: nil,
                        toAccountId: currentId,
                        type: .income,
                        categoryId: loanId
                    )
                )
            }
            
            // Random gift (occasional)
            if Bool.random() && monthOffset < 3 {
                let randomDay = Int.random(in: 1...28)
                let giftDay = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: getDateForDay(randomDay, in: monthDate))!
                let giftAmount = Double.random(in: 20...200)
                newTransactions.append(
                    Transaction(
                        date: giftDay,
                        amount: giftAmount,
                        description: "Gift from family",
                        fromAccount: nil,
                        toAccount: .current,
                        fromAccountId: nil,
                        toAccountId: currentId,
                        type: .income,
                        categoryId: giftId
                    )
                )
            }
            
            // Generate several expenses throughout the month
            for _ in 1...15 {
                let randomDay = Int.random(in: 1...28)
                let expenseDate = calendar.date(bySettingHour: Int.random(in: 8...21),
                                                minute: Int.random(in: 0...59),
                                                second: 0,
                                                of: getDateForDay(randomDay, in: monthDate))!
                
                // Pick a random category and amount
                let categories = [(foodId, "Food", 5.0...50.0),
                                 (transportId, "Transport", 2.0...30.0),
                                 (entertainmentId, "Entertainment", 10.0...100.0),
                                 (shoppingId, "Shopping", 15.0...200.0)]
                
                let randomIndex = Int.random(in: 0..<categories.count)
                let (categoryId, categoryName, amountRange) = categories[randomIndex]
                let amount = Double.random(in: amountRange)
                
                // Randomly pick account to pay from
                let isCredit = Bool.random()
                
                newTransactions.append(
                    Transaction(
                        date: expenseDate,
                        amount: amount,
                        description: "\(categoryName) expense",
                        fromAccount: isCredit ? .credit : .current,
                        toAccount: nil,
                        fromAccountId: isCredit ? creditId : currentId,
                        toAccountId: nil,
                        type: .expense,
                        categoryId: categoryId
                    )
                )
            }
            
            // Monthly bills
            let billDay = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: getDateForDay(1, in: monthDate))!
            newTransactions.append(
                Transaction(
                    date: billDay,
                    amount: Double.random(in: 80...120),
                    description: "Utilities",
                    fromAccount: .current,
                    toAccount: nil,
                    fromAccountId: currentId,
                    toAccountId: nil,
                    type: .expense,
                    categoryId: billsId
                )
            )
            
            // Rent
            let rentDay = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: getDateForDay(1, in: monthDate))!
            newTransactions.append(
                Transaction(
                    date: rentDay,
                    amount: 750.0,
                    description: "Rent",
                    fromAccount: .current,
                    toAccount: nil,
                    fromAccountId: currentId,
                    toAccountId: nil,
                    type: .expense,
                    categoryId: housingId
                )
            )
            
            // Transfer to savings
            let transferDay = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: getDateForDay(26, in: monthDate))!
            newTransactions.append(
                Transaction(
                    date: transferDay,
                    amount: Double.random(in: 200...400),
                    description: "Monthly savings",
                    fromAccount: .current,
                    toAccount: .savings,
                    fromAccountId: currentId,
                    toAccountId: savingsId,
                    type: .transfer,
                    categoryId: expenseCategories[0].id
                )
            )
            
            // Credit card payment
            let ccPayDay = calendar.date(bySettingHour: 15, minute: 30, second: 0, of: getDateForDay(15, in: monthDate))!
            newTransactions.append(
                Transaction(
                    date: ccPayDay,
                    amount: Double.random(in: 200...500),
                    description: "Credit card payment",
                    fromAccount: .current,
                    toAccount: .credit,
                    fromAccountId: currentId,
                    toAccountId: creditId,
                    type: .transfer,
                    categoryId: expenseCategories[0].id
                )
            )
        }
        
        // Add all the transactions
        transactions.append(contentsOf: newTransactions)
        
        // Save changes
        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveCategories(incomeCategories, type: .income)
        DataService.shared.saveCategories(expenseCategories, type: .expense)
        DataService.shared.saveAccounts(accounts)
        
        // Recalculate account balances
        recalcAccounts()
    }
    
    // Helper to get a specific day in a month
    private func getDateForDay(_ day: Int, in date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = min(day, calendar.range(of: .day, in: .month, for: date)?.count ?? 28)
        return calendar.date(from: components) ?? date
    }
}


// Add to FinanceViewModel.swift
extension FinanceViewModel {
    // Export data to a file
    func exportData(format: String) -> URL? {
        var fileURL: URL? = nil
        
        switch format.lowercased() {
        case "csv":
            fileURL = exportToCSV()
        case "json":
            fileURL = exportToJSON()
        default:
            return nil
        }
        
        return fileURL
    }
    
    // Export data to CSV format
    private func exportToCSV() -> URL? {
        let fileName = "finance_export_\(Date().timeIntervalSince1970).csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        var csvText = "ACCOUNTS\n"
        csvText += "ID,Name,Type,Initial Balance,Current Balance\n"
        
        for account in accounts {
            let line = "\(account.id),\"\(account.name)\",\(account.type.rawValue),\(account.initialBalance),\(account.balance)\n"
            csvText += line
        }
        
        csvText += "\nTRANSACTIONS\n"
        csvText += "ID,Date,Amount,Description,From Account,To Account,From Account ID,To Account ID,Type,Category ID,Is Split,Friend Name,Friend Amount,User Amount,Friend Payment Destination,Is Recurring,Recurrence Interval\n"
        
        for transaction in transactions {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: transaction.date)
            
            let line = "\(transaction.id),\(dateString),\(transaction.amount),\"\(transaction.description)\",\(transaction.fromAccount?.rawValue ?? ""),\(transaction.toAccount?.rawValue ?? ""),\(transaction.fromAccountId?.uuidString ?? ""),\(transaction.toAccountId?.uuidString ?? ""),\(transaction.type.rawValue),\(transaction.categoryId),\(transaction.isSplit),\"\(transaction.friendName)\",\(transaction.friendAmount),\(transaction.userAmount),\"\(transaction.friendPaymentDestination)\",\(transaction.isRecurring),\(transaction.recurrenceInterval.rawValue)\n"
            csvText += line
        }
        
        csvText += "\nCATEGORIES\n"
        csvText += "ID,Name,Type,Icon Name\n"
        
        for category in incomeCategories + expenseCategories {
            let line = "\(category.id),\"\(category.name)\",\(category.type.rawValue),\(category.iconName)\n"
            csvText += line
        }
        
        csvText += "\nBUDGETS\n"
        csvText += "ID,Name,Amount,Type,Time Period,Category ID,Account ID,Start Date,Current Spent\n"
        
        for budget in budgets {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: budget.startDate)
            
            let line = "\(budget.id),\"\(budget.name)\",\(budget.amount),\(budget.type.rawValue),\(budget.timePeriod.rawValue),\(budget.categoryId?.uuidString ?? ""),\(budget.accountId?.uuidString ?? ""),\(dateString),\(budget.currentSpent)\n"
            csvText += line
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Error saving CSV file: \(error)")
            return nil
        }
    }
    
    // Export data to JSON format
    private func exportToJSON() -> URL? {
        let fileName = "finance_export_\(Date().timeIntervalSince1970).json"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        // Create a dictionary with all the data
        let exportData: [String: Any] = [
            "accounts": accounts,
            "transactions": transactions,
            "incomeCategories": incomeCategories,
            "expenseCategories": expenseCategories,
            "budgets": budgets,
            "userPreferences": userPreferences
        ]
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // Because our top-level structure isn't directly Codable,
            // we need to encode each component separately and build a JSON string
            var jsonString = "{\n"
            
            // Encode accounts
            if let accountsData = try? encoder.encode(accounts),
               let accountsString = String(data: accountsData, encoding: .utf8) {
                jsonString += "  \"accounts\": \(accountsString),\n"
            }
            
            // Encode transactions
            if let transactionsData = try? encoder.encode(transactions),
               let transactionsString = String(data: transactionsData, encoding: .utf8) {
                jsonString += "  \"transactions\": \(transactionsString),\n"
            }
            
            // Encode income categories
            if let incomeCategoriesData = try? encoder.encode(incomeCategories),
               let incomeCategoriesString = String(data: incomeCategoriesData, encoding: .utf8) {
                jsonString += "  \"incomeCategories\": \(incomeCategoriesString),\n"
            }
            
            // Encode expense categories
            if let expenseCategoriesData = try? encoder.encode(expenseCategories),
               let expenseCategoriesString = String(data: expenseCategoriesData, encoding: .utf8) {
                jsonString += "  \"expenseCategories\": \(expenseCategoriesString),\n"
            }
            
            // Encode budgets
            if let budgetsData = try? encoder.encode(budgets),
               let budgetsString = String(data: budgetsData, encoding: .utf8) {
                jsonString += "  \"budgets\": \(budgetsString),\n"
            }
            
            // Encode user preferences
            if let preferencesData = try? encoder.encode(userPreferences),
               let preferencesString = String(data: preferencesData, encoding: .utf8) {
                jsonString += "  \"userPreferences\": \(preferencesString)\n"
            }
            
            jsonString += "}"
            
            try jsonString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Error saving JSON file: \(error)")
            return nil
        }
    }
}
