import SwiftUI

struct BudgetEditView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    
    // If budget is nil, we're creating a new budget
    var budget: Budget?
    
    // Form state
    @State private var name: String = ""
    @State private var amount: String = ""
    @State private var type: BudgetType = .overall
    @State private var timePeriod: TimePeriod = .monthly
    @State private var selectedCategoryId: UUID?
    @State private var selectedAccountId: UUID?
    @State private var startDate: Date = Date()
    
    var body: some View {
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
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        TextField("Enter name", text: $name)
                            .padding()
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                
                // Amount field
                VStack(alignment: .leading, spacing: 10) {
                    Text("Budget Amount")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        HStack {
                            Text("£")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.leading)
                            
                            TextField("0.00", text: $amount)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .medium))
                            
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                
                // Time period selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Budget Period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Picker("Time Period", selection: $timePeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.displayName()).tag(period)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                
                // Start date
                VStack(alignment: .leading, spacing: 10) {
                    Text("Start Date")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                
                // Category or account selection based on type
                if type == .category {
                    categoryPickerView
                }
                
                if type == .account {
                    accountPickerView
                }
                
                // Save button
                Button(action: {
                    saveBudget()
                    isPresented = false
                }) {
                    Text(budget == nil ? "Create Budget" : "Update Budget")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            canSave
                                ? viewModel.themeColor
                                : Color.gray
                        )
                        .cornerRadius(15)
                        .shadow(color: (canSave ? viewModel.themeColor : Color.gray).opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .disabled(!canSave)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Delete button for existing budgets
                if budget != nil {
                    Button(action: {
                        deleteBudget()
                        isPresented = false
                    }) {
                        Text("Delete Budget")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(15)
                            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                }
                
                // Extra padding at bottom
                Spacer()
                    .frame(height: 30)
            }
            .padding(.vertical, 20)
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .onAppear(perform: setupInitialValues)
        .navigationTitle(budget == nil ? "New Budget" : "Edit Budget")
    }
    
    // MARK: - Helper Views
    
    private var categoryPickerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Category")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                HStack {
                    if let categoryId = selectedCategoryId,
                       let category = viewModel.expenseCategories.first(where: { $0.id == categoryId }) {
                        // Selected category display
                        HStack {
                            Image(systemName: category.iconName)
                                .foregroundColor(.red)
                                .font(.headline)
                            
                            Text(category.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    } else {
                        // Nothing selected yet
                        HStack {
                            Text("Choose a category")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                Picker("", selection: $selectedCategoryId) {
                    Text("Select a category").tag(nil as UUID?)
                    
                    // Show expense categories
                    ForEach(viewModel.expenseCategories) { category in
                        HStack {
                            Image(systemName: category.iconName)
                            Text(category.name)
                        }
                        .tag(category.id as UUID?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
                .opacity(0.015) // Make it invisible but tappable
            }
            .frame(height: 60)
        }
        .padding(.horizontal)
    }
    
    private var accountPickerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Account")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                HStack {
                    if let accountId = selectedAccountId,
                       let account = viewModel.accounts.first(where: { $0.id == accountId }) {
                        // Selected account display
                        HStack {
                            Image(systemName: getAccountIcon(for: account.type))
                                .foregroundColor(getAccountColor(for: account.type))
                                .font(.headline)
                            
                            Text(account.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    } else {
                        // Nothing selected yet
                        HStack {
                            Text("Choose an account")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                
                Picker("", selection: $selectedAccountId) {
                    Text("Select an account").tag(nil as UUID?)
                    
                    ForEach(viewModel.accounts) { account in
                        Text(account.name).tag(account.id as UUID?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
                .opacity(0.015) // Make it invisible but tappable
            }
            .frame(height: 60)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Properties & Methods
    
    private var canSave: Bool {
        // Check that all required fields are filled
        let nameValid = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let amountValid = Double(amount) != nil && Double(amount)! > 0
        
        // For category budgets, a category must be selected
        let categoryValid = type != .category || selectedCategoryId != nil
        
        // For account budgets, an account must be selected
        let accountValid = type != .account || selectedAccountId != nil
        
        return nameValid && amountValid && categoryValid && accountValid
    }
    
    private func setupInitialValues() {
        // If editing an existing budget, populate the form
        if let existingBudget = budget {
            name = existingBudget.name
            amount = String(format: "%.2f", existingBudget.amount)
            type = existingBudget.type
            timePeriod = existingBudget.timePeriod
            selectedCategoryId = existingBudget.categoryId
            selectedAccountId = existingBudget.accountId
            startDate = existingBudget.startDate
        }
    }
    
    private func saveBudget() {
        guard let amountDouble = Double(amount), canSave else { return }
        
        // Create new budget or update existing one
        let updatedBudget = Budget(
            id: budget?.id ?? UUID(),
            name: name,
            amount: amountDouble,
            type: type,
            timePeriod: timePeriod,
            categoryId: type == .category ? selectedCategoryId : nil,
            accountId: type == .account ? selectedAccountId : nil,
            startDate: startDate,
            currentSpent: budget?.currentSpent ?? 0.0
        )
        
        if budget == nil {
            // Creating a new budget
            viewModel.addBudget(updatedBudget)
        } else {
            // Updating existing budget
            viewModel.updateBudget(updatedBudget)
        }
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func deleteBudget() {
        if let budgetToDelete = budget {
            viewModel.deleteBudget(budgetToDelete)
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
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
