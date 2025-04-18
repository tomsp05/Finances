import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme

    
    // For editing account settings
    @State private var accountNames: [UUID: String] = [:]
    @State private var accountPresets: [UUID: String] = [:]
    @State private var accountTypes: [UUID: AccountType] = [:]
    @State private var editingAccount: Account? = nil
    @State private var showEditAccountSheet = false
    
    // Theme options
    let themeOptions = ["Blue", "Green", "Orange", "Purple", "Red", "Teal"]
    @State private var selectedTheme: String = ""
    
    // Export data option
    @State private var showingExportOptions = false
    
    // Account management
    @State private var showAddAccountSheet = false
    @State private var newAccountName = ""
    @State private var newAccountType: AccountType = .savings
    @State private var newAccountBalance = ""
    @State private var accountToDelete: UUID? = nil
    @State private var showDeleteConfirmation = false
    
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
                                    accountNames[account.id] = account.name
                                    accountPresets[account.id] = String(format: "%.2f", account.initialBalance)
                                    accountTypes[account.id] = account.type
                                    editingAccount = account
                                    showEditAccountSheet = true
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
                        
                    }
                }
                
                // Data management section
                settingsSection(title: "Data Management", icon: "externaldrive.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Button(action: { showingExportOptions = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
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
                        
                        Button(action: resetAllData) {
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
                        
                        HStack {
                            Text("Last Updated")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("April 15, 2025")
                        }
                        
                        Button(action: {
                            // Open feedback link
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(viewModel.themeColor)
                                Text("Send Feedback")
                                    .fontWeight(.medium)
                                    .foregroundColor(viewModel.themeColor)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.themeColor, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .onAppear {
            // Populate account edits
            for account in viewModel.accounts {
                accountNames[account.id] = account.name
                accountPresets[account.id] = String(format: "%.2f", account.initialBalance)
                accountTypes[account.id] = account.type
            }
            
            // Set the initial theme selection
            selectedTheme = viewModel.themeColorName
        }
        .alert(isPresented: $showingExportOptions) {
            Alert(
                title: Text("Export Data"),
                message: Text("Choose an export format:"),
                primaryButton: .default(Text("CSV")) {
                    exportData(format: "csv")
                },
                secondaryButton: .default(Text("PDF")) {
                    exportData(format: "pdf")
                }
            )
        }
        .sheet(isPresented: $showAddAccountSheet) {
            addAccountSheet
        }
        .sheet(isPresented: $showEditAccountSheet) {
            editAccountSheet
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete this account? This will not delete transactions associated with this account."),
                primaryButton: .destructive(Text("Delete")) {
                    if let id = accountToDelete {
                        deleteAccount(id: id)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Helper Views
    
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
                                    .fill(getAccountColor(account.type).opacity(0.2))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: getAccountIcon(account.type))
                                    .font(.system(size: 36))
                                    .foregroundColor(getAccountColor(account.type))
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
                                
                                if account.type == .credit {
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
                            
                            // Delete button
                            Button(action: {
                                accountToDelete = account.id
                                showEditAccountSheet = false
                                showDeleteConfirmation = true
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
        
        // Reset the form
        newAccountName = ""
        newAccountBalance = ""
        newAccountType = .savings
    }
    
    private func deleteAccount(id: UUID) {
        var updatedAccounts = viewModel.accounts
        updatedAccounts.removeAll { $0.id == id }
        viewModel.updateAccountsSettings(updatedAccounts: updatedAccounts)
        
        // Clean up references to this account
        accountNames.removeValue(forKey: id)
        accountPresets.removeValue(forKey: id)
        accountTypes.removeValue(forKey: id)
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
            }
        }
        viewModel.updateAccountsSettings(updatedAccounts: updatedAccounts)
        
        // Save theme color
        viewModel.updateThemeColor(newColorName: selectedTheme)
        
        // Show success feedback - in a real app, you would add a toast or notification here
    }
    
    private func resetAllData() {
        // This would reset all user data after confirmation
        // For a real implementation, we'd show another confirmation alert
    }
    
    private func exportData(format: String) {
        // This would handle exporting the user's data in the chosen format
        // In a real implementation, this would create the file and show a share sheet
    }
    
    // MARK: - Helper Functions
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    private func formatPreviewCurrency(_ valueString: String) -> String {
        guard let value = Double(valueString) else { return "£0.00" }
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
            default:
                return Color(red: 0.20, green: 0.40, blue: 0.70) // Default to Blue
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
