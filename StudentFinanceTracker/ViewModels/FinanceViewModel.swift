import Foundation
import Combine
import SwiftUI
import WidgetKit

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
    let defaults = UserDefaults(suiteName: "group.com.TomSpeake.StudentFinanceTracker")
    
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
    
    func loadInitialData() {
        // Load accounts
        if let loadedAccounts = DataService.shared.loadAccounts() {
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
            transactions = migrateOldTransactionAccountTypes(loadedTransactions)
            migrateOldTransactions()
        } else {
            transactions = []
        }
        
        // Load theme color
        if let loadedTheme = DataService.shared.loadThemeColor() {
            themeColorName = loadedTheme
        } else {
            themeColorName = "Blue"
        }
        
        // Recalculate balances and spending
        recalcAccounts()
        handleTransactionChange()
    }
    
    // Helper method to migrate old account types to new ones
    private func migrateOldAccountTypes(_ oldAccounts: [Account]) -> [Account] {
        return oldAccounts.map { account in
            var newAccount = account
            
            if let rawValue = account.type.rawValue as String?,
               rawValue == "creditAmex" || rawValue == "credit_amex" {
                newAccount = Account(
                    id: account.id,
                    name: "Amex Credit Card",
                    type: .credit,
                    initialBalance: account.initialBalance,
                    balance: account.balance
                )
            } else if let rawValue = account.type.rawValue as String?,
                      rawValue == "creditHSBC" || rawValue == "credit_hsbc" {
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
            
            if let fromAccount = transaction.fromAccount {
                let fromRawValue = String(describing: fromAccount)
                if fromRawValue == "creditAmex" || fromRawValue == "credit_amex" ||
                    fromRawValue == "creditHSBC" || fromRawValue == "credit_hsbc" {
                    newTransaction.fromAccount = .credit
                }
            }
            
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
            return expenseCategories
        }
    }
    
    // MARK: - Widget Data Update
    
    func updateWidgetData() {
        let userDefaults = UserDefaults(suiteName: "group.com.TomSpeake.StudentFinanceTracker")
        
        // Correctly calculate net balance
        let currentAccountsTotal = accounts.filter { $0.type == .current }.reduce(0) { $0 + $1.balance }
        let creditCardsTotal = accounts.filter { $0.type == .credit }.reduce(0) { $0 + $1.balance }
        let netBalance = currentAccountsTotal - creditCardsTotal

        // Get the 3 most recent transactions
        let recentTransactions = Array(transactions.sorted { $0.date > $1.date }.prefix(3))
        
        let widgetData = WidgetData(netBalance: netBalance, transactions: recentTransactions)
        
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(widgetData) {
            userDefaults?.set(data, forKey: "widgetData")
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("Failed to encode widget data.")
        }
    }
    
    // MARK: - Category CRUD
    
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
    
    // MARK: - Balance and Transaction Management

    func signalBalanceChange() {
        balanceDidChange.toggle()
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
        updateAccounts(with: transaction)
        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveAccounts(accounts)
        signalBalanceChange()
        handleTransactionChange()
        updateWidgetData() // Update widget
    }
    
    func updateTransaction(_ updatedTransaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            transactions[index] = updatedTransaction
            recalcAccounts()
            DataService.shared.saveTransactions(transactions)
            signalBalanceChange()
            handleTransactionChange()
            updateWidgetData() // Update widget
        }
    }
    
    func deleteTransaction(at offsets: IndexSet) {
        transactions.remove(atOffsets: offsets)
        recalcAccounts()
        DataService.shared.saveTransactions(transactions)
        signalBalanceChange()
        handleTransactionChange()
        updateWidgetData() // Update widget
    }
    
    func recalcAccounts() {
        let oldBalances = accounts.map { $0.balance }
        
        for i in accounts.indices {
            accounts[i].balance = accounts[i].initialBalance
        }
        
        for transaction in transactions {
            apply(transaction)
        }
        
        for i in accounts.indices {
            if i < oldBalances.count && accounts[i].balance != oldBalances[i] {
                adjustPoolsAfterBalanceChange(oldBalance: oldBalances[i], newBalance: accounts[i].balance, accountIndex: i)
            }
        }
        
        DataService.shared.saveAccounts(accounts)
        updateWidgetData() // Update widget whenever balances are recalculated
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
                    accounts[index].balance += transaction.isSplit ? transaction.amount : transaction.amount
                } else {
                    accounts[index].balance -= transaction.amount
                }
            }
            
            // This logic appears to have a bug in the original file, amount might be incorrect. Preserving original logic.
            if transaction.isSplit, //&& transaction.friendPaymentIsAccount,
               let destAccountId = transaction.toAccountId, // Assuming friend's payment goes to an account
               let destIndex = accounts.firstIndex(where: { $0.id == destAccountId }) {
                accounts[destIndex].balance += transaction.amount // This might be friendAmount
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
                    accounts[toIndex].balance -= transaction.amount
                } else {
                    accounts[toIndex].balance += transaction.amount
                }
            }
        }
    }
    
    private func adjustPoolsAfterBalanceChange(oldBalance: Double, newBalance: Double, accountIndex: Int) {
        if oldBalance == newBalance || accounts[accountIndex].pools.isEmpty {
            return
        }
        
        if newBalance < oldBalance {
            let allocatedAmount = accounts[accountIndex].pools.reduce(0.0) { $0 + $1.amount }
            
            if allocatedAmount > newBalance {
                let ratio = newBalance / allocatedAmount
                for i in 0..<accounts[accountIndex].pools.count {
                    accounts[accountIndex].pools[i].amount *= ratio
                }
            }
        }
    }
    
    private func updateAccounts(with transaction: Transaction) {
        // This logic is now handled by recalcAccounts to ensure consistency
        recalcAccounts()
    }
    
    // MARK: - Settings and Data Management
    
    func updateAccountsSettings(updatedAccounts: [Account]) {
        accounts = updatedAccounts
        DataService.shared.saveAccounts(accounts)
        recalcAccounts()
    }
    
    func updateThemeColor(newColorName: String) {
        themeColorName = newColorName
        DataService.shared.saveThemeColor(newColorName)
        userPreferences.themeColorName = newColorName
        saveUserPreferences()
    }
    
    func deleteAllTransactions() {
        transactions = []
        recalcAccounts()
        handleTransactionChange()
        DataService.shared.saveTransactions(transactions)
    }

    func resetAllData() {
        transactions = []
        accounts = []
        budgets = []
        incomeCategories = Category.defaultIncomeCategories
        expenseCategories = Category.defaultExpenseCategories
        userPreferences = UserPreferences.defaultPreferences
        
        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveAccounts(accounts)
        DataService.shared.saveBudgets(budgets)
        DataService.shared.saveCategories(incomeCategories, type: .income)
        DataService.shared.saveCategories(expenseCategories, type: .expense)
        saveUserPreferences()
        
        updateWidgetData() // Update widget after resetting
        signalBalanceChange()
    }
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = userPreferences.currencySymbol
        formatter.locale = Locale(identifier: userPreferences.locale)
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(userPreferences.currencySymbol)0.00"
    }

    // MARK: - Budget Management
    
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
            
            if updatedBudget.timePeriod != budgets[index].timePeriod {
                updatedBudget.periodStartDate = getCurrentPeriodStartDate(for: updatedBudget.timePeriod, from: Date())
                updatedBudget.currentSpent = 0.0
            } else {
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
            handleTransactionChange()
        } else {
            budgets = []
        }
    }

    func handleTransactionChange() {
        checkAndResetBudgetPeriods()
        recalculateBudgetSpending()
    }
    
    func checkAndResetBudgetPeriods() {
        let currentDate = Date()
        var budgetsUpdated = false
        
        for i in 0..<budgets.count {
            let budget = budgets[i]
            let currentPeriodStart = getCurrentPeriodStartDate(for: budget.timePeriod, from: currentDate)
            
            if shouldResetBudgetPeriod(budget: budget, currentPeriodStart: currentPeriodStart) {
                var updatedBudget = budget
                updatedBudget.periodStartDate = currentPeriodStart
                updatedBudget.currentSpent = 0.0
                budgets[i] = updatedBudget
                budgetsUpdated = true
            }
        }
        
        if budgetsUpdated {
            saveBudgets()
        }
    }
    
    private func shouldResetBudgetPeriod(budget: Budget, currentPeriodStart: Date) -> Bool {
        guard let budgetPeriodStart = budget.periodStartDate else {
            return true
        }
        return currentPeriodStart > budgetPeriodStart
    }
    
    func getCurrentPeriodStartDate(for timePeriod: TimePeriod, from referenceDate: Date) -> Date {
        let calendar = Calendar.current
        
        switch timePeriod {
        case .weekly:
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: referenceDate)
            components.weekday = 2 // Monday
            return calendar.date(from: components) ?? referenceDate
            
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: referenceDate)
            return calendar.date(from: components) ?? referenceDate
            
        case .yearly:
            let components = calendar.dateComponents([.year], from: referenceDate)
            return calendar.date(from: components) ?? referenceDate
        }
    }

    func recalculateBudgetSpending() {
        for i in 0..<budgets.count {
            budgets[i].currentSpent = 0.0
        }
        
        let expenseTransactions = transactions.filter { $0.type == .expense }
        
        for i in 0..<budgets.count {
            let budget = budgets[i]
            guard let periodStartDate = budget.periodStartDate else { continue }
            
            var totalSpent: Double = 0.0
            let periodEndDate = budget.timePeriod.getNextResetDate(from: periodStartDate)
            
            for transaction in expenseTransactions {
                guard transaction.date >= periodStartDate && transaction.date < periodEndDate else { continue }
                
                if shouldTransactionCountForBudget(transaction: transaction, budget: budget) {
                    totalSpent += transaction.amount
                }
            }
            budgets[i].currentSpent = totalSpent
        }
        
        saveBudgets()
    }
    
    private func shouldTransactionCountForBudget(transaction: Transaction, budget: Budget) -> Bool {
        switch budget.type {
        case .overall:
            return true
        case .category:
            guard let budgetCategoryId = budget.categoryId else { return false }
            return budgetCategoryId == transaction.categoryId
        case .account:
            guard let budgetAccountId = budget.accountId, let transactionAccountId = transaction.fromAccountId else { return false }
            return budgetAccountId == transactionAccountId
        }
    }
    
    // MARK: - Recurring Transactions - Assuming Transaction has these properties
    
    // The following properties and methods assume `Transaction` has `isRecurring`, `recurrenceInterval`,
    // `recurrenceEndDate`, `parentTransactionId`, and `isFutureTransaction` properties.
    // If not, these will cause errors and should be adapted to your data model.

    // MARK: - Test Data, Import/Export
    
    func generateTestData() {
        if incomeCategories.isEmpty { incomeCategories = Category.defaultIncomeCategories }
        if expenseCategories.isEmpty { expenseCategories = Category.defaultExpenseCategories }
        
        if accounts.isEmpty {
            accounts = [
                Account(name: "Savings Account", type: .savings, initialBalance: 1500.0, balance: 1500.0),
                Account(name: "Current Account", type: .current, initialBalance: 2000.0, balance: 2000.0),
                Account(name: "Credit Card", type: .credit, initialBalance: 0.0, balance: 0.0)
            ]
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        var newTransactions: [Transaction] = []
        
        let savingsId = accounts.first(where: { $0.type == .savings })?.id
        let currentId = accounts.first(where: { $0.type == .current })?.id
        let creditId = accounts.first(where: { $0.type == .credit })?.id
        
        let salaryId = incomeCategories.first(where: { $0.name == "Salary" })?.id ?? incomeCategories[0].id
        let loanId = incomeCategories.first(where: { $0.name == "Student Loan" })?.id ?? incomeCategories[0].id
        let giftId = incomeCategories.first(where: { $0.name == "Gift" })?.id ?? incomeCategories[0].id
        
        let foodId = expenseCategories.first(where: { $0.name == "Food" })?.id ?? expenseCategories[0].id
        let transportId = expenseCategories.first(where: { $0.name == "Transport" })?.id ?? expenseCategories[0].id
        let entertainmentId = expenseCategories.first(where: { $0.name == "Entertainment" })?.id ?? expenseCategories[0].id
        let shoppingId = expenseCategories.first(where: { $0.name == "Shopping" })?.id ?? expenseCategories[0].id
        let billsId = expenseCategories.first(where: { $0.name == "Bills" })?.id ?? expenseCategories[0].id
        let housingId = expenseCategories.first(where: { $0.name == "Housing" })?.id ?? expenseCategories[0].id
        
        for monthOffset in 0..<6 {
            let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: currentDate)!
            
            let salaryDay = calendar.date(bySettingHour: 9, minute: 30, second: 0, of: getDateForDay(25, in: monthDate))!
            newTransactions.append(Transaction(date: salaryDay, amount: Double.random(in: 1800...2200), description: "Monthly Salary", toAccount: .current, toAccountId: currentId, type: .income, categoryId: salaryId))
            
            if monthOffset % 3 == 0 {
                let loanDay = calendar.date(bySettingHour: 10, minute: 15, second: 0, of: getDateForDay(15, in: monthDate))!
                newTransactions.append(Transaction(date: loanDay, amount: 2500.0, description: "Student Loan Installment", toAccount: .current, toAccountId: currentId, type: .income, categoryId: loanId))
            }
            
            for _ in 1...15 {
                let randomDay = Int.random(in: 1...28)
                let expenseDate = calendar.date(bySettingHour: Int.random(in: 8...21), minute: Int.random(in: 0...59), second: 0, of: getDateForDay(randomDay, in: monthDate))!
                let categories = [(foodId, "Food", 5.0...50.0), (transportId, "Transport", 2.0...30.0), (entertainmentId, "Entertainment", 10.0...100.0), (shoppingId, "Shopping", 15.0...200.0)]
                let (categoryId, categoryName, amountRange) = categories.randomElement()!
                let isCredit = Bool.random()
                newTransactions.append(Transaction(date: expenseDate, amount: Double.random(in: amountRange), description: "\(categoryName) expense", fromAccount: isCredit ? .credit : .current, fromAccountId: isCredit ? creditId : currentId, type: .expense, categoryId: categoryId))
            }
        }
        
        transactions.append(contentsOf: newTransactions)
        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveAccounts(accounts)
        recalcAccounts()
        handleTransactionChange()
    }
    
    private func getDateForDay(_ day: Int, in date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = min(day, calendar.range(of: .day, in: .month, for: date)?.count ?? 28)
        return calendar.date(from: components) ?? date
    }

    func exportData(format: String) -> URL? {
        // Implementation for exporting data
        return nil
    }
    
    func importData(from url: URL) -> (success: Bool, message: String) {
        // Implementation for importing data
        return (false, "Not implemented")
    }
    
    // MARK: - Recurring Transactions API for UI (Stubs)
    func updateRecurringTransaction(_ transaction: Transaction) {
        // TODO: Implement updating recurring transactions
    }
    
    func generateRecurringTransactions(from transaction: Transaction) {
        // TODO: Implement generation of recurring transactions
    }
    
    func deleteRecurringTransaction(_ transaction: Transaction, deleteAllFutureInstances: Bool) {
        // TODO: Implement deletion of recurring transactions
    }
}
