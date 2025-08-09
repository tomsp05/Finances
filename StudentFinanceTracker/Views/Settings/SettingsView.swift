import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var showOnboardingSheet = false

    @State private var showConfirmationAlert = false
    
    // For editing account settings
    @State private var accountNames: [UUID: String] = [:]
    @State private var accountPresets: [UUID: String] = [:]
    @State private var accountTypes: [UUID: AccountType] = [:]
    @State private var editingAccount: Account? = nil
    @State private var showEditAccountSheet = false
    @State private var showTestDataAlert = false
    
    // Add state variable to track which action is being confirmed
    @State private var confirmationAction: ConfirmationAction = .deleteTransactions
    
    // Theme options
    let themeOptions = ["Blue", "Green", "Orange", "Purple", "Red", "Teal", "Pink"]
    @State private var selectedTheme: String = ""
    
    // Export data option
    @State private var showingExportOptions = false
    
    // Account management
    @State private var showAddAccountSheet = false
    @State private var newAccountName = ""
    @State private var newAccountType: AccountType = .savings
    @State private var newAccountBalance = ""
    @State private var accountToDelete: UUID? = nil
    
    // State for What's New sheet
    @State private var showWhatsNewSheet = false
    
    // Enum to track which confirmation is being shown
    enum ConfirmationAction {
        case deleteTransactions
        case resetAllData
        case deleteAccount
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with title and save button
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    
                    Spacer()
                    
                    Button(action: saveAllSettings) {
                        Text("Save All")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.themeColor)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)
                
                // Personalization section
                settingsSection(title: "Appearance", icon: "paintbrush.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Theme Color")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            // Color preview row
                            HStack(spacing: 15) {
                                ForEach(themeOptions, id: \.self) { option in
                                    ThemeColorButton(
                                        colorName: option,
                                        isSelected: selectedTheme == option,
                                        onTap: { selectedTheme = option }
                                    )
                                }
                            }
                            
                            // Preview card with selected theme
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(getThemeColor(name: selectedTheme))
                                    .frame(height: 60)
                                    .overlay(
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                                .padding(.leading)
                                            
                                            Text("Theme Preview")
                                                .foregroundColor(.white)
                                                .fontWeight(.semibold)
                                            
                                            Spacer()
                                        }
                                    )
                            }
                        }
                    }
                }
                
                // Accounts section
                settingsSection(title: "Accounts", icon: "banknote.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Manage Accounts")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                showAddAccountSheet = true
                            }) {
                                Label("Add", systemImage: "plus.circle")
                                    .foregroundColor(viewModel.themeColor)
                            }
                        }
                        
                        if viewModel.accounts.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 12) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No accounts added yet")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        } else {
                            // List of accounts with minimal information
                            ForEach(viewModel.accounts) { account in
                                Button(action: {
                                    // Pre-populate account details for editing
                                    // Ensure dictionaries are populated before showing the sheet
                                    prepareEditAccount(account)
                                }) {
                                    HStack(spacing: 16) {
                                        // Account type indicator
                                        ZStack {
                                            Circle()
                                                .fill(getAccountColor(account.type).opacity(0.2))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: getAccountIcon(account.type))
                                                .font(.system(size: 18))
                                                .foregroundColor(getAccountColor(account.type))
                                        }
                                        
                                        // Account name and balance
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(account.name)
                                                .font(.headline)
                                            
                                            Text(formatCurrency(account.balance))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if account.id != viewModel.accounts.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                
                // Preferences section
                settingsSection(title: "Preferences", icon: "gearshape.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        // Categories manage button
                        NavigationLink(destination: CategoryEditView()) {
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(viewModel.themeColor)
                                    .cornerRadius(8)
                                
                                Text("Manage Categories")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Currency setting
                        Picker("Currency", selection: $viewModel.userPreferences.currency) {
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Text(currency.rawValue).tag(currency)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                    }
                }
                
                // Data management section
                settingsSection(title: "Data Management", icon: "externaldrive.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Data storage location indicator
                        HStack(spacing: 10) {
                            Image(systemName: viewModel.isUsingICloud ? "icloud.fill" : "internaldrive.fill")
                                .foregroundColor(viewModel.isUsingICloud ? .blue : .gray)
                                .font(.title3)
                            Text(viewModel.isUsingICloud ? "Data stored in iCloud" : "Data stored locally")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                            Spacer()
                        }
                        .padding(.bottom, 6)
                        
//                        // Show onboarding again button
//                        Button(action: {
//                            showOnboardingSheet = true
//                        }) {
//                            HStack {
//                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
//                                    .foregroundColor(.white)
//                                    .padding(8)
//                                    .background(viewModel.themeColor)
//                                    .cornerRadius(8)
//                                
//                                Text("Show Onboarding Again")
//                                    .fontWeight(.semibold)
//                                
//                                Spacer()
//                                
//                                Image(systemName: "chevron.right")
//                                    .foregroundColor(.gray)
//                            }
//                            .padding()
//                            .background(Color(.systemBackground))
//                            .cornerRadius(12)
//                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                        }
//                        .buttonStyle(PlainButtonStyle())

//                        // Add test data button
//                        Button(action: {
//                            viewModel.generateTestData()
//                            showTestDataAlert = true
//                        }) {
//                            HStack {
//                                Image(systemName: "plus.square.fill")
//                                    .foregroundColor(.white)
//                                    .padding(8)
//                                    .background(Color.green)
//                                    .cornerRadius(8)
//
//                                Text("Generate Test Data")
//                                    .fontWeight(.semibold)
//
//                                Spacer()
//                            }
//                            .padding()
//                            .background(Color(.systemBackground))
//                            .cornerRadius(12)
//                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                        }
//                        .buttonStyle(PlainButtonStyle())
                        
//                        // Delete All Transactions button
//                        Button(action: {
//                            confirmationAction = .deleteTransactions
//                            showConfirmationAlert = true
//                        }) {
//                            HStack {
//                                Image(systemName: "trash.fill")
//                                    .foregroundColor(.white)
//                                    .padding(8)
//                                    .background(Color.red)
//                                    .cornerRadius(8)
//
//                                Text("Delete All Transactions")
//                                    .fontWeight(.semibold)
//                                    .foregroundColor(.red)
//
//                                Spacer()
//                            }
//                            .padding()
//                            .background(Color(.systemBackground))
//                            .cornerRadius(12)
//                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//
                        // Reset All Data button
                        Button(action: {
                            resetAllData()
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.red)
                                    .cornerRadius(8)

                                Text("Reset All Data")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)

                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Import data button
                        NavigationLink(destination: ImportDataView()) {
                            HStack {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(viewModel.themeColor)
                                    .cornerRadius(8)
                                
                                Text("Import Data")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Export data button
                        NavigationLink(destination: ExportDataView()) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(viewModel.themeColor)
                                    .cornerRadius(8)
                                
                                Text("Export Data")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .actionSheet(isPresented: $showingExportOptions) {
                            ActionSheet(
                                title: Text("Export Data"),
                                message: Text("Choose an export format"),
                                buttons: [
                                    .default(Text("CSV")) {
                                        exportData(format: "csv")
                                    },
                                    .default(Text("JSON")) {
                                        exportData(format: "json")
                                    },
                                    .cancel()
                                ]
                            )
                        }
                        
                    }
                }
                
                // About section
                settingsSection(title: "About", icon: "info.circle.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Version")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("1.0.0")
                        }
                        
                        HStack {
                            Text("Developer")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Tom Speake")
                        }
                        
                        // What's New/Known Issues Button
                        Button(action: {
                            showWhatsNewSheet = true
                        }) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(viewModel.themeColor)
                                    .padding(8)
                                    .background(viewModel.themeColor.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Text("What's New / Known Issues")
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .onAppear {
            // Initialize dictionaries for all accounts when the view appears
            initializeAccountDictionaries()
            
            // Set the initial theme selection
            selectedTheme = viewModel.themeColorName
        }
        .sheet(isPresented: $showAddAccountSheet) {
            addAccountSheet
        }
        .sheet(isPresented: $showEditAccountSheet) {
            editAccountSheet
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingContainerView(isFromSettings: true)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showWhatsNewSheet) {
            WhatsNewView()
                .environmentObject(viewModel)
        }
        .alert(isPresented: $showConfirmationAlert) {
            switch confirmationAction {
            case .deleteTransactions:
                return Alert(
                    title: Text("Delete All Transactions"),
                    message: Text("Are you sure you want to delete all transactions? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        viewModel.deleteAllTransactions()
                    },
                    secondaryButton: .cancel()
                )
            case .resetAllData:
                return Alert(
                    title: Text("Reset All Data"),
                    message: Text("Are you sure you want to reset all data? This will delete all accounts, transactions, categories, and settings. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset Everything")) {
                        resetAllData()
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAccount:
                        return Alert(
                            title: Text("Delete Account"),
                            message: Text("Are you sure you want to delete this account? All associated transactions will be deleted as well."),
                            primaryButton: .destructive(Text("Delete")) {
                                if let id = accountToDelete {
                                    viewModel.deleteAccountAndTransactions(accountId: id)
                                    showEditAccountSheet = false  // Dismiss the sheet after deletion
                                    accountToDelete = nil  // Reset the state
                                }
                            },
                            secondaryButton: .cancel {
                                accountToDelete = nil  // Reset the state on cancel
                            }
                        )
            }
        }
        .alert(isPresented: $showTestDataAlert) {
            Alert(
                title: Text("Test Data Generated"),
                message: Text("6 months of sample transactions have been added to your account."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Helper Views
    
    // New method to initialize all account dictionaries
    private func initializeAccountDictionaries() {
        // Ensure dictionaries are populated for all accounts
        for account in viewModel.accounts {
            accountNames[account.id] = account.name
            accountPresets[account.id] = String(format: "%.2f", account.initialBalance)
            accountTypes[account.id] = account.type
        }
    }
    
    // New method to prepare for editing an account
    private func prepareEditAccount(_ account: Account) {
        // Ensure this specific account's data is in the dictionaries
        accountNames[account.id] = account.name
        accountPresets[account.id] = String(format: "%.2f", account.initialBalance)
        accountTypes[account.id] = account.type
        
        // Set the editing account
        editingAccount = account
        
        // Now show the sheet
        showEditAccountSheet = true
    }
    
    private var editAccountSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if let account = editingAccount {
                        // Header with account type icon
                        VStack(spacing: 8) {
                            // Account icon
                            ZStack {
                                Circle()
                                    .fill(getAccountColor(accountTypes[account.id] ?? account.type).opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: getAccountIcon(accountTypes[account.id] ?? account.type))
                                    .font(.system(size: 36))
                                    .foregroundColor(getAccountColor(accountTypes[account.id] ?? account.type))
                            }
                            .padding(.top, 12)
                            
                            // Account current balance
                            Text("Current Balance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(formatCurrency(account.balance))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(getBalanceColor(account))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 8)
                        
                        // Account name field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Account Name")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                TextField("Account Name", text: Binding(
                                    get: { accountNames[account.id] ?? account.name },
                                    set: { accountNames[account.id] = $0 }
                                ))
                                .padding()
                            }
                            .frame(height: 60)
                        }
                        .padding(.horizontal)
                        
                        // Account type picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Account Type")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                ForEach(AccountType.allCases, id: \.self) { type in
                                    AccountTypeButton(
                                        type: type,
                                        isSelected: accountTypes[account.id] ?? account.type == type,
                                        onTap: {
                                            accountTypes[account.id] = type
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Initial balance field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Initial Balance")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                                
                                HStack {
                                    TextField("0.00", text: Binding(
                                        get: { accountPresets[account.id] ?? String(format: "%.2f", account.initialBalance) },
                                        set: { accountPresets[account.id] = $0 }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    
                                    Spacer()
                                    
                                    // Preview formatted currency
                                    Text(formatPreviewCurrency(accountPresets[account.id] ?? String(format: "%.2f", account.initialBalance)))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing)
                                }
                            }
                            .frame(height: 60)
                        }
                        .padding(.horizontal)
                        
                        // Information about initial balance
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About Initial Balance")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(viewModel.themeColor)
                                    
                                    Text("Initial balance is the starting amount for your account. The app will recalculate your current balance based on all transactions.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if (accountTypes[account.id] ?? account.type) == .credit {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "creditcard.fill")
                                            .foregroundColor(viewModel.themeColor)
                                        
                                        Text("For credit cards, the balance represents your debt. A positive balance means you owe money to the credit card company.")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(viewModel.themeColor.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            // Save button
                            Button(action: {
                                saveAccountChanges()
                                showEditAccountSheet = false
                            }) {
                                Text("Save Changes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(viewModel.themeColor)
                                    .cornerRadius(15)
                                    .shadow(color: viewModel.themeColor.opacity(0.4), radius: 5, x: 0, y: 3)
                            }
                            .padding(.horizontal)
                            
                            // MARK: - Delete Account Button
                            // This button initiates the delete process for the selected account.
                            Button(action: {
                                // Set the account to be deleted.
                                accountToDelete = account.id
                                
                                viewModel.deleteAccountAndTransactions(accountId: account.id)

//                                // Specify the confirmation action.
//                                confirmationAction = .deleteAccount
//                                // Show the confirmation alert.
//                                showConfirmationAlert = true
                                // Hide the edit sheet to show the alert on the main view.
                                showEditAccountSheet = false
                                
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Account")
                                }
                                .font(.headline)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.bottom, 30)
                .onAppear {
                    // Make sure the account data is available when the sheet appears
                    if let account = editingAccount {
                        if accountNames[account.id] == nil {
                            accountNames[account.id] = account.name
                        }
                        if accountPresets[account.id] == nil {
                            accountPresets[account.id] = String(format: "%.2f", account.initialBalance)
                        }
                        if accountTypes[account.id] == nil {
                            accountTypes[account.id] = account.type
                        }
                    }
                }
            }
            .navigationTitle("Edit Account")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showEditAccountSheet = false
                }
            )
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    private func saveAccountChanges() {
        guard let account = editingAccount else { return }
        
        var updatedAccounts = viewModel.accounts
        if let index = updatedAccounts.firstIndex(where: { $0.id == account.id }) {
            if let newName = accountNames[account.id] {
                updatedAccounts[index].name = newName
            }
            if let newType = accountTypes[account.id] {
                updatedAccounts[index].type = newType
            }
            if let newPresetString = accountPresets[account.id],
               let newPreset = Double(newPresetString) {
                updatedAccounts[index].initialBalance = newPreset
                
                // If initial balance changes, adjust pools proportionally if needed
                if newPreset != account.initialBalance {
                    let ratio = newPreset / account.initialBalance
                    for j in 0..<updatedAccounts[index].pools.count {
                        updatedAccounts[index].pools[j].amount *= ratio
                    }
                }
            }
        }
        
        viewModel.updateAccountsSettings(updatedAccounts: updatedAccounts)
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(viewModel.themeColor)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            // Content
            content()
                .padding()
                .background(
                    colorScheme == .dark
                        ? Color(UIColor.secondarySystemBackground)
                        : Color(UIColor.systemBackground)
                )
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal)
    }
    
    private var addAccountSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with account type icon
                    VStack(spacing: 8) {
                        // Account icon
                        ZStack {
                            Circle()
                                .fill(getAccountColor(newAccountType).opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: getAccountIcon(newAccountType))
                                .font(.system(size: 36))
                                .foregroundColor(getAccountColor(newAccountType))
                        }
                        .padding(.top, 12)
                        
                        // Title
                        Text("New Account")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    // Account name field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            TextField("Account Name", text: $newAccountName)
                                .padding()
                        }
                        .frame(height: 60)
                    }
                    .padding(.horizontal)
                    
                    // Account type picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account Type")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach(AccountType.allCases, id: \.self) { type in
                                AccountTypeButton(
                                    type: type,
                                    isSelected: newAccountType == type,
                                    onTap: {
                                        newAccountType = type
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Initial balance field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Initial Balance")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            
                            HStack {
                                TextField("0.00", text: $newAccountBalance)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                
                                Spacer()
                                
                                // Preview formatted currency
                                Text(formatPreviewCurrency(newAccountBalance))
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.trailing)
                            }
                        }
                        .frame(height: 60)
                    }
                    .padding(.horizontal)
                    
                    // Information about initial balance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About Initial Balance")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(viewModel.themeColor)
                                
                                Text("Initial balance is the starting amount for your account. The app will recalculate your current balance based on all transactions.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if newAccountType == .credit {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(viewModel.themeColor)
                                    
                                    Text("For credit cards, the balance represents your debt. A positive balance means you owe money to the credit card company.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(viewModel.themeColor.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Add button
                    Button(action: {
                        addNewAccount()
                        showAddAccountSheet = false
                    }) {
                        Text("Add Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : viewModel.themeColor)
                            .cornerRadius(15)
                            .shadow(color: (newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : viewModel.themeColor).opacity(0.4), radius: 5, x: 0, y: 3)
                    }
                    .disabled(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Add Account")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showAddAccountSheet = false
                }
            )
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
    
    private func addNewAccount() {
        let initialBalance = Double(newAccountBalance) ?? 0.0
        let newAccount = Account(
            name: newAccountName,
            type: newAccountType,
            initialBalance: initialBalance,
            balance: initialBalance
        )
        
        var updatedAccounts = viewModel.accounts
        updatedAccounts.append(newAccount)
        viewModel.updateAccountsSettings(updatedAccounts: updatedAccounts)
        
        // Add this account to the dictionaries
        accountNames[newAccount.id] = newAccount.name
        accountPresets[newAccount.id] = String(format: "%.2f", newAccount.initialBalance)
        accountTypes[newAccount.id] = newAccount.type
        
        // Reset the form
        newAccountName = ""
        newAccountBalance = ""
        newAccountType = .savings
    }
    
    // MARK: - Action Methods
    
    private func saveAllSettings() {
        // Save account settings
        var updatedAccounts = viewModel.accounts
        for i in 0..<updatedAccounts.count {
            let account = updatedAccounts[i]
            if let newName = accountNames[account.id] {
                updatedAccounts[i].name = newName
            }
            if let newType = accountTypes[account.id] {
                updatedAccounts[i].type = newType
            }
            if let newPresetString = accountPresets[account.id],
               let newPreset = Double(newPresetString) {
                updatedAccounts[i].initialBalance = newPreset
                
                // If initial balance changes, adjust pools proportionally if needed
                if newPreset != account.initialBalance {
                    let ratio = newPreset / account.initialBalance
                    for j in 0..<updatedAccounts[i].pools.count {
                        updatedAccounts[i].pools[j].amount *= ratio
                    }
                }
            }
        }
        viewModel.updateAccountsSettings(updatedAccounts: updatedAccounts)
        viewModel.saveUserPreferences()
        
        // Save theme color
        viewModel.updateThemeColor(newColorName: selectedTheme)
    }

    private func resetAllData() {
        // Reset accounts
        viewModel.accounts = []
        
        // Reset transactions
        viewModel.transactions = []
        
        // Reset to default theme
        viewModel.updateThemeColor(newColorName: "Blue")
    }
    
    private func exportData(format: String) {
        guard let fileURL = viewModel.exportData(format: format) else {
            // Show error
            return
        }
        
        // Present share sheet to allow user to save or share the file
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatCurrency(_ value: Double) -> String {
        return viewModel.formatCurrency(value)
    }
    
    private func formatPreviewCurrency(_ valueString: String) -> String {
        guard let value = Double(valueString) else { return viewModel.formatCurrency(0) }
        return formatCurrency(value)
    }
    
    private func getThemeColor(name: String) -> Color {
            // Match the same color calculation as in the ViewModel
            switch name {
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
                return Color(red: 0.20, green: 0.40, blue: 0.70) // Default to Darker Blue
            }
        }
    
    private func getAccountTypeDisplay(_ type: AccountType) -> String {
        switch type {
        case .savings:
            return "Savings"
        case .current:
            return "Current"
        case .credit:
            return "Credit"
        }
    }
    
    private func getAccountIcon(_ type: AccountType) -> String {
        switch type {
        case .savings: return "building.columns.fill"
        case .current: return "banknote.fill"
        case .credit: return "creditcard.fill"
        }
    }
    
    private func getAccountColor(_ type: AccountType) -> Color {
        switch type {
        case .savings: return .blue
        case .current: return .green
        case .credit: return .purple
        }
    }
    
    private func getBalanceColor(_ account: Account) -> Color {
        if account.type == .credit {
            return account.balance > 0 ? .red : .green
        } else {
            return account.balance >= 0 ? .green : .red
        }
    }
    
    // MARK: - Supporting Views
    
    struct ThemeColorButton: View {
        let colorName: String
        let isSelected: Bool
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                ZStack {
                    Circle()
                        .fill(getThemeColorPreview(name: colorName))
                        .frame(width: 40, height: 40)
                        .shadow(color: getThemeColorPreview(name: colorName).opacity(0.4), radius: 3, x: 0, y: 2)
                    
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        
        private func getThemeColorPreview(name: String) -> Color {
                    switch name {
                    case "Blue":
                        return Color(red: 0.20, green: 0.40, blue: 0.70)
                    case "Green":
                        return Color(red: 0.20, green: 0.55, blue: 0.30)
                    case "Orange":
                        return Color(red: 0.80, green: 0.40, blue: 0.20)
                    case "Purple":
                        return Color(red: 0.50, green: 0.25, blue: 0.70)
                    case "Red":
                        return Color(red: 0.70, green: 0.20, blue: 0.20)
                    case "Teal":
                        return Color(red: 0.20, green: 0.50, blue: 0.60)
                    case "Pink":
                        return Color(red: 0.90, green: 0.40, blue: 0.60)
                    default:
                        return Color(red: 0.20, green: 0.40, blue: 0.70)
                    }
                }
    }
    
    struct AccountTypeButton: View {
        let type: AccountType
        let isSelected: Bool
        let onTap: () -> Void
        
        @EnvironmentObject var viewModel: FinanceViewModel
        
        var body: some View {
            Button(action: onTap) {
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? getTypeColor(type).opacity(0.2) : Color(.systemGray5))
                            .frame(width: 100, height: 80)
                        
                        VStack(spacing: 8) {
                            Image(systemName: getTypeIcon(type))
                                .font(.system(size: 24))
                                .foregroundColor(isSelected ? getTypeColor(type) : .gray)
                            
                            Text(getTypeDisplayName(type))
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(isSelected ? getTypeColor(type) : .gray)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? getTypeColor(type) : Color.clear, lineWidth: 2)
                    )
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        private func getTypeIcon(_ type: AccountType) -> String {
            switch type {
            case .savings: return "building.columns.fill"
            case .current: return "banknote.fill"
            case .credit: return "creditcard.fill"
            }
        }
        
        private func getTypeColor(_ type: AccountType) -> Color {
            switch type {
            case .savings: return .blue
            case .current: return .green
            case .credit: return .purple
            }
        }
        
        private func getTypeDisplayName(_ type: AccountType) -> String {
            switch type {
            case .savings: return "Savings"
            case .current: return "Current"
            case .credit: return "Credit"
            }
        }
    }
}

