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
    // Removed showEditAccountSheet
    
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
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                    
                    
                    Spacer()
                    
                    Button(action: saveAllSettings) {
                        Text("Save All")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.themeColor)
                            .cornerRadius(10)
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)
                
                // Personalization section
                settingsSection(title: "Appearance", icon: "paintbrush.fill") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Theme Color")
                            .font(.headline)
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                        
                        VStack(spacing: 12) {
                            // Color preview row
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(themeOptions, id: \.self) { option in
                                        ThemeColorButton(
                                            colorName: option,
                                            isSelected: selectedTheme == option,
                                            onTap: { selectedTheme = option }
                                        )
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                            
                            // Currency picker moved here from Preferences section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Currency")
                                    .font(.headline)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                Picker("Currency", selection: $viewModel.userPreferences.currency) {
                                    ForEach(Currency.allCases, id: \.self) { currency in
                                        Text(currency.rawValue).tag(currency)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            Divider()
                            
                            // Preview card with selected theme
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Preview")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(getThemeColor(name: selectedTheme))
                                    .frame(height: 60)
                                    .overlay(
                                        HStack {
                                            Image(systemName: "creditcard.fill")
                                                .font(.title2)
                                                .scaledToFit()
                                                .frame(minWidth: 40, maxWidth: 60, minHeight: 40, maxHeight: 60)
                                                .foregroundColor(.white)
                                                .padding(.leading)
                                            
                                            Text("Theme Preview")
                                                .foregroundColor(.white)
                                                .fontWeight(.semibold)
                                                .minimumScaleFactor(0.85)
                                                .lineLimit(1)
                                            
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
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {
                                showAddAccountSheet = true
                            }) {
                                Label("Add", systemImage: "plus.circle")
                                    .foregroundColor(viewModel.themeColor)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
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
                                        .minimumScaleFactor(0.85)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 20)
                        } else {
                            // Updated to use new account cards
                            VStack(spacing: 16) {
                                ForEach(viewModel.accounts) { account in
                                    SettingsAccountCard(
                                        account: account,
                                        accountName: accountNames[account.id] ?? account.name,
                                        accountType: accountTypes[account.id] ?? account.type,
                                        accountPreset: accountPresets[account.id] ?? String(format: "%.2f", account.initialBalance),
                                        onTapEdit: {
                                            prepareEditAccount(account)
                                        },
                                        viewModel: viewModel
                                    )
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
                                    .scaledToFit()
                                    .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                                
                                Text("Manage Categories")
                                    .fontWeight(.semibold)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                
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
                        
                        // Data storage location indicator
                        HStack(spacing: 10) {
                            Image(systemName: viewModel.isUsingICloud ? "icloud.fill" : "internaldrive.fill")
                                .foregroundColor(viewModel.isUsingICloud ? .blue : .gray)
                                .font(.title3)
                                .scaledToFit()
                                .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                            Text(viewModel.isUsingICloud ? "Data stored in iCloud" : "Data stored locally")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.bottom, 6)
                        
                        // Show onboarding again button
                        Button(action: {
                            showOnboardingSheet = true
                        }) {
                            HStack {
                                Image(systemName: "rectangle.and.pencil.and.ellipsis")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(viewModel.themeColor)
                                    .cornerRadius(8)
                                
                                Text("Show Onboarding Again")
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

                        // Add test data button
                        Button(action: {
                            viewModel.generateTestData()
                            showTestDataAlert = true
                        }) {
                            HStack {
                                Image(systemName: "plus.square.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.green)
                                    .cornerRadius(8)

                                Text("Generate Test Data")
                                    .fontWeight(.semibold)

                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
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
                                    .scaledToFit()
                                    .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)

                                Text("Reset All Data")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)

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
                                    .scaledToFit()
                                    .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                                
                                Text("Import Data")
                                    .fontWeight(.semibold)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                
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
                                    .scaledToFit()
                                    .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                                
                                Text("Export Data")
                                    .fontWeight(.semibold)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                
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
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                            Spacer()
                            Text("1.0.0")
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Text("Developer")
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                            Spacer()
                            Text("Tom Speake")
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
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
                                    .scaledToFit()
                                    .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                                
                                Text("What's New / Known Issues")
                                    .fontWeight(.semibold)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
                                
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
            .frame(maxWidth: 600)
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
        // Changed sheet presentation for editing accounts to use .sheet(item:)
        .sheet(item: $editingAccount) { account in
            editAccountSheet(account: account)
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
                                    editingAccount = nil  // Dismiss the sheet after deletion
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
        
        // Set the editing account (always set to ensure sheet presents)
        editingAccount = account
        
        // No longer using showEditAccountSheet
    }
    
    private func editAccountSheet(account: Account) -> some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 28) {
                    // Header section: Icon + Balance
                    VStack(spacing: 12) {
                        ZStack {
                            // Background circle with subtle gradient
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            getAccountColor(accountTypes[account.id] ?? account.type).opacity(0.3),
                                            getAccountColor(accountTypes[account.id] ?? account.type).opacity(0.15)
                                        ]),
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 40
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: getAccountColor(accountTypes[account.id] ?? account.type).opacity(0.2), radius: 12, x: 0, y: 4)

                            Image(systemName: getAccountIcon(accountTypes[account.id] ?? account.type))
                                .font(.system(size: 38, weight: .semibold))
                                .foregroundColor(getAccountColor(accountTypes[account.id] ?? account.type))
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 4) {
                            Text("Current Balance")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            Text(formatCurrency(account.balance))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(getBalanceColor(account))
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial)
                            .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 2)
                    )
                    .padding(.horizontal, 20)
                    
                    // Account Details Card
                    CardView(title: "Account Details", icon: "person.text.rectangle") {
                        VStack(alignment: .leading, spacing: 12) {
                            InputField(
                                label: "Account Name",
                                text: Binding(
                                    get: { accountNames[account.id] ?? account.name },
                                    set: { accountNames[account.id] = $0 }
                                ),
                                placeholder: "Enter account name"
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Type Selection Card
                    CardView(title: "Account Type", icon: "list.bullet.rectangle") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                            ForEach(AccountType.allCases, id: \.self) { type in
                                AccountTypeButton(
                                    type: type,
                                    isSelected: accountTypes[account.id] ?? account.type == type,
                                    onTap: {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            accountTypes[account.id] = type
                                        }
                                    }
                                )
                                .frame(height: 85)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Starting Balance Card
                    CardView(title: "Starting Balance", icon: "dollarsign.circle") {
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Amount")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.3)
                                    
                                    TextField("0.00", text: Binding(
                                        get: { accountPresets[account.id] ?? String(format: "%.2f", account.initialBalance) },
                                        set: { accountPresets[account.id] = $0 }
                                    ))
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.quaternarySystemFill))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(getAccountColor(accountTypes[account.id] ?? account.type).opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                }
                                
                                // Currency preview
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("Preview")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.3)
                                    
                                    Text(formatPreviewCurrency(accountPresets[account.id] ?? String(format: "%.2f", account.initialBalance)))
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(getAccountColor(accountTypes[account.id] ?? account.type).opacity(0.12))
                                        )
                                        .foregroundColor(getAccountColor(accountTypes[account.id] ?? account.type))
                                        .minimumScaleFactor(0.8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Information Cards
                    VStack(spacing: 16) {
                        InfoCard(
                            icon: "info.circle.fill",
                            iconColor: viewModel.themeColor,
                            text: "Initial balance is the starting amount for your account. The app will recalculate your current balance based on all transactions."
                        )
                        
                        if (accountTypes[account.id] ?? account.type) == .credit {
                            InfoCard(
                                icon: "creditcard.fill",
                                iconColor: .orange,
                                text: "For credit cards, the balance represents your debt. A positive balance means you owe money to the credit card company."
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                saveAccountChanges()
                                editingAccount = nil
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Save Changes")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [viewModel.themeColor, viewModel.themeColor.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: viewModel.themeColor.opacity(0.3), radius: 8, x: 0, y: 4))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                accountToDelete = account.id
                                viewModel.deleteAccountAndTransactions(accountId: account.id)
                                editingAccount = nil
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Delete Account")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.red.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(ScaleButtonStyle(scale: 0.97))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .navigationTitle("Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            editingAccount = nil
                        }
                    }
                    .foregroundColor(viewModel.themeColor)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }

    // MARK: - Supporting Views

    struct CardView<Content: View>: View {
        let title: String
        let icon: String
        let content: Content
        
        init(title: String, icon: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.icon = icon
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                content
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 2)
            )
        }
    }

    struct InputField: View {
        let label: String
        @Binding var text: String
        let placeholder: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 17, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.quaternarySystemFill))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
                            )
                    )
            }
        }
    }

    struct InfoCard: View {
        let icon: String
        let iconColor: Color
        let text: String
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconColor.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(iconColor.opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }

    struct ScaleButtonStyle: ButtonStyle {
        let scale: CGFloat
        
        init(scale: CGFloat = 0.95) {
            self.scale = scale
        }
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? scale : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
                    .scaledToFit()
                    .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                Text(title)
                    .font(.headline)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)
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
        .frame(maxWidth: 600)
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
                                .frame(minWidth: 40, maxWidth: 60, minHeight: 40, maxHeight: 60)
                            
                            Image(systemName: getAccountIcon(newAccountType))
                                .font(.system(size: 36))
                                .scaledToFit()
                                .frame(minWidth: 40, maxWidth: 60, minHeight: 40, maxHeight: 60)
                                .foregroundColor(getAccountColor(newAccountType))
                        }
                        .padding(.top, 12)
                        
                        // Title
                        Text("New Account")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 8)
                    
                    // Account name field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                        
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
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                        
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
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                        
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
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(1)
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
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(viewModel.themeColor)
                                    .scaledToFit()
                                    .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                                
                                Text("Initial balance is the starting amount for your account. The app will recalculate your current balance based on all transactions.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.85)
                                    .lineLimit(3)
                            }
                            
                            if newAccountType == .credit {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(viewModel.themeColor)
                                        .scaledToFit()
                                        .frame(minWidth: 20, maxWidth: 30, minHeight: 20, maxHeight: 30)
                                    
                                    Text("For credit cards, the balance represents your debt. A positive balance means you owe money to the credit card company.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .minimumScaleFactor(0.85)
                                        .lineLimit(3)
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
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                    }
                    .disabled(newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
                .padding(.horizontal)
                .frame(maxWidth: 500)
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
                        .frame(minWidth: 40, maxWidth: 60, minHeight: 40, maxHeight: 60)
                        .shadow(color: getThemeColorPreview(name: colorName).opacity(0.4), radius: 3, x: 0, y: 2)
                    
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2)
                            .frame(minWidth: 40, maxWidth: 60, minHeight: 40, maxHeight: 60)
                        
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
                            .frame(minWidth: 80, maxWidth: 120, minHeight: 60, maxHeight: 90)
                        
                        VStack(spacing: 8) {
                            Image(systemName: getTypeIcon(type))
                                .scaledToFit()
                                .frame(minWidth: 40, maxWidth: 60, minHeight: 40, maxHeight: 60)
                                .foregroundColor(isSelected ? getTypeColor(type) : .gray)
                            
                            Text(getTypeDisplayName(type))
                                .font(.caption)
                                .fontWeight(isSelected ? .bold : .regular)
                                .foregroundColor(isSelected ? getTypeColor(type) : .gray)
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
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
    
    /// New Account Card View for Settings accounts list, styled like AccountsListView cards
    struct SettingsAccountCard: View {
        let account: Account
        let accountName: String
        let accountType: AccountType
        let accountPreset: String
        let onTapEdit: () -> Void
        @ObservedObject var viewModel: FinanceViewModel
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            Button(action: onTapEdit) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center, spacing: 16) {
                        
                        ZStack {
                            Circle()
                                .fill(getAccountColor(accountType).opacity(0.2))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: getAccountIcon(accountType))
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(getAccountColor(accountType))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(accountName)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                            
                            HStack(spacing: 8) {
                                Text(getAccountTypeDisplay(accountType))
                                    .font(.caption)
                                    .bold()
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(getAccountColor(accountType).opacity(0.15))
                                    .foregroundColor(getAccountColor(accountType))
                                    .cornerRadius(8)
                                
                                if account.pools.count > 0 {
                                    Text("\(account.pools.count) Pool\(account.pools.count > 1 ? "s" : "")")
                                        .font(.caption)
                                        .bold()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(viewModel.themeColor.opacity(0.15))
                                        .foregroundColor(viewModel.themeColor)
                                        .cornerRadius(8)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(formatCurrency(account.balance))
                                .font(.headline)
                                .foregroundColor(getBalanceColor(account))
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                            
                            Text("Initial: \(formatPreviewCurrency(accountPreset))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                        }
                    }
                }
                .padding()
                .background(
                    colorScheme == .dark
                    ? Color(UIColor.secondarySystemBackground)
                    : Color(UIColor.systemBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(
                            getAccountColor(accountType)
                                .opacity(colorScheme == .dark ? 0.4 : 0.2),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: colorScheme == .dark
                        ? Color.white.opacity(0.1)
                        : Color.black.opacity(0.06), radius: 5, x: 0, y: 3)
                .cornerRadius(15)
            }
            .buttonStyle(PlainButtonStyle())
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
        
        private func formatCurrency(_ value: Double) -> String {
            return viewModel.formatCurrency(value)
        }
        
        private func formatPreviewCurrency(_ valueString: String) -> String {
            guard let value = Double(valueString) else { return viewModel.formatCurrency(0) }
            return formatCurrency(value)
        }
    }
}

struct CurrencySelectionCard: View {
    let currency: Currency
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Currency symbol in a circle
                ZStack {
                    Circle()
                        .fill(isSelected ? getCurrencyColor().opacity(0.2) : Color(.systemGray6))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? getCurrencyColor() : Color.clear, lineWidth: 2)
                        )
                    
                    Text(currency.rawValue)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? getCurrencyColor() : .secondary)
                }
                
                // Currency name
                Text(currency.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? getCurrencyColor() : .secondary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? getCurrencyColor().opacity(0.08) : Color(.systemGray6).opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? getCurrencyColor().opacity(0.3) : Color.clear, lineWidth: 1.5)
                    )
            )
            .shadow(
                color: isSelected ? getCurrencyColor().opacity(0.2) : Color.black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func getCurrencyColor() -> Color {
        switch currency {
        case .gbp:
            return Color(red: 0.2, green: 0.4, blue: 0.8) // British Blue
        case .usd:
            return Color(red: 0.0, green: 0.5, blue: 0.3) // Dollar Green
        case .eur:
            return Color(red: 0.9, green: 0.6, blue: 0.1) // Euro Gold
        }
    }
}
