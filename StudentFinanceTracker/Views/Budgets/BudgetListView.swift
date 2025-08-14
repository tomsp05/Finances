import SwiftUI

struct BudgetListView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var showingAddBudget = false
    @State private var selectedBudgetForEdit: Budget? = nil
    @State private var showingEditBudget = false
    @State private var searchText = ""
    @State private var selectedFilter: BudgetFilter = .all
    @State private var showingBudgetInsights = false
    @State private var selectedBudgetForDetails: Budget? = nil
    @Environment(\.colorScheme) var colorScheme
    
    enum BudgetFilter: String, CaseIterable {
        case all = "All"
        case onTrack = "On Track"
        case warning = "Warning"
        case overBudget = "Over Budget"
        case nearExpiry = "Expiring Soon"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Enhanced header with summary and quick actions
                summaryCard
                
                // Search and filter bar
                searchAndFilterBar
                
                
                
                // Budget sections
                if !filteredOverallBudgets.isEmpty {
                    budgetSection(title: "Overall Budgets", icon: "chart.pie.fill", budgets: filteredOverallBudgets)
                }
                
                if !filteredCategoryBudgets.isEmpty {
                    budgetSection(title: "Category Budgets", icon: "tag.fill", budgets: filteredCategoryBudgets)
                }
                
                if !filteredAccountBudgets.isEmpty {
                    budgetSection(title: "Account Budgets", icon: "creditcard.fill", budgets: filteredAccountBudgets)
                }
                
                // Empty state
                if filteredBudgets.isEmpty {
                    emptyState
                }
                
                // Add budget button with quick templates
                addBudgetSection
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Budgets")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .refreshable {
            await refreshBudgets()
        }
        // Add Budget Sheet
        .sheet(isPresented: $showingAddBudget) {
            BudgetEditView(budget: nil)
                .onDisappear {
                    showingAddBudget = false
                }
        }
        // Edit Budget Sheet - Fixed version
        .sheet(isPresented: $showingEditBudget) {
            BudgetEditView(budget: selectedBudgetForEdit)
                .onDisappear {
                    showingEditBudget = false
                    selectedBudgetForEdit = nil
                }
        }
        // Budget Details Sheet
        .sheet(item: $selectedBudgetForDetails) { budget in
            NavigationView {
                BudgetDetailView(budget: budget)
                    .navigationTitle(budget.name)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }

    }
    
    // MARK: - Enhanced Helper Views
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Budget Overview")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Quick add button
                Button(action: {
                    showingAddBudget = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            
            // Enhanced stats grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                budgetStat(
                    icon: "chart.pie.fill",
                    value: "\(viewModel.budgets.count)",
                    label: "Active Budgets",
                    color: .white
                )
                
                budgetStat(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(overBudgetCount)",
                    label: "Over Budget",
                    color: overBudgetCount > 0 ? .orange : .white
                )
                
                budgetStat(
                    icon: "checkmark.circle.fill",
                    value: "\(onTrackCount)",
                    label: "On Track",
                    color: .green
                )
                
                budgetStat(
                    icon: "clock.fill",
                    value: "\(expiringCount)",
                    label: "Expiring Soon",
                    color: expiringCount > 0 ? .yellow : .white
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    viewModel.themeColor.opacity(0.7),
                    viewModel.themeColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: viewModel.themeColor.opacity(0.5), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            
            // Filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(BudgetFilter.allCases, id: \.self) { filter in
                        filterPill(for: filter)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func filterPill(for filter: BudgetFilter) -> some View {
        Button(action: {
            selectedFilter = filter
        }) {
            HStack(spacing: 6) {
                filterIcon(for: filter)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if filterCount(for: filter) > 0 && filter != .all {
                    Text("\(filterCount(for: filter))")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedFilter == filter
                    ? viewModel.themeColor
                    : Color.secondary.opacity(0.2)
            )
            .foregroundColor(
                selectedFilter == filter
                    ? .white
                    : .primary
            )
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func filterIcon(for filter: BudgetFilter) -> some View {
        Group {
            switch filter {
            case .all:
                Image(systemName: "list.bullet")
            case .onTrack:
                Image(systemName: "checkmark.circle")
            case .warning:
                Image(systemName: "exclamationmark.triangle")
            case .overBudget:
                Image(systemName: "exclamationmark.octagon")
            case .nearExpiry:
                Image(systemName: "clock")
            }
        }
        .font(.caption)
    }
    

    
    
    private func budgetStat(icon: String, value: String, label: String, color: Color = .white) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(color.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func budgetSection(title: String, icon: String, budgets: [Budget]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced section header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(viewModel.themeColor)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                // Progress indicator for section
                Text("\(budgets.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            // Budget items with enhanced interaction
            ForEach(budgets) { budget in
                Button(action: {
                    selectedBudgetForDetails = budget
                }) {
                    EnhancedBudgetCardView(budget: budget, viewModel: viewModel)
                        .padding(.horizontal)
                        .contextMenu {
                            Button(action: {
                                selectedBudgetForEdit = budget
                                showingEditBudget = true
                            }) {
                                Label("Edit Budget", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                deleteBudget(budget)
                            }) {
                                Label("Delete Budget", systemImage: "trash")
                            }
                        }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? "chart.pie" : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.7))
            
            Text(searchText.isEmpty ? "No Budgets Set" : "No Results Found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(searchText.isEmpty
                 ? "Start tracking your spending by creating budgets"
                 : "Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    selectedFilter = .all
                }) {
                    Text("Clear Search")
                        .font(.callout)
                        .foregroundColor(viewModel.themeColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
    
    private var addBudgetSection: some View {
        VStack(spacing: 12) {
            // Main add button
            Button(action: {
                showingAddBudget = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    
                    Text("Add New Budget")
                        .fontWeight(.semibold)
                }
                .foregroundColor(viewModel.themeColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewModel.themeColor.opacity(0.1))
                .cornerRadius(15)
            }
            .buttonStyle(PlainButtonStyle())
        
        }
        .padding(.horizontal)
    }
    
    private func quickTemplateButton(title: String, icon: String, amount: Double) -> some View {
        Button(action: {
            createQuickBudget(title: title, amount: amount)
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.callout)
                
                Text(title)
                    .font(.caption2)
                
                Text(viewModel.formatCurrency(amount))
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundColor(viewModel.themeColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(viewModel.themeColor.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Enhanced Helper Properties
    
    private var filteredBudgets: [Budget] {
        let filtered = viewModel.budgets.filter { budget in
            let matchesSearch = searchText.isEmpty ||
                               budget.name.localizedCaseInsensitiveContains(searchText)
            
            let matchesFilter: Bool
            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .onTrack:
                matchesFilter = budget.currentSpent <= budget.amount * 0.8
            case .warning:
                matchesFilter = budget.currentSpent > budget.amount * 0.8 && budget.currentSpent <= budget.amount
            case .overBudget:
                matchesFilter = budget.currentSpent > budget.amount
            case .nearExpiry:
                // Assuming budget has endDate property
                matchesFilter = isNearExpiry(budget)
            }
            
            return matchesSearch && matchesFilter
        }
        
        return filtered
    }
    
    private var filteredOverallBudgets: [Budget] {
        filteredBudgets.filter { $0.type == .overall }
    }
    
    private var filteredCategoryBudgets: [Budget] {
        filteredBudgets.filter { $0.type == .category }
    }
    
    private var filteredAccountBudgets: [Budget] {
        filteredBudgets.filter { $0.type == .account }
    }
    
    private var overBudgetCount: Int {
        viewModel.budgets.filter { $0.currentSpent > $0.amount }.count
    }
    
    private var onTrackCount: Int {
        viewModel.budgets.filter { $0.currentSpent <= $0.amount * 0.8 }.count
    }
    
    private var expiringCount: Int {
        viewModel.budgets.filter { isNearExpiry($0) }.count
    }
    
    // MARK: - Helper Methods
    
    private func filterCount(for filter: BudgetFilter) -> Int {
        switch filter {
        case .all:
            return viewModel.budgets.count
        case .onTrack:
            return onTrackCount
        case .warning:
            return viewModel.budgets.filter {
                $0.currentSpent > $0.amount * 0.8 && $0.currentSpent <= $0.amount
            }.count
        case .overBudget:
            return overBudgetCount
        case .nearExpiry:
            return expiringCount
        }
    }
    
    private func isNearExpiry(_ budget: Budget) -> Bool {
        // Implement logic based on budget end date
        // This would depend on your Budget model having an endDate property
        return false // Placeholder
    }
    
    private func refreshBudgets() async {
        viewModel.loadBudgets()
        viewModel.handleTransactionChange()
    }
    
    private func deleteBudget(_ budget: Budget) {
        viewModel.deleteBudget(budget)
    }
    
    private func createQuickBudget(title: String, amount: Double) {
        // Create a quick budget template
        // This would integrate with your budget creation logic
    }
}
