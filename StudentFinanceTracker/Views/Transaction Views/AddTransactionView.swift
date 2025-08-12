import SwiftUI

struct AddTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme

    
    // Transaction fields
    @State private var amount: String = ""
    @State private var description: String = ""
    @State private var date: Date = Date()
    @State private var transactionType: TransactionType = .expense
    @State private var selectedFromAccount: AccountType? = nil
    @State private var selectedFromAccountId: UUID? = nil
    @State private var selectedToAccount: AccountType? = nil
    @State private var selectedToAccountId: UUID? = nil
    @State private var selectedCategory: UUID? = nil
    
    // Recurring transaction fields
    @State private var isRecurring: Bool = false
    @State private var recurrenceInterval: RecurrenceInterval = .monthly
    @State private var recurrenceEndDate: Date = Date().addingTimeInterval(60*60*24*365) // Default 1 year
    @State private var hasEndDate: Bool = false
    
    // UI state
    @State private var currentStep: FormStep = .basicInfo
    @State private var amountBeingEdited: AmountField = .total // Track which amount is being edited
    
    // Warning state for description field
    @State private var showDescriptionWarning: Bool = false
    
    // Helper properties
    private var formattedAmount: String {
        guard let amountValue = Double(amount) else { return "\(viewModel.userPreferences.currency.rawValue)0.00" }
        return viewModel.formatCurrency(amountValue)
    }
    
    // Filtered categories based on transaction type
    private var filteredCategories: [Category] {
        switch transactionType {
        case .income:
            return viewModel.incomeCategories
        case .expense, .transfer:
            return viewModel.expenseCategories
        }
    }
    
    // Form steps enum
    enum FormStep {
        case basicInfo, category, accounts, review
    }
    
    // Which amount field is being edited
    enum AmountField {
        case total, user, friend
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Dynamic content based on current step
                    switch currentStep {
                    case .basicInfo:
                        basicInfoSection
                    case .category:
                        categorySection
                    case .accounts:
                        accountsSection
                    case .review:
                        reviewSection
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            
            // Bottom navigation area with progress bar and buttons
            bottomNavArea
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .navigationTitle(getNavigationTitle())
        .onAppear {
            // Default selections if needed
            if selectedFromAccountId == nil && !viewModel.accounts.isEmpty {
                selectedFromAccountId = viewModel.accounts[0].id
                selectedFromAccount = viewModel.accounts[0].type
            }
            
            if selectedToAccountId == nil && !viewModel.accounts.isEmpty {
                selectedToAccountId = viewModel.accounts[0].id
                selectedToAccount = viewModel.accounts[0].type
            }
        }
    }
    
    // MARK: - Form Sections
    
    // Step 1: Basic Info
    private var basicInfoSection: some View {
        VStack(spacing: 20) {
            // Transaction type selector
            VStack(alignment: .leading, spacing: 10) {
                Text("")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        TypeButton(
                            title: type.rawValue.capitalisedFirstLetter(),
                            isSelected: transactionType == type,
                            action: {
                                transactionType = type
                                selectedCategory = nil
                            }
                        )
                    }
                }
            }
            
            // Amount entry with preview
            VStack(alignment: .leading, spacing: 10) {
                Text("")
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        Text(viewModel.userPreferences.currency.rawValue)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.leading)
                        
                        TextField("0.00", text: $amount)
                            .font(.system(size: 24, weight: .bold))
                            .keyboardType(.decimalPad)
                            .onChange(of: amount) { newValue in
                                amountBeingEdited = .total
                            }
                    }
                    .padding(.vertical)
                    .padding(.trailing)
                }
                .frame(height: 60)
            }
            
            // Description field
            VStack(alignment: .leading, spacing: 10) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.red, lineWidth: 2)
                                .opacity(showDescriptionWarning && description.isEmpty ? 1 : 0)
                        )
                    
                    TextField("Enter description", text: $description)
                        .padding()
                        .onChange(of: description) { newValue in
                            if !newValue.isEmpty {
                                showDescriptionWarning = false
                            }
                        }
                }
                .frame(height: 60)
            }
            
            // Date picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Date")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                    
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .padding()
                }
                .frame(height: 60)
            }
            
            // Recurring toggle (moved from separate page)
            if transactionType != .transfer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recurring")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Recurring Transaction", isOn: $isRecurring)
                                .padding(.vertical, 5)
                            
                            if isRecurring {
                                Divider()
                                
                                HStack {
                                    Text("Repeat")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("", selection: $recurrenceInterval) {
                                        ForEach(RecurrenceInterval.allCases.filter { $0 != .none }, id: \.self) { interval in
                                            Text(interval.description).tag(interval)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                                .padding(.vertical, 5)
                                
                                Toggle("End Date", isOn: $hasEndDate)
                                    .padding(.vertical, 5)
                                
                                if hasEndDate {
                                    DatePicker(
                                        "Ends On",
                                        selection: $recurrenceEndDate,
                                        in: date...,
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(CompactDatePickerStyle())
                                }
                            }
                        }
                        .padding()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // Step 2: Category Selection
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("Choose a category for your \(transactionType.rawValue)")
                .foregroundColor(.secondary)
            
            if filteredCategories.isEmpty {
                emptyStateView(message: "No categories found. Add categories in Settings.")
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredCategories) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category.id,
                            onTap: {
                                selectedCategory = category.id
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // Step 3: Accounts
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if viewModel.accounts.isEmpty {
                emptyStateView(message: "No accounts found. Add accounts in Settings.")
            } else {
                if transactionType == .expense || transactionType == .transfer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("From Account")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ForEach(getFromAccounts()) { account in
                            AccountSelectionRow(
                                account: account,
                                isSelected: selectedFromAccountId == account.id,
                                onTap: {
                                    selectedFromAccountId = account.id
                                    selectedFromAccount = account.type
                                }
                            )
                        }
                    }
                }
                
                if transactionType == .income || transactionType == .transfer {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("To Account")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.accounts) { account in
                            AccountSelectionRow(
                                account: account,
                                isSelected: selectedToAccountId == account.id,
                                onTap: {
                                    selectedToAccountId = account.id
                                    selectedToAccount = account.type
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Step 4: Review
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Review Transaction")
                .font(.title2)
                .fontWeight(.bold)
            
            // Card container with transaction summary
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Type")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(transactionType.rawValue.capitalisedFirstLetter())
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Amount")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formattedAmount)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Description")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(description.isEmpty ? "No description" : description)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("Date")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(dateFormatter.string(from: date))
                        .fontWeight(.medium)
                }
                
                if let category = viewModel.getCategory(id: selectedCategory ?? UUID()) {
                    Divider()
                    
                    HStack {
                        Text("Category")
                            .foregroundColor(.secondary)
                        Spacer()
                        HStack {
                            Image(systemName: category.iconName)
                                .foregroundColor(getCategoryColor(category))
                            Text(category.name)
                                .fontWeight(.medium)
                        }
                    }
                }
                
                if transactionType == .expense || transactionType == .transfer,
                   let fromAccountId = selectedFromAccountId,
                   let account = viewModel.accounts.first(where: { $0.id == fromAccountId }) {
                    Divider()
                    
                    HStack {
                        Text("From Account")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(account.name)
                            .fontWeight(.medium)
                    }
                }
                
                if transactionType == .income || transactionType == .transfer,
                   let toAccountId = selectedToAccountId,
                   let account = viewModel.accounts.first(where: { $0.id == toAccountId }) {
                    Divider()
                    
                    HStack {
                        Text("To Account")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(account.name)
                            .fontWeight(.medium)
                    }
                }
                
                if isRecurring {
                    Divider()
                    
                    HStack {
                        Text("Recurring")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(recurrenceInterval.description)
                            .fontWeight(.medium)
                    }
                    
                    if hasEndDate {
                        HStack {
                            Text("Ends on")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(dateFormatter.string(from: recurrenceEndDate))
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
            
            // Add Transaction Button
            Button(action: saveTransaction) {
                HStack {
                    Spacer()
                    Text("Add Transaction")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(isFormValid() ? viewModel.themeColor : Color.gray)
                .cornerRadius(15)
                .shadow(color: (isFormValid() ? viewModel.themeColor : Color.gray).opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .disabled(!isFormValid())
            .padding(.top, 20)
        }
    }
    
    // Bottom navigation area with progress bar and buttons
    private var bottomNavArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Updated progress bar and navigation buttons
            HStack(spacing: 16) {
                // Back button (styled nicer)
                if currentStep != .basicInfo {
                    Button(action: goToPreviousStep) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(10)
                        .foregroundColor(viewModel.themeColor)
                    }
                } else {
                    // Placeholder for alignment
                    Spacer()
                        .frame(width: 85)
                }
                
                // Progress bar (moved from top to bottom)
                ProgressBar(currentStep: currentStep)
                    .frame(maxWidth: .infinity)
                
                // Next/Done button (styled nicer)
                if currentStep != .review {
                    Button(action: goToNextStep) {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(canMoveToNextStep() ? viewModel.themeColor.opacity(0.9) : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                    .disabled(!canMoveToNextStep())
                } else {
                    // Button to add transaction
                    Button(action: saveTransaction) {
                        HStack {
                            Text("Save")
                            Image(systemName: "checkmark")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(isFormValid() ? viewModel.themeColor.opacity(0.9) : Color.gray.opacity(0.3))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    }
                    .disabled(!isFormValid())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        }
    }
    
    // MARK: - Helper Views
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Navigation Logic
    
    private func goToNextStep() {
        withAnimation {
            switch currentStep {
            case .basicInfo:
                if description.isEmpty {
                    showDescriptionWarning = true
                    return
                }
                currentStep = .category
            case .category:
                currentStep = .accounts
            case .accounts:
                currentStep = .review
            case .review:
                break
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation {
            switch currentStep {
            case .basicInfo:
                break
            case .category:
                currentStep = .basicInfo
            case .accounts:
                currentStep = .category
            case .review:
                currentStep = .accounts
            }
        }
    }
    
    private func canMoveToNextStep() -> Bool {
        switch currentStep {
        case .basicInfo:
            return !amount.isEmpty && Double(amount) != nil && !description.isEmpty
        case .category:
            return selectedCategory != nil
        case .accounts:
            if transactionType == .expense || transactionType == .transfer {
                return selectedFromAccountId != nil
            } else if transactionType == .income {
                return selectedToAccountId != nil
            }
            return false
        case .review:
            return isFormValid()
        }
    }
    
    private func isFormValid() -> Bool {
        // Basic validation
        guard !amount.isEmpty, let _ = Double(amount),
              !description.isEmpty,
              selectedCategory != nil else {
            return false
        }
        
        // Account validation
        if (transactionType == .expense || transactionType == .transfer) && selectedFromAccountId == nil {
            return false
        }
        
        if (transactionType == .income || transactionType == .transfer) && selectedToAccountId == nil {
            return false
        }
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private func getNavigationTitle() -> String {
        switch currentStep {
        case .basicInfo:
            return "Add Transaction"
        case .category:
            return "Select Category"
        case .accounts:
            return "Select Accounts"
        case .review:
            return "Review"
        }
    }
    
    private func getFromAccounts() -> [Account] {
        if transactionType == .transfer {
            // For transfers, filter out credit cards for "From" account
            return viewModel.accounts.filter { $0.type != .credit }
        } else {
            // For expenses, show all accounts
            return viewModel.accounts
        }
    }
    
    private func getCategoryColor(_ category: Category) -> Color {
        return category.type == .income ? .green : .red
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // MARK: - Action Methods
    
    private func saveTransaction() {
        // Convert amount to Double
        guard let amountValue = Double(amount) else { return }
        
        var newTransaction = Transaction(
            date: date,
            amount: amountValue,
            description: description,
            fromAccount: transactionType == .income ? nil : selectedFromAccount,
            toAccount: transactionType == .expense ? nil : selectedToAccount,
            fromAccountId: selectedFromAccountId,
            toAccountId: selectedToAccountId,
            type: transactionType,
            categoryId: selectedCategory ?? (transactionType == .income ?
                             viewModel.incomeCategories[0].id :
                             viewModel.expenseCategories[0].id)
        )
        
        // Set recurring values (removed future transaction toggle)
        newTransaction.isFutureTransaction = date > Date() // Simply use date comparison
        newTransaction.isRecurring = isRecurring
        newTransaction.recurrenceInterval = isRecurring ? recurrenceInterval : .none
        newTransaction.recurrenceEndDate = hasEndDate ? recurrenceEndDate : nil
        
        // Add the transaction to the view model
        viewModel.addTransaction(newTransaction)
        
        // Generate recurring transactions if needed
        if isRecurring {
            viewModel.generateRecurringTransactions(from: newTransaction)
        }
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}


// Progress bar for step-by-step transaction flow (4 steps)
struct ProgressBar: View {
    var currentStep: AddTransactionView.FormStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                let stepCompleted = stepValue(for: currentStep) > index
                let isCurrentStep = stepValue(for: currentStep) == index
                
                Circle()
                    .fill(
                        stepCompleted || isCurrentStep
                            ? Color.blue
                            : Color.gray.opacity(0.3)
                    )
                    .frame(width: isCurrentStep ? 12 : 8, height: isCurrentStep ? 12 : 8)
                    .overlay(
                        Circle()
                            .stroke(isCurrentStep ? Color.blue : Color.clear, lineWidth: 2)
                            .scaleEffect(1.5)
                    )
            }
        }
    }
    
    private func stepValue(for step: AddTransactionView.FormStep) -> Int {
        switch step {
        case .basicInfo: return 0
        case .category: return 1
        case .accounts: return 2
        case .review: return 3
        }
    }
}

// Type selection button (Income, Expense, Transfer)
struct TypeButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    @EnvironmentObject var viewModel: FinanceViewModel
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? viewModel.themeColor : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Category selection button with icon
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject var viewModel: FinanceViewModel
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              (category.type == .income ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) :
                              Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ?
                                        (category.type == .income ? .green : .red) :
                                        .gray)
                }
                
                Text(category.name)
                    .font(.callout)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
            .frame(width: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          (category.type == .income ? Color.green.opacity(0.1) : Color.red.opacity(0.1)) :
                          Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ?
                            (category.type == .income ? Color.green : Color.red) :
                            Color.clear,
                            lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Account selection row with details
struct AccountSelectionRow: View {
    let account: Account
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject var viewModel: FinanceViewModel
    
    var body: some View {
        Button(action: onTap) {
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
                    
                    Text(viewModel.formatCurrency(account.balance))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(viewModel.themeColor)
                        .font(.title3)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? viewModel.themeColor.opacity(0.1) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? viewModel.themeColor : Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Helper functions
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
}

