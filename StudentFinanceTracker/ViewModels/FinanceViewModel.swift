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
    let legacyDefaults = UserDefaults.standard

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
           case "Pink":
               return Color(red: 0.90, green: 0.40, blue: 0.60) // Pink
           default:
               return Color(red: 0.20, green: 0.40, blue: 0.70) // Default to Blue
           }
       }

    @Published var budgets: [Budget] = []

    init() {
        migrateLegacyDataIfNeeded()
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
            accounts = []
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
    
    

    // Helper to migrate old account types to new ones
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

    // Helper to migrate transactions with old account types
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

        // Calculate net balance
        let currentAccountsTotal = accounts.filter { $0.type == .current }.reduce(0) { $0 + $1.balance }
        let creditCardsTotal = accounts.filter { $0.type == .credit }.reduce(0) { $0 + $1.balance }
        let netBalance = currentAccountsTotal - creditCardsTotal

        // Get the 3 most recent transactions
        let recentTransactions = Array(transactions.sorted { $0.date > $1.date }.prefix(15))

        // Convert the theme color to Data for UserDefaults
        var themeColorData: Data?
        if let cgColor = themeColor.cgColor {
            // Convert SwiftUI Color to UIColor
            let uiColor = UIColor(cgColor: cgColor)
            // Archive UIColor to Data
            themeColorData = try? NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        }

        let widgetData = WidgetData(
            netBalance: netBalance,
            transactions: recentTransactions,
            themeColorData: themeColorData,
            categories: self.expenseCategories // <-- ADD THIS
        )

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

    // Modify updateTransaction function to update pool amounts when transactions are modified

    func updateTransaction(_ updatedTransaction: Transaction) {
        // Find the original transaction
        if let index = transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            let originalTransaction = transactions[index]
            
            // Check if pool assignment has changed
            if originalTransaction.poolId != updatedTransaction.poolId {
                // If there was a previous pool assignment, adjust that pool's amount
                if let oldPoolId = originalTransaction.poolId,
                   let accountId = originalTransaction.type == .expense ? originalTransaction.fromAccountId : originalTransaction.toAccountId,
                   var pools = getAccountPools(accountId),
                   let poolIndex = pools.firstIndex(where: { $0.id == oldPoolId }) {
                    
                    // Restore amount to the old pool
                    if originalTransaction.type == .expense {
                        pools[poolIndex].amount += originalTransaction.amount
                    } else if originalTransaction.type == .income {
                        pools[poolIndex].amount -= originalTransaction.amount
                    }
                    
                    // Save the updated pools
                    saveAccountPools(accountId, pools: pools)
                }
                
                // If there is a new pool assignment, adjust that pool's amount
                if let newPoolId = updatedTransaction.poolId,
                   let accountId = updatedTransaction.type == .expense ? updatedTransaction.fromAccountId : updatedTransaction.toAccountId,
                   var pools = getAccountPools(accountId),
                   let poolIndex = pools.firstIndex(where: { $0.id == newPoolId }) {
                    
                    // Deduct/add amount from/to the new pool
                    if updatedTransaction.type == .expense {
                        pools[poolIndex].amount -= updatedTransaction.amount
                    } else if updatedTransaction.type == .income {
                        pools[poolIndex].amount += updatedTransaction.amount
                    }
                    
                    // Save the updated pools
                    saveAccountPools(accountId, pools: pools)
                }
            }
            // If the amount has changed but pool is the same
            else if originalTransaction.amount != updatedTransaction.amount && updatedTransaction.poolId != nil {
                if let poolId = updatedTransaction.poolId,
                   let accountId = updatedTransaction.type == .expense ? updatedTransaction.fromAccountId : updatedTransaction.toAccountId,
                   var pools = getAccountPools(accountId),
                   let poolIndex = pools.firstIndex(where: { $0.id == poolId }) {
                    
                    // Calculate difference
                    let difference = updatedTransaction.amount - originalTransaction.amount
                    
                    // Adjust pool amount
                    if updatedTransaction.type == .expense {
                        pools[poolIndex].amount -= difference
                    } else if updatedTransaction.type == .income {
                        pools[poolIndex].amount += difference
                    }
                    
                    // Save the updated pools
                    saveAccountPools(accountId, pools: pools)
                }
            }
            
            // Update the transaction
            transactions[index] = updatedTransaction
            recalcAccounts()
            DataService.shared.saveTransactions(transactions)
            signalBalanceChange()
            handleTransactionChange()
            updateWidgetData() // Update widget
        }
    }

    // Modify deleteTransaction to handle pools
    func deleteTransaction(at offsets: IndexSet) {
        // Handle pool updates for each deleted transaction
        for index in offsets {
            let transaction = transactions[index]
            if let poolId = transaction.poolId,
               let accountId = transaction.type == .expense ? transaction.fromAccountId : transaction.toAccountId,
               var pools = getAccountPools(accountId),
               let poolIndex = pools.firstIndex(where: { $0.id == poolId }) {
                
                // Restore amount to the pool
                if transaction.type == .expense {
                    pools[poolIndex].amount += transaction.amount
                } else if transaction.type == .income {
                    pools[poolIndex].amount -= transaction.amount
                }
                
                // Save the updated pools
                saveAccountPools(accountId, pools: pools)
            }
        }
        
        // Delete the transactions
        transactions.remove(atOffsets: offsets)
        recalcAccounts()
        DataService.shared.saveTransactions(transactions)
        signalBalanceChange()
        handleTransactionChange()
        updateWidgetData() // Update widget
    }

    // Modify addTransaction to handle pools
    func addTransaction(_ transaction: Transaction) {
        // Add the transaction
        transactions.append(transaction)
        
        // Update pool if transaction is assigned to one
        if let poolId = transaction.poolId,
           let accountId = transaction.type == .expense ? transaction.fromAccountId : transaction.toAccountId,
           var pools = getAccountPools(accountId),
           let poolIndex = pools.firstIndex(where: { $0.id == poolId }) {
            
            // Adjust pool amount
            if transaction.type == .expense {
                pools[poolIndex].amount -= transaction.amount
            } else if transaction.type == .income {
                pools[poolIndex].amount += transaction.amount
            }
            
            // Save the updated pools
            saveAccountPools(accountId, pools: pools)
        }
        
        recalcAccounts()
        handleTransactionChange()
        signalBalanceChange()
        DataService.shared.saveTransactions(transactions)
        updateWidgetData() // Update widget data
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
        recalcAccounts()
    }

    // MARK: - Settings and Data Management

    func updateAccountsSettings(updatedAccounts: [Account]) {
        accounts = updatedAccounts
        DataService.shared.saveAccounts(accounts)
        recalcAccounts()
    }

    func deleteAccountAndTransactions(accountId: UUID) {
        // Find and delete transactions associated with the account
        transactions.removeAll { $0.fromAccountId == accountId || $0.toAccountId == accountId }

        // Delete the account
        accounts.removeAll { $0.id == accountId }

        // Delete associated pools stored in UserDefaults
        UserDefaults.standard.removeObject(forKey: "pools_\(accountId.uuidString)")
        
        // Save the changes
        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveAccounts(accounts)

        // Recalculate balances and update UI
        recalcAccounts()
        handleTransactionChange()
        signalBalanceChange()
        
        // Update widget data if applicable
        updateWidgetData()
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
        // Backup current accounts to clean up pools
        let oldAccounts = accounts
        
        transactions = []
        accounts = []
        budgets = []
        incomeCategories = Category.defaultIncomeCategories
        expenseCategories = Category.defaultExpenseCategories
        userPreferences = UserPreferences.defaultPreferences

        // Clean up pools for all deleted accounts
        for account in oldAccounts {
            UserDefaults.standard.removeObject(forKey: "pools_\(account.id.uuidString)")
        }

        DataService.shared.saveTransactions(transactions)
        DataService.shared.saveAccounts(accounts)
        DataService.shared.saveBudgets(budgets)
        DataService.shared.saveCategories(incomeCategories, type: .income)
        DataService.shared.saveCategories(expenseCategories, type: .expense)
        DataService.shared.saveThemeColor(themeColorName)
        
        saveUserPreferences()
        handleTransactionChange()
        signalBalanceChange()
    }

    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = userPreferences.currency.rawValue
        formatter.locale = Locale(identifier: userPreferences.currency.locale)
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(userPreferences.currency.rawValue)0.00"
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

