import SwiftUI

struct BudgetEditView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // If budget is nil, we're creating a new budget
    let budget: Budget?
    
    // Form state
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var type: BudgetType = .overall
    @State private var timePeriod: TimePeriod = .monthly
    @State private var selectedCategoryId: UUID? = nil
    @State private var selectedAccountId: UUID? = nil
    @State private var startDate: Date = Date()
    
    // Simplified UI state
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget type selector
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget Type")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Picker("Type", selection: $type) {
                            Text("Overall").tag(BudgetType.overall)
                            Text("Category").tag(BudgetType.category)
                            Text("Account").tag(BudgetType.account)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .padding(.horizontal)
                    
                    // Budget name field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter name", text: $name)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Amount field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget Amount")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("£")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .medium))
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Time period selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget Period")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Picker("Time Period", selection: $timePeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.displayName()).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Start date
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Start Date")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(15)
                    }
                    .padding(.horizontal)
                    
                    // Category or account selection based on type
                    if type == .category {
                        simplifiedCategoryPicker
                    }
                    
                    if type == .account {
                        simplifiedAccountPicker
                    }
                    
                    // Save button - simplified
                    Button(action: {
                        saveAndDismiss()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            
                            Text(budget == nil ? "Create Budget" : "Update Budget")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(canSave ? viewModel.themeColor : Color.gray)
                        )
                    }
                    .disabled(!canSave || isLoading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Delete button - simplified for existing budgets
                    if budget != nil {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Text("Delete Budget")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.red)
                                )
                        }
                        .padding(.horizontal)
                        .alert("Delete Budget?", isPresented: $showDeleteConfirmation) {
                            Button("Cancel", role: .cancel) { }
                            Button("Delete", role: .destructive) {
                                // Direct deletion function call
                                if let budgetToDelete = budget {
                                    viewModel.deleteBudget(budgetToDelete)
                                    dismiss()
                                }
                            }
                        } message: {
                            Text("Are you sure you want to delete this budget? This action cannot be undone.")
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
            .navigationTitle(budget == nil ? "New Budget" : "Edit Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if canSave && !isLoading {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveAndDismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
    }
    
    // MARK: - Simplified Pickers
    
    private var simplifiedCategoryPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Category")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100))
                ], spacing: 12) {
                    ForEach(viewModel.expenseCategories) { category in
                        categoryButton(category)
                    }
                }
                .padding()
            }
            .frame(maxHeight: 200)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
    
    private func categoryButton(_ category: Category) -> some View {
        Button(action: {
            selectedCategoryId = category.id
        }) {
            VStack {
                Image(systemName: category.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(selectedCategoryId == category.id ? viewModel.themeColor : .gray)
                    .padding(8)
                    .background(Circle().fill(selectedCategoryId == category.id ? viewModel.themeColor.opacity(0.2) : Color.clear))
                
                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedCategoryId == category.id ? viewModel.themeColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var simplifiedAccountPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Account")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 0) {
                ForEach(viewModel.accounts) { account in
                    simplifiedAccountRow(account)
                    
                    if account.id != viewModel.accounts.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
        }
        .padding(.horizontal)
    }
    
    private func simplifiedAccountRow(_ account: Account) -> some View {
        Button(action: {
            selectedAccountId = account.id
        }) {
            HStack {
                Image(systemName: getAccountIcon(for: account.type))
                    .foregroundColor(getAccountColor(for: account.type))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .foregroundColor(.primary)
                        .font(.body)
                    
                    Text(account.type.rawValue.capitalized)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                if selectedAccountId == account.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(getAccountColor(for: account.type))
                }
            }
            .padding()
            .background(selectedAccountId == account.id ?
                        getAccountColor(for: account.type).opacity(0.1) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private var canSave: Bool {
        let nameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let amountValid = Double(amount) != nil && Double(amount)! > 0
        let categoryValid = type != .category || selectedCategoryId != nil
        let accountValid = type != .account || selectedAccountId != nil
        
        return nameValid && amountValid && categoryValid && accountValid
    }
    
    private func setupInitialValues() {
        if let existingBudget = budget {
            name = existingBudget.name
            amount = String(format: "%.2f", existingBudget.amount)
            type = existingBudget.type
            timePeriod = existingBudget.timePeriod
            selectedCategoryId = existingBudget.categoryId
            selectedAccountId = existingBudget.accountId
            startDate = existingBudget.startDate
        } else {
            // Set defaults for new budget
            name = ""
            amount = ""
            type = .overall
            timePeriod = .monthly
            selectedCategoryId = nil
            selectedAccountId = nil
            startDate = Date()
        }
    }
    
    // Simplified save method
    private func saveAndDismiss() {
        guard let amountDouble = Double(amount), canSave else { return }
        
        isLoading = true
        
        let updatedBudget = Budget(
            id: budget?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amountDouble,
            type: type,
            timePeriod: timePeriod,
            categoryId: type == .category ? selectedCategoryId : nil,
            accountId: type == .account ? selectedAccountId : nil,
            startDate: startDate,
            currentSpent: budget?.currentSpent ?? 0.0
        )
        
        // Add a small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if budget == nil {
                viewModel.addBudget(updatedBudget)
            } else {
                viewModel.updateBudget(updatedBudget)
            }
            
            // Force haptic feedback
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            isLoading = false
            dismiss()
        }
    }
    
    // Helper functions for account icons and colors
    private func getAccountIcon(for accountType: AccountType) -> String {
        switch accountType {
        case .savings: return "banknote"
        case .current: return "creditcard"
        case .credit: return "creditcard.fill"
        }
    }
    
    private func getAccountColor(for accountType: AccountType) -> Color {
        switch accountType {
        case .savings: return .green
        case .current: return .blue
        case .credit: return .purple
        }
    }
}
