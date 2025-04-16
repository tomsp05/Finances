import SwiftUI

struct EditTransactionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: FinanceViewModel
    
    let transaction: Transaction
    
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
    
    // Future and recurring transaction fields
    @State private var isFutureTransaction: Bool = false
    @State private var isRecurring: Bool = false
    @State private var recurrenceInterval: RecurrenceInterval = .monthly
    @State private var recurrenceEndDate: Date = Date().addingTimeInterval(60*60*24*365) // Default 1 year
    @State private var hasEndDate: Bool = false
    @State private var updateAllFutureInstances: Bool = false
    @State private var deleteAllFutureInstances: Bool = false
    
    // UI state
    @State private var expandedSection: ExpandableSection? = .basicInfo
    @State private var showDeleteAlert: Bool = false
    
    // For recurring series management
    private var isRecurringSeries: Bool {
        transaction.isRecurring && transaction.parentTransactionId == nil
    }
    
    // Enum for collapsible sections
    enum ExpandableSection: String, CaseIterable {
        case basicInfo = "Basic Details"
        case category = "Category"
        case accounts = "Accounts"
        case recurring = "Timing Options"
    }
    
    // Filtered categories based on transaction type
    private var filteredCategories: [Category] {
        viewModel.getCategoriesForTransactionType(transactionType)
    }
    
    // Helper properties
    private var formattedAmount: String {
        guard let amountValue = Double(amount) else { return "£0.00" }
        return formatCurrency(amountValue)
    }
    
    init(transaction: Transaction) {
        self.transaction = transaction
        
        // Initialize state variables based on the transaction
        _date = State(initialValue: transaction.date)
        _amount = State(initialValue: String(format: "%.2f", transaction.isSplit ? transaction.totalAmount : transaction.amount))
        _description = State(initialValue: transaction.description)
        _transactionType = State(initialValue: transaction.type)
        _selectedCategory = State(initialValue: transaction.categoryId)
        _selectedFromAccountId = State(initialValue: transaction.fromAccountId)
        _selectedToAccountId = State(initialValue: transaction.toAccountId)
        _selectedFromAccount = State(initialValue: transaction.fromAccount)
        _selectedToAccount = State(initialValue: transaction.toAccount)
        
        // Future and recurring variables
        _isFutureTransaction = State(initialValue: transaction.isFutureTransaction)
        _isRecurring = State(initialValue: transaction.isRecurring)
        _recurrenceInterval = State(initialValue: transaction.recurrenceInterval != .none ? transaction.recurrenceInterval : .monthly)
        
        // Handle end date
        if let endDate = transaction.recurrenceEndDate {
            _hasEndDate = State(initialValue: true)
            _recurrenceEndDate = State(initialValue: endDate)
        } else {
            _hasEndDate = State(initialValue: false)
            _recurrenceEndDate = State(initialValue: Date().addingTimeInterval(60*60*24*365))
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Transaction summary header
                transactionHeader
                
                // Expandable sections
                ForEach(ExpandableSection.allCases, id: \.self) { section in
                    expandableSection(section)
                }
                
                // Action buttons
                actionButtons
            }
            .padding()
            .padding(.bottom, 30)
        }
        .navigationTitle("Edit Transaction")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Transaction"),
                message: isRecurringSeries ?
                    Text("Do you want to delete just this transaction or all future occurrences of this recurring transaction?") :
                    Text("Are you sure you want to delete this transaction?"),
                primaryButton: .destructive(Text(isRecurringSeries ? "Delete All" : "Delete")) {
                    if isRecurringSeries {
                        deleteTransaction(deleteAllFutureInstances: true)
                    } else {
                        deleteTransaction(deleteAllFutureInstances: false)
                    }
                },
                secondaryButton: isRecurringSeries ?
                    .cancel(Text("Delete Only This One")) {
                        deleteTransaction(deleteAllFutureInstances: false)
                    } : .cancel()
            )
        }
    }
    
    // MARK: - UI Components
    
    // Transaction summary header
    private var transactionHeader: some View {
        VStack(spacing: 8) {
            // Transaction type badge
            Text(transactionType.rawValue.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(transactionTypeColor.opacity(0.2))
                .foregroundColor(transactionTypeColor)
                .cornerRadius(15)
            
            // Amount
            Text(formattedAmount)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(transactionTypeColor)
            
            // Description
            Text(description)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Date
            Text(dateFormatter.string(from: date))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            // Badges for special transaction types
            if isFutureTransaction || isRecurring {
                HStack(spacing: 10) {
                    if isFutureTransaction {
                        badge(label: "FUTURE", color: .blue)
                    }
                    
                    if isRecurring {
                        badge(label: recurrenceInterval.description.uppercased(), color: .purple)
                    }
                }
                .padding(.top, 8)
            }
            
            // Split payment indicator if transaction is split
            if transaction.isSplit {
                badge(label: "SPLIT PAYMENT", color: .orange)
                    .padding(.top, 4)
                Text("Edit not available for split payments")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Category badge
            if let category = viewModel.getCategory(id: selectedCategory ?? UUID()) {
                HStack(spacing: 6) {
                    Image(systemName: category.iconName)
                    Text(category.name)
                }
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    category.type == .income ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
                )
                .foregroundColor(category.type == .income ? .green : .red)
                .cornerRadius(15)
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Expandable section container
    private func expandableSection(_ section: ExpandableSection) -> some View {
        VStack(spacing: 0) {
            // Section header button
            Button(action: {
                withAnimation {
                    expandedSection = expandedSection == section ? nil : section
                }
            }) {
                HStack {
                    Text(section.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(expandedSection == section ? 15 : 15)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(transaction.isSplit) // Disable editing for split transactions
            
            // Section content
            if expandedSection == section {
                VStack(spacing: 16) {
                    // Content based on section type
                    switch section {
                    case .basicInfo:
                        basicInfoContent
                    case .category:
                        categoryContent
                    case .accounts:
                        accountsContent
                    case .recurring:
                        recurringContent
                    }
                    
                    // Save button for the section
                    Button(action: {
                        withAnimation {
                            saveTransaction()
                            expandedSection = nil
                        }
                    }) {
                        Text("Save Changes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.themeColor)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color(.systemBackground).opacity(0.5))
                .cornerRadius(15)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Basic info section content
    private var basicInfoContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Transaction type selector
            VStack(alignment: .leading, spacing: 10) {
                Text("Transaction Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        TypeButton(
                            title: type.rawValue.capitalisedFirstLetter(),
                            isSelected: transactionType == type,
                            action: {
                                transactionType = type
                                
                                // Disable recurring for transfers
                                if type == .transfer {
                                    isRecurring = false
                                }
                            }
                        )
                    }
                }
            }
            
            // Amount entry
            VStack(alignment: .leading, spacing: 10) {
                Text("Amount")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("£")
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $amount)
                        .font(.headline)
                        .keyboardType(.decimalPad)
                    
                    Spacer()
                    
                    Text(formattedAmount)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            
            // Description entry
            VStack(alignment: .leading, spacing: 10) {
                Text("Description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter description", text: $description)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            // Date picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Date")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
        }
    }
    
    // Category selection content
    private var categoryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Category")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if filteredCategories.isEmpty {
                Text("No categories found for this transaction type")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
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
            }
        }
    }
    
    // Accounts selection content
    private var accountsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if transactionType == .expense || transactionType == .transfer {
                VStack(alignment: .leading, spacing: 10) {
                    Text("From Account")
                        .font(.subheadline)
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
                        .font(.subheadline)
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
    
    // Recurring options content
    private var recurringContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Future transaction toggle
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Future Transaction", isOn: $isFutureTransaction)
                    .padding(.bottom, 5)
                
                if isFutureTransaction {
                    DatePicker(
                        "Future Date",
                        selection: $date,
                        in: Date()...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            
            // Only show recurring options for income and expense
            if transactionType != .transfer {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Recurring Transaction", isOn: $isRecurring)
                        .padding(.bottom, 5)
                    
                    if isRecurring {
                        // Recurrence interval picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("", selection: $recurrenceInterval) {
                                ForEach(RecurrenceInterval.allCases.filter { $0 != .none }, id: \.self) { interval in
                                    Text(interval.description).tag(interval)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        
                        // End date toggle and picker
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("End Date", isOn: $hasEndDate)
                                .padding(.bottom, 5)
                            
                            if hasEndDate {
                                DatePicker(
                                    "Ends On",
                                    selection: $recurrenceEndDate,
                                    in: date...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        
                        // For parent recurring transactions
                        if isRecurringSeries {
                            Divider()
                            
                            Toggle("Update All Future Occurrences", isOn: $updateAllFutureInstances)
                                .padding(.vertical, 5)
                        }
                    }
                }
            } else {
                Text("Recurring options not available for transfers")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            }
        }
    }
    
    // Action buttons at the bottom
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Delete button
            Button(action: {
                showDeleteAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .font(.headline)
                    Text("Delete Transaction")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper Views
    
    // Badge for transaction types
    private func badge(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
    
    // MARK: - Helper Methods
    
    private var transactionTypeColor: Color {
        switch transactionType {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // MARK: - Action Methods
    
    private func saveTransaction() {
        guard let categoryId = selectedCategory else { return }
        
        // If this is a split transaction, prevent editing certain fields
        if transaction.isSplit {
            // Only allow editing description, date, category for split transactions
            var updatedTransaction = transaction
            updatedTransaction.description = description
            updatedTransaction.date = date
            updatedTransaction.categoryId = categoryId
            updatedTransaction.isFutureTransaction = isFutureTransaction
            updatedTransaction.isRecurring = isRecurring
            updatedTransaction.recurrenceInterval = isRecurring ? recurrenceInterval : .none
            updatedTransaction.recurrenceEndDate = hasEndDate ? recurrenceEndDate : nil
            
            viewModel.updateTransaction(updatedTransaction)
            return
        }
        
        // Get account types based on selected account IDs
        let fromAccount = selectedFromAccountId != nil ?
            viewModel.accounts.first(where: { $0.id == selectedFromAccountId })?.type : nil
        
        let toAccount = selectedToAccountId != nil ?
            viewModel.accounts.first(where: { $0.id == selectedToAccountId })?.type : nil
        
        // Determine the transaction amount
        let transactionAmount = Double(amount) ?? 0.0
        
        var updatedTransaction = Transaction(
            id: transaction.id,
            date: date,
            amount: transactionAmount,
            description: description,
            fromAccount: (transactionType == .expense || transactionType == .transfer) ? fromAccount : nil,
            toAccount: (transactionType == .income || transactionType == .transfer) ? toAccount : nil,
            fromAccountId: (transactionType == .expense || transactionType == .transfer) ? selectedFromAccountId : nil,
            toAccountId: (transactionType == .income || transactionType == .transfer) ? selectedToAccountId : nil,
            type: transactionType,
            categoryId: categoryId
        )
        
        // Preserve split payment data if the transaction was already split
        // but don't allow changing split status or details
        if transaction.isSplit {
            updatedTransaction.isSplit = transaction.isSplit
            updatedTransaction.friendName = transaction.friendName
            updatedTransaction.friendAmount = transaction.friendAmount
            updatedTransaction.userAmount = transaction.userAmount
            updatedTransaction.friendPaymentDestination = transaction.friendPaymentDestination
            updatedTransaction.friendPaymentAccountId = transaction.friendPaymentAccountId
            updatedTransaction.friendPaymentIsAccount = transaction.friendPaymentIsAccount
        }
        
        // Set future and recurring properties
        updatedTransaction.isFutureTransaction = isFutureTransaction
        updatedTransaction.isRecurring = isRecurring
        updatedTransaction.recurrenceInterval = isRecurring ? recurrenceInterval : .none
        updatedTransaction.recurrenceEndDate = hasEndDate ? recurrenceEndDate : nil
        updatedTransaction.parentTransactionId = transaction.parentTransactionId
        
        // Update transaction(s)
        if updateAllFutureInstances && isRecurringSeries {
            // Update this transaction and all future instances
            viewModel.updateRecurringTransaction(updatedTransaction)
        } else {
            // Just update this single transaction
            viewModel.updateTransaction(updatedTransaction)
        }
        
        // Add haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func deleteTransaction(deleteAllFutureInstances: Bool) {
        // First provide haptic feedback before deleting
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        if isRecurringSeries && deleteAllFutureInstances {
            // Delete this transaction and all future instances
            viewModel.deleteRecurringTransaction(transaction, deleteAllFutureInstances: true)
        } else if let index = viewModel.transactions.firstIndex(where: { $0.id == transaction.id }) {
            // Just delete this single transaction
            viewModel.deleteTransaction(at: IndexSet(integer: index))
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    // Helper function to format currency
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
}

extension String {
    /// Capitalises the first letter of a string.
    func capitalisedFirstLetter() -> String {
        guard let first = self.first else { return self }
        return String(first).uppercased() + self.dropFirst()
    }
}
