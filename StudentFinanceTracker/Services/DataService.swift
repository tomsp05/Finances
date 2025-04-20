import Foundation

class DataService {
    
    // At the top of DataService.swift, add a new file constant:
    private let themeColorFile = "themeColor.json"
    private let incomeCategsFile = "incomeCategories.json"
    private let expenseCategsFile = "expenseCategories.json"

    private var themeColorURL: URL {
        documentsDirectory.appendingPathComponent(themeColorFile)
    }
    
    private var incomeCategoriesURL: URL {
        documentsDirectory.appendingPathComponent(incomeCategsFile)
    }
    
    private var expenseCategoriesURL: URL {
        documentsDirectory.appendingPathComponent(expenseCategsFile)
    }

    // MARK: - Theme Color Persistence

    func saveThemeColor(_ colorName: String) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(colorName)
            try data.write(to: themeColorURL)
            print("Theme color saved successfully at \(themeColorURL)")
        } catch {
            print("Error saving theme color: \(error)")
        }
    }

    func loadThemeColor() -> String? {
        do {
            let data = try Data(contentsOf: themeColorURL)
            let colorName = try JSONDecoder().decode(String.self, from: data)
            print("Theme color loaded successfully from \(themeColorURL)")
            return colorName
        } catch {
            print("Error loading theme color: \(error)")
        }
        return nil
    }
    
    static let shared = DataService()
    
    private let accountsFile = "accounts.json"
    private let transactionsFile = "transactions.json"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var accountsURL: URL {
        documentsDirectory.appendingPathComponent(accountsFile)
    }
    
    private var transactionsURL: URL {
        documentsDirectory.appendingPathComponent(transactionsFile)
    }
    
    // MARK: - Accounts Persistence
    
    func saveAccounts(_ accounts: [Account]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(accounts)
            try data.write(to: accountsURL)
            print("Accounts saved successfully at \(accountsURL)")
        } catch {
            print("Error saving accounts: \(error)")
        }
    }
    
    func loadAccounts() -> [Account]? {
        do {
            let data = try Data(contentsOf: accountsURL)
            let accounts = try JSONDecoder().decode([Account].self, from: data)
            print("Accounts loaded successfully from \(accountsURL)")
            return accounts
        } catch {
            print("Error loading accounts: \(error)")
        }
        return nil
    }
    
    // MARK: - Transactions Persistence
    
    func saveTransactions(_ transactions: [Transaction]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(transactions)
            try data.write(to: transactionsURL)
            print("Transactions saved successfully at \(transactionsURL)")
        } catch {
            print("Error saving transactions: \(error)")
        }
    }
    
    func loadTransactions() -> [Transaction]? {
        do {
            let data = try Data(contentsOf: transactionsURL)
            let transactions = try JSONDecoder().decode([Transaction].self, from: data)
            print("Transactions loaded successfully from \(transactionsURL)")
            return transactions
        } catch {
            print("Error loading transactions: \(error)")
        }
        return nil
    }
    
    // MARK: - Categories Persistence
    
    func saveCategories(_ categories: [Category], type: CategoryType) {
        let url = type == .income ? incomeCategoriesURL : expenseCategoriesURL
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(categories)
            try data.write(to: url)
            print("Categories saved successfully at \(url)")
        } catch {
            print("Error saving categories: \(error)")
        }
    }
    
    func loadCategories(type: CategoryType) -> [Category]? {
        let url = type == .income ? incomeCategoriesURL : expenseCategoriesURL
        
        do {
            let data = try Data(contentsOf: url)
            let categories = try JSONDecoder().decode([Category].self, from: data)
            print("Categories loaded successfully from \(url)")
            return categories
        } catch {
            print("Error loading categories: \(error)")
        }
        return nil
    }
}

//
//  BudgetService.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/17/25.
//

import Foundation

extension DataService {
    // File URL for budgets
    private var budgetsFileURL: URL {
        // Access the documents directory directly instead of using the private property
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("budgets.json")
    }
    
    // Save budgets to file
    func saveBudgets(_ budgets: [Budget]) {
        do {
            let data = try JSONEncoder().encode(budgets)
            try data.write(to: budgetsFileURL)
        } catch {
            print("Failed to save budgets: \(error.localizedDescription)")
        }
    }
    
    // Load budgets from file
    func loadBudgets() -> [Budget]? {
        guard let data = try? Data(contentsOf: budgetsFileURL) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode([Budget].self, from: data)
        } catch {
            print("Failed to load budgets: \(error.localizedDescription)")
            return nil
        }
    }
}


extension DataService {
    // File name for user preferences
    private var userPreferencesFile: String { "userPreferences.json" }
    
    // URL for user preferences file
    private var userPreferencesURL: URL {
        documentsDirectory.appendingPathComponent(userPreferencesFile)
    }
    
    // Save user preferences to file
    func saveUserPreferences(_ preferences: UserPreferences) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(preferences)
            try data.write(to: userPreferencesURL)
            print("User preferences saved successfully at \(userPreferencesURL)")
        } catch {
            print("Error saving user preferences: \(error)")
        }
    }
    
    // Load user preferences from file
    func loadUserPreferences() -> UserPreferences? {
        do {
            let data = try Data(contentsOf: userPreferencesURL)
            let preferences = try JSONDecoder().decode(UserPreferences.self, from: data)
            print("User preferences loaded successfully from \(userPreferencesURL)")
            return preferences
        } catch {
            print("Error loading user preferences: \(error)")
        }
        return nil
    }
}
