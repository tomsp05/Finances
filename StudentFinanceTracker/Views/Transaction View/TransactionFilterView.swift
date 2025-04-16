import SwiftUI

struct TransactionFilterView: View {
    @Binding var filterState: TransactionFilterState
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.dismiss) var dismiss
    
    // Temporary state for editing amount values
    @State private var minAmountString: String = ""
    @State private var maxAmountString: String = ""
    
    init(filterState: Binding<TransactionFilterState>) {
        self._filterState = filterState
        
        // Initialize text fields with current values
        if let minAmount = filterState.wrappedValue.minAmount {
            self._minAmountString = State(initialValue: String(format: "%.2f", minAmount))
        }
        if let maxAmount = filterState.wrappedValue.maxAmount {
            self._maxAmountString = State(initialValue: String(format: "%.2f", maxAmount))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time period filter
                VStack(alignment: .leading, spacing: 10) {
                    Text("Time Period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Time filter options
                    VStack(spacing: 12) {
                        ForEach(TransactionTimeFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                filterState.timeFilter = filter
                                
                                // If selecting custom, initialize the date range
                                if filter == .custom && filterState.customStartDate == nil {
                                    filterState.customStartDate = Date().addingTimeInterval(-60*60*24*30) // 30 days ago
                                    filterState.customEndDate = Date()
                                }
                            }) {
                                HStack {
                                    Image(systemName: filter.systemImage)
                                        .foregroundColor(viewModel.themeColor)
                                        .frame(width: 24)
                                    
                                    Text(filter.rawValue)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if filterState.timeFilter == filter {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(viewModel.themeColor)
                                            .font(.headline)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(filterState.timeFilter == filter ?
                                              viewModel.themeColor.opacity(0.1) : Color(.systemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(filterState.timeFilter == filter ?
                                                viewModel.themeColor : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Custom date range (only shown when custom is selected)
                if filterState.timeFilter == .custom {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom Date Range")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        // Start Date
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
                            DatePicker("Start Date", selection: Binding(
                                get: { self.filterState.customStartDate ?? Date() },
                                set: { self.filterState.customStartDate = $0 }
                            ), displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                        }
                        .frame(height: 60)
                        
                        // End Date
                        ZStack {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
                            DatePicker("End Date", selection: Binding(
                                get: { self.filterState.customEndDate ?? Date() },
                                set: { self.filterState.customEndDate = $0 }
                            ), displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                        }
                        .frame(height: 60)
                    }
                }
                
                // Transaction type filter
                VStack(alignment: .leading, spacing: 10) {
                    Text("Transaction Type")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            TypeFilterButton(
                                title: type.rawValue.capitalized,
                                isSelected: filterState.transactionTypes.contains(type),
                                action: {
                                    if filterState.transactionTypes.contains(type) {
                                        filterState.transactionTypes.remove(type)
                                    } else {
                                        filterState.transactionTypes.insert(type)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Category filter
                VStack(alignment: .leading, spacing: 10) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    NavigationLink(destination: CategoryFilterView(selectedCategories: $filterState.selectedCategories)) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
                            HStack {
                                Image(systemName: "tag")
                                    .foregroundColor(viewModel.themeColor)
                                    .padding(.leading)
                                
                                Text(!filterState.selectedCategories.isEmpty ?
                                     "\(filterState.selectedCategories.count) categories selected" :
                                     "Select categories")
                                    .foregroundColor(!filterState.selectedCategories.isEmpty ? .primary : .secondary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .padding(.trailing)
                            }
                            .padding(.vertical)
                        }
                        .frame(height: 60)
                    }
                }
                
                // Amount filter
                VStack(alignment: .leading, spacing: 10) {
                    Text("Amount Range")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    // Min Amount
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                        
                        HStack {
                            Text("Minimum")
                                .foregroundColor(.secondary)
                                .padding(.leading)
                            
                            Spacer()
                            
                            Text("£")
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: $minAmountString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onChange(of: minAmountString) { newValue in
                                    if let amount = Double(newValue) {
                                        filterState.minAmount = amount
                                    } else if newValue.isEmpty {
                                        filterState.minAmount = nil
                                    }
                                }
                                .padding(.trailing)
                        }
                        .padding(.vertical)
                    }
                    .frame(height: 60)
                    
                    // Max Amount
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                        
                        HStack {
                            Text("Maximum")
                                .foregroundColor(.secondary)
                                .padding(.leading)
                            
                            Spacer()
                            
                            Text("£")
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", text: $maxAmountString)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                                .onChange(of: maxAmountString) { newValue in
                                    if let amount = Double(newValue) {
                                        filterState.maxAmount = amount
                                    } else if newValue.isEmpty {
                                        filterState.maxAmount = nil
                                    }
                                }
                                .padding(.trailing)
                        }
                        .padding(.vertical)
                    }
                    .frame(height: 60)
                }
                
                // Recurring filter
                VStack(alignment: .leading, spacing: 10) {
                    Text("Other Filters")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                        
                        Toggle("Only Show Recurring Transactions", isOn: $filterState.onlyRecurring)
                            .toggleStyle(SwitchToggleStyle(tint: viewModel.themeColor))
                            .padding()
                    }
                    .frame(height: 60)
                }
                
                // Apply and Reset buttons
                HStack(spacing: 16) {
                    Button(action: {
                        filterState = TransactionFilterState()
                    }) {
                        Text("Reset Filters")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray)
                            .cornerRadius(15)
                            .shadow(color: Color.gray.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Apply Filters")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.themeColor)
                            .cornerRadius(15)
                            .shadow(color: viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.top, 10)
            }
            .padding()
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Filter Transactions")
    }
}

// Type selection button (Income, Expense, Transfer)
struct TypeFilterButton: View {
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

struct CategoryFilterView: View {
    @Binding var selectedCategories: Set<UUID>
    @EnvironmentObject var viewModel: FinanceViewModel
    
    // Grid layout for categories
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Income Categories
                Text("Income Categories")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if viewModel.incomeCategories.isEmpty {
                    Text("No income categories found")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.incomeCategories) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: selectedCategories.contains(category.id),
                                onTap: {
                                    if selectedCategories.contains(category.id) {
                                        selectedCategories.remove(category.id)
                                    } else {
                                        selectedCategories.insert(category.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                    .padding(.vertical, 10)
                
                // Expense Categories
                Text("Expense Categories")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if viewModel.expenseCategories.isEmpty {
                    Text("No expense categories found")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.expenseCategories) { category in
                            CategoryFilterButton(
                                category: category,
                                isSelected: selectedCategories.contains(category.id),
                                onTap: {
                                    if selectedCategories.contains(category.id) {
                                        selectedCategories.remove(category.id)
                                    } else {
                                        selectedCategories.insert(category.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Select/Clear All buttons
                HStack(spacing: 16) {
                    Button(action: {
                        selectedCategories.removeAll()
                    }) {
                        Text("Clear All")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray)
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        // Add all category IDs
                        viewModel.incomeCategories.forEach { selectedCategories.insert($0.id) }
                        viewModel.expenseCategories.forEach { selectedCategories.insert($0.id) }
                    }) {
                        Text("Select All")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.themeColor)
                            .cornerRadius(15)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Select Categories")
    }
}

// Category selection button with icon
struct CategoryFilterButton: View {
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
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 22))
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
