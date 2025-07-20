import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var showFilterSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    // Filter state
    @State private var filterState: TransactionFilterState
    
    // New initializer to accept a pre-configured filter state
    init(initialFilterState: TransactionFilterState? = nil) {
        _filterState = State(initialValue: initialFilterState ?? TransactionFilterState())
    }
    
    // Group transactions by day and sort by date (most recent first)
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        // Apply all filters
        let filteredTransactions = viewModel.transactions.filter { transaction in
            // Apply time filter
            let passesTimeFilter: Bool
            
            switch filterState.timeFilter {
            case .all:
                passesTimeFilter = true
            case .future:
                let currentDate = Calendar.current.startOfDay(for: Date())
                passesTimeFilter = Calendar.current.startOfDay(for: transaction.date) >= currentDate
            case .past:
                let currentDate = Calendar.current.startOfDay(for: Date())
                passesTimeFilter = Calendar.current.startOfDay(for: transaction.date) <= currentDate
            case .today:
                passesTimeFilter = Calendar.current.isDateInToday(transaction.date)
            case .thisWeek:
                passesTimeFilter = Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .weekOfYear)
            case .thisMonth:
                passesTimeFilter = Calendar.current.isDate(transaction.date, equalTo: Date(), toGranularity: .month)
            case .lastMonth:
                let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
                passesTimeFilter = Calendar.current.isDate(transaction.date, equalTo: lastMonth, toGranularity: .month)
            case .custom:
                if let startDate = filterState.customStartDate, let endDate = filterState.customEndDate {
                    let adjustedEndDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!
                    passesTimeFilter = transaction.date >= startDate && transaction.date <= adjustedEndDate
                } else {
                    passesTimeFilter = true
                }
            }
            
            // Apply recurring filter
            let passesRecurringFilter = !filterState.onlyRecurring || transaction.isRecurring
            
            // Apply transaction type filter
            let passesTypeFilter = filterState.transactionTypes.isEmpty ||
                                  filterState.transactionTypes.contains(transaction.type)
            
            // Apply category filter
            let passesCategoryFilter = filterState.selectedCategories.isEmpty ||
                                      filterState.selectedCategories.contains(transaction.categoryId)
            
            // Apply amount filter
            let passesAmountFilter: Bool
            if let minAmount = filterState.minAmount, let maxAmount = filterState.maxAmount {
                passesAmountFilter = transaction.amount >= minAmount && transaction.amount <= maxAmount
            } else if let minAmount = filterState.minAmount {
                passesAmountFilter = transaction.amount >= minAmount
            } else if let maxAmount = filterState.maxAmount {
                passesAmountFilter = transaction.amount <= maxAmount
            } else {
                passesAmountFilter = true
            }
            
            // Apply pool filter
            let passesPoolFilter: Bool
            if filterState.selectedPools.isEmpty {
                passesPoolFilter = true
            } else {
                // Check if transaction is assigned to one of the selected pools
                if let poolId = transaction.poolId {
                    passesPoolFilter = filterState.selectedPools.contains(poolId)
                } else {
                    // For now, exclude unassigned transactions when pool filter is active
                    // Future enhancement could add a special "Unassigned" filter option
                    passesPoolFilter = false
                }
            }
            
            return passesTimeFilter && passesRecurringFilter && passesTypeFilter &&
                   passesCategoryFilter && passesAmountFilter && passesPoolFilter
        }
        
        // Group by the start of day for each transaction date.
        let groups = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        // Sort the groups by key (date) descending.
        let sortedGroups = groups.sorted { $0.key > $1.key }
        // Sort transactions within each group by date descending.
        return sortedGroups.map { (date: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Active filters display
            if filterState.hasActiveFilters {
                activeFiltersView
            }
            
            // Transaction list
            transactionsList
        }
        .navigationTitle("Transactions")
        .navigationBarItems(trailing: filterButton)
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showFilterSheet) {
            NavigationView {
                TransactionFilterView(filterState: $filterState)
            }
        }
    }
    
    // Filter button for navigation bar
    private var filterButton: some View {
        Button(action: {
            showFilterSheet = true
        }) {
            HStack(spacing: 5) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                Text(filterState.hasActiveFilters ? "\(activeFilterCount)" : "")
            }
        }
    }
    
    // Active filters display
    private var activeFiltersView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active Filters")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    filterState = TransactionFilterState()
                }) {
                    Text("Clear All")
                        .font(.subheadline)
                        .foregroundColor(viewModel.themeColor)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if filterState.timeFilter != .all {
                        filterTag(
                            icon: filterState.timeFilter.systemImage,
                            text: filterState.timeFilter.rawValue,
                            color: viewModel.themeColor
                        )
                    }
                    
                    if !filterState.transactionTypes.isEmpty {
                        let typeText = filterState.transactionTypes.count == 1 ?
                          filterState.transactionTypes.first!.rawValue.capitalized :
                          "\(filterState.transactionTypes.count) Types"
                        
                        filterTag(
                            icon: "arrow.left.arrow.right.circle",
                            text: typeText,
                            color: .blue
                        )
                    }
                    
                    if !filterState.selectedCategories.isEmpty {
                        filterTag(
                            icon: "tag",
                            text: "\(filterState.selectedCategories.count) Categories",
                            color: .orange
                        )
                    }
                    
                    if filterState.minAmount != nil || filterState.maxAmount != nil {
                        let amountText = formatAmountFilterText()
                        filterTag(
                            icon: "dollarsign.circle",
                            text: amountText,
                            color: .green
                        )
                    }
                    
                    if filterState.onlyRecurring {
                        filterTag(
                            icon: "repeat",
                            text: "Recurring Only",
                            color: .purple
                        )
                    }
                    
                    if !filterState.selectedPools.isEmpty {
                        filterTag(
                            icon: "drop.fill",
                            text: "\(filterState.selectedPools.count) Pool\(filterState.selectedPools.count == 1 ? "" : "s")",
                            color: .cyan
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            
            Divider()
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
    }
    
    // Filter tag component
    private func filterTag(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(colorScheme == .dark ? 0.25 : 0.15))
        )
        .foregroundColor(color)
    }
    
    // Helper to count active filters
    private var activeFilterCount: Int {
        var count = 0
        
        if filterState.timeFilter != .all { count += 1 }
        if !filterState.transactionTypes.isEmpty { count += 1 }
        if !filterState.selectedCategories.isEmpty { count += 1 }
        if filterState.minAmount != nil || filterState.maxAmount != nil { count += 1 }
        if filterState.onlyRecurring { count += 1 }
        if !filterState.selectedPools.isEmpty { count += 1 }
        
        return count
    }
    
    // Helper to format amount filter text
    private func formatAmountFilterText() -> String {
        if let min = filterState.minAmount, let max = filterState.maxAmount {
            return "£\(String(format: "%.0f", min)) - £\(String(format: "%.0f", max))"
        } else if let min = filterState.minAmount {
            return "Min: £\(String(format: "%.0f", min))"
        } else if let max = filterState.maxAmount {
            return "Max: £\(String(format: "%.0f", max))"
        } else {
            return "Amount"
        }
    }
    
    // Transactions list view
    private var transactionsList: some View {
        ScrollView {
            if groupedTransactions.isEmpty {
                noTransactionsView
            } else {
                LazyVStack(spacing: 12) {
                    // Iterate over grouped transactions
                    ForEach(groupedTransactions, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            // Date header for the group
                            Text(formattedDate(group.date))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                            
                            Divider()
                            
                            // List out each transaction for this day.
                            ForEach(group.transactions) { transaction in
                                NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                                    TransactionCardView(transaction: transaction)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }.padding(.vertical, 2)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
            }
        }
    }
    
    // No transactions view
    private var noTransactionsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56))
                .foregroundColor(viewModel.themeColor.opacity(0.5))
            
            Text("No transactions match your filters")
                .font(.headline)
                .foregroundColor(.primary)
            
            if filterState.hasActiveFilters {
                Button(action: {
                    filterState = TransactionFilterState()
                }) {
                    Text("Clear all filters")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(viewModel.themeColor)
                        .cornerRadius(10)
                        .shadow(color: colorScheme == .dark ? Color.clear : viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Helper to format the grouped date header.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Apr 14, 2025"
        return formatter.string(from: date)
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransactionsListView().environmentObject(FinanceViewModel())
        }
    }
}

// MARK: - Filter State

struct TransactionFilterState {
    var timeFilter: TransactionTimeFilter = .all
    var selectedCategories: Set<UUID> = []
    var transactionTypes: Set<TransactionType> = []
    var minAmount: Double? = nil
    var maxAmount: Double? = nil
    var onlyRecurring: Bool = false
    var selectedPools: Set<UUID> = [] // New pool filter
    var customStartDate: Date? = nil
    var customEndDate: Date? = nil
    
    var hasActiveFilters: Bool {
        return timeFilter != .all ||
               !selectedCategories.isEmpty ||
               !transactionTypes.isEmpty ||
               minAmount != nil ||
               maxAmount != nil ||
               onlyRecurring ||
               !selectedPools.isEmpty // Include pool filter
    }
}