// Add to FinanceViewModel.swift
extension FinanceViewModel {
    // Import data from a file
    func importData(from url: URL) -> (success: Bool, message: String) {
        let fileExtension = url.pathExtension.lowercased()

        switch fileExtension {
        case "json":
            return importFromJSON(url: url)
        case "csv":
            return importFromCSV(url: url)
        default:
            return (false, "Unsupported file format. Please use JSON or CSV files exported from this app.")
        }
    }

    // Import data from JSON file
    private func importFromJSON(url: URL) -> (success: Bool, message: String) {
        do {
            // First check if the file exists and is accessible
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: url.path) else {
                return (false, "File does not exist at the specified location.")
            }

            // Try to read the file
            let data: Data
            do {
                data = try Data(contentsOf: url)
            } catch {
                return (false, "Could not read file: \(error.localizedDescription). This may be a permissions issue.")
            }

            let decoder = JSONDecoder()

            // Create a container to hold the decoded data
            struct ImportContainer: Codable {
                var accounts: [Account]?
                var transactions: [Transaction]?
                var incomeCategories: [Category]?
                var expenseCategories: [Category]?
                var budgets: [Budget]?
                var userPreferences: UserPreferences?
            }

            // Try to decode the data
            let importedData: ImportContainer
            do {
                importedData = try decoder.decode(ImportContainer.self, from: data)
            } catch {
                return (false, "Error decoding JSON file: \(error.localizedDescription). The file may be corrupted or in an invalid format.")
            }

            // Count how many items we'll import
            var accountsCount = 0
            var transactionsCount = 0
            var incomeCategoriesCount = 0
            var expenseCategoriesCount = 0
            var budgetsCount = 0

            // Import accounts
            if let importedAccounts = importedData.accounts {
                // Create a mapping of old IDs to new IDs for proper referencing
                var accountIdMapping = [UUID: UUID]()

                for importedAccount in importedAccounts {
                    // Check if this account already exists (by name and type)
                    if !accounts.contains(where: { $0.name == importedAccount.name && $0.type == importedAccount.type }) {
                        // Create new account with a new ID
                        let newId = UUID()
                        accountIdMapping[importedAccount.id] = newId

                        var newAccount = importedAccount
                        newAccount.id = newId
                        accounts.append(newAccount)
                        accountsCount += 1
                    }
                }
                DataService.shared.saveAccounts(accounts)

                // Import categories first (needed for transactions)
                if let importedIncomeCategories = importedData.incomeCategories {
                    var categoryIdMapping = [UUID: UUID]()

                    for importedCategory in importedIncomeCategories {
                        if !incomeCategories.contains(where: { $0.name == importedCategory.name }) {
                            let newId = UUID()
                            categoryIdMapping[importedCategory.id] = newId

                            var newCategory = importedCategory
                            newCategory.id = newId
                            incomeCategories.append(newCategory)
                            incomeCategoriesCount += 1
                        }
                    }

                    DataService.shared.saveCategories(incomeCategories, type: .income)
                }

                if let importedExpenseCategories = importedData.expenseCategories {
                    var categoryIdMapping = [UUID: UUID]()

                    for importedCategory in importedExpenseCategories {
                        if !expenseCategories.contains(where: { $0.name == importedCategory.name }) {
                            let newId = UUID()
                            categoryIdMapping[importedCategory.id] = newId

                            var newCategory = importedCategory
                            newCategory.id = newId
                            expenseCategories.append(newCategory)
                            expenseCategoriesCount += 1
                        }
                    }

                    DataService.shared.saveCategories(expenseCategories, type: .expense)
                }

                // Import transactions with proper account references
                if let importedTransactions = importedData.transactions {
                    for importedTransaction in importedTransactions {
                        // Skip if we already have this transaction (by date, amount, and description)
                        if transactions.contains(where: {
                            $0.date == importedTransaction.date &&
                                $0.amount == importedTransaction.amount &&
                                $0.description == importedTransaction.description
                        }) {
                            continue
                        }

                        var newTransaction = importedTransaction
                        newTransaction.id = UUID() // Generate new ID

                        // Update account references if needed
                        if let fromAccountId = importedTransaction.fromAccountId,
                           let mappedId = accountIdMapping[fromAccountId] {
                            newTransaction.fromAccountId = mappedId
                        }

                        if let toAccountId = importedTransaction.toAccountId,
                           let mappedId = accountIdMapping[toAccountId] {
                            newTransaction.toAccountId = mappedId
                        }

                        // Add the transaction
                        transactions.append(newTransaction)
                        transactionsCount += 1
                    }

                    DataService.shared.saveTransactions(transactions)
                }

                // Import budgets with proper account and category references
                if let importedBudgets = importedData.budgets {
                    for importedBudget in importedBudgets {
                        // Skip if we already have this budget (by name and amount)
                        if budgets.contains(where: { $0.name == importedBudget.name && $0.amount == importedBudget.amount }) {
                            continue
                        }

                        var newBudget = importedBudget
                        newBudget.id = UUID() // Generate new ID

                        // Add the budget
                        budgets.append(newBudget)
                        budgetsCount += 1
                    }

                    DataService.shared.saveBudgets(budgets)
                }

                // Import user preferences if provided
                if let importedPreferences = importedData.userPreferences {
                    // Only update preferences if explicitly requested
                    // For now, we'll skip this to avoid overwriting current preferences
                }

                // Recalculate account balances after importing transactions
                recalcAccounts()
                recalculateBudgetSpending()

                // Success message with counts
                let successMessage = """
                        Import completed successfully:
                        • \(accountsCount) accounts added
                        • \(transactionsCount) transactions imported
                        • \(incomeCategoriesCount + expenseCategoriesCount) categories added
                        • \(budgetsCount) budgets imported
                        """

                return (true, successMessage)
            }

            return (false, "File did not contain valid account data.")

        } catch {
            print("Import error: \(error)")
            return (false, "Error reading file: \(error.localizedDescription)")
        }
    }
    // Import data from CSV file
    private func importFromCSV(url: URL) -> (success: Bool, message: String) {
        do {
            let csvString = try String(contentsOf: url, encoding: .utf8)
            var lines = csvString.components(separatedBy: .newlines)

            // Variables for counting imported items
            var accountsCount = 0
            var transactionsCount = 0
            var categoriesCount = 0
            var budgetsCount = 0

            // Maps to store ID mappings from old to new
            var accountIdMapping = [String: UUID]()
            var categoryIdMapping = [String: UUID]()

            // Process accounts section
            if let accountsStartIndex = lines.firstIndex(of: "ACCOUNTS") {
                var currentLine = accountsStartIndex + 2 // Skip header

                while currentLine < lines.count && !lines[currentLine].isEmpty && lines[currentLine] != "TRANSACTIONS" {
                    let line = lines[currentLine]
                    let components = parseCSVLine(line)

                    if components.count >= 5 {
                        let idString = components[0]
                        let name = components[1].replacingOccurrences(of: "\"", with: "")
                        let typeString = components[2]
                        let initialBalanceString = components[3]
                        let currentBalanceString = components[4]
                        
                        if let type = AccountType(rawValue: typeString),
                           let initialBalance = Double(initialBalanceString),
                           let currentBalance = Double(currentBalanceString) {

                            // Check if an account with the same name and type already exists
                            if let existingAccount = accounts.first(where: { $0.name == name && $0.type == type }) {
                                // If it exists, map the old ID from the CSV to the existing account's ID
                                accountIdMapping[idString] = existingAccount.id
                            } else {
                                // If it doesn't exist, create a new account and map the old ID to the new ID
                                let newId = UUID()
                                accountIdMapping[idString] = newId

                                let newAccount = Account(
                                    id: newId,
                                    name: name,
                                    type: type,
                                    initialBalance: initialBalance,
                                    balance: currentBalance
                                )

                                accounts.append(newAccount)
                                accountsCount += 1
                            }
                        }
                    }
                    currentLine += 1
                }

                // Save accounts
                DataService.shared.saveAccounts(accounts)
            }

            // Process categories section
            if let categoriesStartIndex = lines.firstIndex(of: "CATEGORIES") {
                var currentLine = categoriesStartIndex + 2 // Skip header

                while currentLine < lines.count && !lines[currentLine].isEmpty && !lines[currentLine].contains("BUDGETS") {
                    let line = lines[currentLine]
                    let components = parseCSVLine(line)

                    if components.count >= 4 {
                        let idString = components[0]
                        let name = components[1].replacingOccurrences(of: "\"", with: "")
                        let typeString = components[2]
                        let iconName = components[3]

                        if let type = CategoryType(rawValue: typeString) {
                            let newId = UUID()
                            categoryIdMapping[idString] = newId

                            let newCategory = Category(
                                id: newId,
                                name: name,
                                type: type,
                                iconName: iconName
                            )

                            if type == .income {
                                if !incomeCategories.contains(where: { $0.name == name }) {
                                    incomeCategories.append(newCategory)
                                    categoriesCount += 1
                                }
                            } else {
                                if !expenseCategories.contains(where: { $0.name == name }) {
                                    expenseCategories.append(newCategory)
                                    categoriesCount += 1
                                }
                            }
                        }
                    }

                    currentLine += 1
                }

                // Save categories
                DataService.shared.saveCategories(incomeCategories, type: .income)
                DataService.shared.saveCategories(expenseCategories, type: .expense)
            }
            // Process transactions section
            if let transactionsStartIndex = lines.firstIndex(of: "TRANSACTIONS") {
                var currentLine = transactionsStartIndex + 2 // Skip header

                while currentLine < lines.count && !lines[currentLine].isEmpty && !lines[currentLine].contains("CATEGORIES") {
                    let line = lines[currentLine]
                    let components = parseCSVLine(line)

                    if components.count >= 15 {
                        let idString = components[0]
                        let dateString = components[1]
                        let amountString = components[2]
                        let description = components[3].replacingOccurrences(of: "\"", with: "")
                        let fromAccountString = components[4]
                        let toAccountString = components[5]
                        let fromAccountIdString = components[6]
                        let toAccountIdString = components[7]
                        let typeString = components[8]
                        let categoryIdString = components[9]
                        let isSplitString = components[10]
                        let friendName = components[11].replacingOccurrences(of: "\"", with: "")
                        let friendAmountString = components[12]
                        let userAmountString = components[13]
                        let friendPaymentDestination = components[14].replacingOccurrences(of: "\"", with: "")

                        // Convert date
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        if let date = dateFormatter.date(from: dateString),
                           let amount = Double(amountString),
                           let type = TransactionType(rawValue: typeString) {

                            // Skip if we already have a similar transaction
                            if transactions.contains(where: {
                                $0.date == date &&
                                    $0.amount == amount &&
                                    $0.description == description
                            }) {
                                currentLine += 1
                                continue
                            }

                            // Map account types and IDs
                            var fromAccount: AccountType? = nil
                            if !fromAccountString.isEmpty {
                                fromAccount = AccountType(rawValue: fromAccountString)
                            }

                            var toAccount: AccountType? = nil
                            if !toAccountString.isEmpty {
                                toAccount = AccountType(rawValue: toAccountString)
                            }

                            var fromAccountId: UUID? = nil
                            if !fromAccountIdString.isEmpty {
                                fromAccountId = accountIdMapping[fromAccountIdString]
                            }

                            var toAccountId: UUID? = nil
                            if !toAccountIdString.isEmpty {
                                toAccountId = accountIdMapping[toAccountIdString]
                            }

                            // Map category ID
                            var categoryId: UUID = UUID() // Default as fallback
                            if let mappedCategoryId = categoryIdMapping[categoryIdString] {
                                categoryId = mappedCategoryId
                            } else if let category = (type == .income ? incomeCategories : expenseCategories).first {
                                // Use first available category if mapping fails
                                categoryId = category.id
                            }

                            // Split payment info
                            let isSplit = isSplitString.lowercased() == "true"
                            let friendAmount = Double(friendAmountString) ?? 0.0
                            let userAmount = Double(userAmountString) ?? 0.0

                            // Create the transaction
                            let newTransaction = Transaction(
                                id: UUID(), // Generate new ID
                                date: date,
                                amount: amount,
                                description: description,
                                fromAccount: fromAccount,
                                toAccount: toAccount,
                                fromAccountId: fromAccountId,
                                toAccountId: toAccountId,
                                type: type,
                                categoryId: categoryId,
                                isSplit: isSplit,
                                friendName: friendName,
                                friendAmount: friendAmount,
                                userAmount: userAmount,
                                friendPaymentDestination: friendPaymentDestination
                            )

                            transactions.append(newTransaction)
                            transactionsCount += 1
                        }
                    }

                    currentLine += 1
                }

                // Save transactions
                DataService.shared.saveTransactions(transactions)
            }

            // Process budgets section
            if let budgetsStartIndex = lines.firstIndex(of: "BUDGETS") {
                var currentLine = budgetsStartIndex + 2 // Skip header

                while currentLine < lines.count && !lines[currentLine].isEmpty {
                    let line = lines[currentLine]
                    let components = parseCSVLine(line)

                    if components.count >= 8 {
                        let idString = components[0]
                        let name = components[1].replacingOccurrences(of: "\"", with: "")
                        let amountString = components[2]
                        let typeString = components[3]
                        let timePeriodString = components[4]
                        let categoryIdString = components[5]
                        let accountIdString = components[6]
                        let startDateString = components[7]
                        let currentSpentString = components.count > 8 ? components[8] : "0"

                        // Convert types
                        if let amount = Double(amountString),
                           let budgetType = BudgetType(rawValue: typeString),
                           let timePeriod = TimePeriod(rawValue: timePeriodString) {

                            // Skip if budget already exists
                            if budgets.contains(where: { $0.name == name && $0.amount == amount }) {
                                currentLine += 1
                                continue
                            }

                            // Parse date
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            let startDate = dateFormatter.date(from: startDateString) ?? Date()
                            let currentSpent = Double(currentSpentString) ?? 0.0

                            // Map category and account IDs
                            var categoryId: UUID? = nil
                            if !categoryIdString.isEmpty {
                                categoryId = categoryIdMapping[categoryIdString]
                            }

                            var accountId: UUID? = nil
                            if !accountIdString.isEmpty {
                                accountId = accountIdMapping[accountIdString]
                            }


                            // Create the budget
                            let newBudget = Budget(
                                id: UUID(), // Generate new ID
                                name: name,
                                amount: amount,
                                type: budgetType,
                                timePeriod: timePeriod,
                                categoryId: categoryId,
                                accountId: accountId,
                                startDate: startDate,
                                currentSpent: currentSpent
                            )

                            budgets.append(newBudget)
                            budgetsCount += 1
                        }
                    }

                    currentLine += 1
                }

                // Save budgets
                DataService.shared.saveBudgets(budgets)
            }

            // Recalculate account balances after importing transactions
            recalcAccounts()
            recalculateBudgetSpending()

            let successMessage = """
                    Import completed successfully:
                    • \(accountsCount) accounts added
                    • \(transactionsCount) transactions imported
                    • \(categoriesCount) categories added
                    • \(budgetsCount) budgets imported
                    """

            return (true, successMessage)

        } catch {
            print("Import error: \(error)")
            return (false, "Error reading CSV file: \(error.localizedDescription)")
        }
    }

    // Helper function to parse CSV lines properly (handling quotes)
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var currentValue = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(currentValue)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }

        // Add the last component
        result.append(currentValue)

        return result
    }
}


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

