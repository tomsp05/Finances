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
    
    // Split payment fields
    @State private var friendName: String = ""
    @State private var friendAmount: String = "0.00"
    @State private var userAmount: String = "0.00"
    @State private var friendPaymentDestination: String = ""
    @State private var friendPaymentAccountId: UUID? = nil
    @State private var friendPaymentIsOther: Bool = false
    
    // Recurring transaction fields
    @State private var isRecurring: Bool = false
    @State private var recurrenceInterval: RecurrenceInterval = .monthly
    @State private var recurrenceEndDate: Date = Date().addingTimeInterval(60*60*24*365) // Default 1 year
    @State private var hasEndDate: Bool = false
    
    // UI state
    @State private var currentStep: FormStep = .basicInfo
    @State private var amountBeingEdited: AmountField = .total // Track which amount is being edited
    
    // Helper properties
    private var formattedAmount: String {
        guard let amountValue = Double(amount) else { return "\(viewModel.userPreferences.currency.rawValue)0.00" }
        return viewModel.formatCurrency(amountValue)
    }
    
    // Check if split payment has data filled in
    private var isSplitPaymentFilled: Bool {
        return !friendName.isEmpty &&
               (Double(userAmount) ?? 0) > 0 &&
               (Double(friendAmount) ?? 0) > 0 &&
               (!friendPaymentIsOther || !friendPaymentDestination.isEmpty) &&
               (friendPaymentIsOther || friendPaymentAccountId != nil)
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
        case basicInfo, category, accounts, split, review
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
                    case .split:
                        splitPaymentSection
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
            
            // Default friend payment account
            if friendPaymentAccountId == nil && !viewModel.accounts.isEmpty {
                friendPaymentAccountId = viewModel.accounts[0].id
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
                                
                                // Reset split on type change
                                if type != .expense {
                                    clearSplitData()
                                }
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
                                // When changing total amount
                                amountBeingEdited = .total
                                
                                // Update split amounts maintaining proportions if possible
                                if isSplitPaymentStarted() {
                                    updateSplitAmounts()
                                }
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
                    
                    TextField("Enter description", text: $description)
                        .padding()
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
    
    // Step 4: Split Payment (only for expenses, but can be skipped)
    private var splitPaymentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if transactionType == .expense {
                
                Text("Fill this in if you're splitting the expense, or skip to the next step")
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                // Friend name input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Friend's Name")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                        
                        TextField("Friend's name", text: $friendName)
                            .padding()
                    }
                    .frame(height: 60)
                }
                
                // Split amount inputs section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Payment Distribution")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Your amount input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("You Paid")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
                            HStack {
                                Text(viewModel.userPreferences.currency.rawValue)
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                                
                                TextField("0.00", text: $userAmount)
                                    .keyboardType(.decimalPad)
                                    .onChange(of: userAmount) { newValue in
                                        amountBeingEdited = .user
                                        updateFriendAmount()
                                    }
                            }
                            .padding(.vertical)
                        }
                        .frame(height: 60)
                    }
                    
                    // Friend amount input (user can edit this one too)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(friendName.isEmpty ? "Friend" : friendName) Paid")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
                            HStack {
                                Text(viewModel.userPreferences.currency.rawValue)
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                                
                                TextField("0.00", text: $friendAmount)
                                    .keyboardType(.decimalPad)
                            }
                            .padding(.vertical)
                        }
                        .frame(height: 60)
                    }
                    
                    // Total for reference (display only)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formattedAmount)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Quick split buttons
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Split")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button(action: { splitEvenly() }) {
                            Text("50/50")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        
                        Button(action: { splitCustom(yourPercent: 70) }) {
                            Text("70/30")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        
                        Button(action: { splitCustom(yourPercent: 25) }) {
                            Text("25/75")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                        
                        Button(action: { userAmount = amount; friendAmount = "0.00" }) {
                            Text("All You")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.vertical, 4)
                
                // Split distribution visualization
                if let totalAmount = Double(amount), totalAmount > 0,
                   let yourAmount = Double(userAmount), yourAmount > 0,
                   let friendAmount = Double(friendAmount), friendAmount > 0 {
                    let yourPercent = yourAmount / (yourAmount + friendAmount)
                    let friendPercent = friendAmount / (yourAmount + friendAmount)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Split Distribution")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(yourPercent * 100))% / \(Int(friendPercent * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Visual split indicator
                        GeometryReader { geometry in
                            HStack(spacing: 2) {
                                Rectangle()
                                    .fill(viewModel.themeColor)
                                    .frame(width: geometry.size.width * CGFloat(yourPercent))
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * CGFloat(friendPercent))
                            }
                            .cornerRadius(6)
                        }
                        .frame(height: 12)
                        
                        HStack {
                            HStack {
                                Rectangle()
                                    .fill(viewModel.themeColor)
                                    .frame(width: 12, height: 12)
                                    .cornerRadius(3)
                                
                                Text("You")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack {
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: 12, height: 12)
                                    .cornerRadius(3)
                                
                                Text(friendName.isEmpty ? "Friend" : friendName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                }
                
                // Friend's payment destination - redesigned
                VStack(alignment: .leading, spacing: 10) {
                    Text("Friend's Payment Method")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Account options
                    ForEach(viewModel.accounts) { account in
                        AccountSelectionRow(
                            account: account,
                            isSelected: !friendPaymentIsOther && friendPaymentAccountId == account.id,
                            onTap: {
                                friendPaymentIsOther = false
                                friendPaymentAccountId = account.id
                            }
                        )
                    }
                    
                    // Other option
                    HStack(spacing: 16) {
                        // "Other" icon
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        
                        // Label and text field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Other")
                                .font(.headline)
                            
                            if friendPaymentIsOther {
                                TextField("Cash, etc", text: $friendPaymentDestination)
                                    .font(.subheadline)
                            } else {
                                Text("External payment method")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if friendPaymentIsOther {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(viewModel.themeColor)
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(friendPaymentIsOther ? viewModel.themeColor.opacity(0.1) : Color(.systemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(friendPaymentIsOther ? viewModel.themeColor : Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onTapGesture {
                        friendPaymentIsOther = true
                    }
                }
                
                // Clear button (to reset split data)
                Button(action: clearSplitData) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear Split Data")
                    }
                    .foregroundColor(.red)
                    .padding(.vertical, 10)
                }
                .disabled(friendName.isEmpty && (Double(userAmount) ?? 0) == 0)
                .opacity(friendName.isEmpty && (Double(userAmount) ?? 0) == 0 ? 0.5 : 1)
                
            } else {
                // For income and transfers
                Text("Split payment is only available for expenses")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // Step 5: Review
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
                
                if isSplitPaymentFilled {
                    Divider()
                    
                    HStack {
                        Text("Split with")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(friendName)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Friend paid")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formatCurrency(Double(friendAmount) ?? 0))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("You paid")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(viewModel.formatCurrency(Double(userAmount) ?? 0))
                            .fontWeight(.medium)
                    }
                    
                    if !friendPaymentIsOther, let accountId = friendPaymentAccountId,
                       let account = viewModel.accounts.first(where: { $0.id == accountId }) {
                        HStack {
                            Text("Friend paid to")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(account.name)
                                .fontWeight(.medium)
                        }
                    } else if friendPaymentIsOther && !friendPaymentDestination.isEmpty {
                        HStack {
                            Text("Friend paid via")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(friendPaymentDestination)
                                .fontWeight(.medium)
                        }
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
                currentStep = .category
            case .category:
                currentStep = .accounts
            case .accounts:
                currentStep = transactionType == .expense ? .split : .review
            case .split:
                currentStep = .review
            case .review:
                // Should never happen
                break
            }
        }
    }
    
    private func goToPreviousStep() {
        withAnimation {
            switch currentStep {
            case .basicInfo:
                // Should never happen
                break
            case .category:
                currentStep = .basicInfo
            case .accounts:
                currentStep = .category
            case .split:
                currentStep = .accounts
            case .review:
                currentStep = transactionType == .expense ? .split : .accounts
            }
        }
    }
    
    private func canMoveToNextStep() -> Bool {
        switch currentStep {
        case .basicInfo:
            return !amount.isEmpty && Double(amount) != nil
        case .category:
            return selectedCategory != nil
        case .accounts:
            if transactionType == .expense || transactionType == .transfer {
                return selectedFromAccountId != nil
            } else if transactionType == .income {
                return selectedToAccountId != nil
            }
            return false
        case .split:
            // Split page can always be skipped, no validation required to move forward
            // If there is data, validate that it's complete
            if (Double(userAmount) ?? 0) > 0 || !friendName.isEmpty || (Double(friendAmount) ?? 0) > 0 {
                // If some fields are filled, validate everything
                if !friendName.isEmpty &&
                   Double(userAmount) != nil && Double(userAmount) ?? 0 > 0 &&
                   Double(friendAmount) != nil && Double(friendAmount) ?? 0 > 0 {
                    
                    // Validate friend payment details
                    if friendPaymentIsOther {
                        return !friendPaymentDestination.isEmpty
                    } else {
                        return friendPaymentAccountId != nil
                    }
                }
                return false
            }
            // Empty split form can be skipped
            return true
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
        
        // Split validation (only if split has data)
        if isSplitPaymentStarted() {
            guard !friendName.isEmpty,
                  let friendAmountValue = Double(friendAmount), friendAmountValue > 0,
                  let userAmountValue = Double(userAmount), userAmountValue > 0 else {
                return false
            }
            
            // If using "Other" payment method, need a destination
            if friendPaymentIsOther && friendPaymentDestination.isEmpty {
                return false
            }
            
            // If not using "Other", need an account
            if !friendPaymentIsOther && friendPaymentAccountId == nil {
                return false
            }
        }
        
        return true
    }
    
    // MARK: - Split Payment Helpers
    
    private func isSplitPaymentStarted() -> Bool {
        return !friendName.isEmpty || (Double(userAmount) ?? 0) > 0 || (Double(friendAmount) ?? 0) > 0
    }
    
    // Clear all split payment data
    private func clearSplitData() {
        friendName = ""
        userAmount = "0.00"
        friendAmount = "0.00"
        friendPaymentDestination = ""
        friendPaymentIsOther = false
        // Don't clear friendPaymentAccountId as it's a useful default
    }
    
    // Update amounts based on which field was edited
    private func updateSplitAmounts() {
        switch amountBeingEdited {
        case .total:
            // Adjust both amounts proportionally if possible
            if let totalAmount = Double(amount),
               let oldUserAmount = Double(userAmount), oldUserAmount > 0,
               let oldFriendAmount = Double(friendAmount), oldFriendAmount > 0 {
                
                let oldTotal = oldUserAmount + oldFriendAmount
                let userRatio = oldUserAmount / oldTotal
                
                let newUserAmount = totalAmount * userRatio
                let newFriendAmount = totalAmount - newUserAmount
                
                userAmount = String(format: "%.2f", newUserAmount)
                friendAmount = String(format: "%.2f", newFriendAmount)
            } else {
                // If no existing split, default to even split
                splitEvenly()
            }
            
        case .user:
            updateFriendAmount()
            
        case .friend:
            updateUserAmount()
        }
    }
    
    // Update friend's amount based on user's input
    private func updateFriendAmount() {
        if let totalAmount = Double(amount), let userPaid = Double(userAmount) {
            // Friend paid the remainder of the total
            let friendPaid = max(0, totalAmount - userPaid)
            friendAmount = String(format: "%.2f", friendPaid)
        } else {
            friendAmount = "0.00"
        }
    }
    
    // Update user's amount based on friend's input
    private func updateUserAmount() {
        if let totalAmount = Double(amount), let friendPaid = Double(friendAmount) {
            // User paid the remainder of the total
            let userPaid = max(0, totalAmount - friendPaid)
            userAmount = String(format: "%.2f", userPaid)
        } else {
            userAmount = "0.00"
        }
    }
    
    private func splitEvenly() {
        if let totalAmountDouble = Double(amount) {
            let halfAmount = totalAmountDouble / 2
            userAmount = String(format: "%.2f", halfAmount)
            friendAmount = String(format: "%.2f", halfAmount)
        }
    }
    
    private func splitCustom(yourPercent: Double) {
        if let totalAmountDouble = Double(amount) {
            let yourPortion = totalAmountDouble * (yourPercent / 100)
            let friendPortion = totalAmountDouble - yourPortion
            userAmount = String(format: "%.2f", yourPortion)
            friendAmount = String(format: "%.2f", friendPortion)
        }
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
        case .split:
            return "Split Payment (Optional)"
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
            amount: isSplitPaymentFilled ? Double(userAmount) ?? 0.0 : amountValue,
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
        
        // Set split payment values if applicable
        if isSplitPaymentFilled {
            newTransaction.isSplit = true
            newTransaction.friendName = friendName
            newTransaction.friendAmount = Double(friendAmount) ?? 0.0
            newTransaction.userAmount = Double(userAmount) ?? 0.0
            newTransaction.friendPaymentDestination = friendPaymentIsOther ? friendPaymentDestination : ""
            newTransaction.friendPaymentAccountId = friendPaymentIsOther ? nil : friendPaymentAccountId
            newTransaction.friendPaymentIsAccount = !friendPaymentIsOther
        }
        
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


// Progress bar for step-by-step transaction flow (5 steps)
struct ProgressBar: View {
    var currentStep: AddTransactionView.FormStep
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
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
        case .split: return 3
        case .review: return 4
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