extension FinanceViewModel {
    /// Migrates user data from legacy storage (UserDefaults.standard and old file locations) into new group container if needed.
    private func migrateLegacyDataIfNeeded() {
        let migrationFlagKey = "didMigrateLegacyData"
        guard defaults?.bool(forKey: migrationFlagKey) != true else { return }

        // 1. Migrate user preferences (including onboarding status)
        if let legacyPrefsData = legacyDefaults.data(forKey: "userPreferences"),
           defaults?.data(forKey: "userPreferences") == nil {
            defaults?.set(legacyPrefsData, forKey: "userPreferences")
        }

        // 2. Migrate theme color (legacy key)
        if let legacyTheme = legacyDefaults.string(forKey: "themeColor"),
           defaults?.string(forKey: "themeColor") == nil {
            defaults?.set(legacyTheme, forKey: "themeColor")
        }

        // 3. Migrate accounts, categories, transactions, budgets files from old locations if present
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let groupDocDir = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.TomSpeake.StudentFinanceTracker") ?? docDir

        // Helper to copy file if needed
        func migrateFile(named name: String) {
            let legacyURL = docDir.appendingPathComponent(name)
            let newURL = groupDocDir.appendingPathComponent(name)
            if fileManager.fileExists(atPath: legacyURL.path) && !fileManager.fileExists(atPath: newURL.path) {
                try? fileManager.copyItem(at: legacyURL, to: newURL)
            }
        }

        migrateFile(named: "accounts.json")
        migrateFile(named: "incomeCategories.json")
        migrateFile(named: "expenseCategories.json")
        migrateFile(named: "transactions.json")
        migrateFile(named: "budgets.json")

        // 4. Migrate pools (if per-account pools were stored in UserDefaults)
        // This migrates keys like pools_<accountId>
        for (key, value) in legacyDefaults.dictionaryRepresentation() {
            if key.starts(with: "pools_") && defaults?.object(forKey: key) == nil {
                defaults?.set(value, forKey: key)
            }
        }

        // 5. Mark migration as done
        defaults?.set(true, forKey: migrationFlagKey)
    }
}
