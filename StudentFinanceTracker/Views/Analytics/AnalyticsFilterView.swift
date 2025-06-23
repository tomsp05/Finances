import SwiftUI

struct AnalyticsFilterView: View {
    @Binding var filterState: AnalyticsFilterState
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time period filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Time Period")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    // Time filter options with more padding
                    VStack(spacing: 14) {
                        ForEach(AnalyticsTimeFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                filterState.timeFilter = filter
                                filterState.timeOffset = 0 // Reset offset when changing filter
                            }) {
                                HStack {
                                    Image(systemName: filterIcon(for: filter))
                                        .foregroundColor(viewModel.themeColor)
                                        .frame(width: 28)
                                        .font(.system(size: 18))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(filter.rawValue)
                                            .foregroundColor(.primary)
                                            .font(.system(size: 17))
                                        
                                        Text(filterDescription(for: filter))
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if filterState.timeFilter == filter {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(viewModel.themeColor)
                                            .font(.headline)
                                    }
                                }
                                .padding(.vertical, 20)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(filterState.timeFilter == filter ?
                                              viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1) :
                                              Color(UIColor.secondarySystemBackground))
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
                .padding(.bottom, 8)
                
                // Transaction type filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Transaction Type")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    HStack(spacing: 12) {
                        ForEach(AnalyticsTransactionType.allCases, id: \.self) { type in
                            TypeFilterButton(
                                title: type.rawValue.capitalized,
                                isSelected: filterState.transactionType == type,
                                action: {
                                    filterState.transactionType = type
                                }
                            )
                        }
                    }
                }
                .padding(.bottom, 8)
                
                // Category filter
                VStack(alignment: .leading, spacing: 12) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    
                    NavigationLink(destination: AnalyticsCategoryFilterView(selectedCategories: $filterState.selectedCategories, filterType: filterState.transactionType)) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
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
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .padding(.bottom, 10)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Filter Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Reset") {
                    filterState = AnalyticsFilterState()
                }
                .foregroundColor(viewModel.themeColor)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Apply") {
                    dismiss()
                }
                .foregroundColor(viewModel.themeColor)
                .fontWeight(.bold)
            }
        }
    }
    
    private func filterIcon(for timeFilter: AnalyticsTimeFilter) -> String {
        switch timeFilter {
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .yearToDate: return "calendar.badge.exclamationmark"
        case .pastYear: return "calendar.circle"
        case .year: return "calendar.badge.clock.rtl"
        }
    }
    
    private func filterDescription(for timeFilter: AnalyticsTimeFilter) -> String {
        switch timeFilter {
        case .week: return "Monday to Sunday"
        case .month: return "1st to today"
        case .yearToDate: return "January 1st to today"
        case .pastYear: return "Last 12 months from the 1st"
        case .year: return "Last 365 days from today"
        }
    }
}

struct AnalyticsCategoryFilterView: View {
    @Binding var selectedCategories: Set<UUID>
    let filterType: AnalyticsTransactionType
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // Grid layout for categories
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Show only relevant categories based on filter type
                if filterType == .income || filterType == .all {
                    categorySection(
                        title: "Income Categories",
                        categories: viewModel.incomeCategories
                    )
                }
                
                if filterType == .expense || filterType == .all {
                    if filterType == .all {
                        Divider()
                            .padding(.vertical, 10)
                    }
                    
                    categorySection(
                        title: "Expense Categories",
                        categories: viewModel.expenseCategories
                    )
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
                            .background(Color(UIColor.systemGray))
                            .cornerRadius(15)
                            .shadow(color: colorScheme == .dark ? Color.clear : Color.gray.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    
                    Button(action: {
                        // Add all relevant category IDs based on filter type
                        switch filterType {
                        case .income:
                            viewModel.incomeCategories.forEach { selectedCategories.insert($0.id) }
                        case .expense:
                            viewModel.expenseCategories.forEach { selectedCategories.insert($0.id) }
                        case .all:
                            viewModel.incomeCategories.forEach { selectedCategories.insert($0.id) }
                            viewModel.expenseCategories.forEach { selectedCategories.insert($0.id) }
                        }
                    }) {
                        Text("Select All")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(viewModel.themeColor)
                            .cornerRadius(15)
                            .shadow(color: colorScheme == .dark ? Color.clear : viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Select Categories")
    }
    
    private func categorySection(title: String, categories: [Category]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if categories.isEmpty {
                Text("No categories found")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(categories) { category in
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
        }
    }
}

// Analytics filter state model - NOW Codable and Equatable
struct AnalyticsFilterState: Codable, Equatable {
    var timeFilter: AnalyticsTimeFilter = .month
    var timeOffset: Int = 0
    var transactionType: AnalyticsTransactionType = .all
    var selectedCategories: Set<UUID> = []
    
    var hasActiveFilters: Bool {
        return transactionType != .all || !selectedCategories.isEmpty
    }
}

// Analytics time filter options - NOW Codable
enum AnalyticsTimeFilter: String, CaseIterable, Codable {
    case week = "Week"
    case month = "Month"
    case yearToDate = "Year to Date"
    case pastYear = "Past Year"
    case year = "Calendar Year"
}

// Analytics transaction type filter - NOW Codable
enum AnalyticsTransactionType: String, CaseIterable, Codable {
    case all = "All"
    case income = "Income"
    case expense = "Expense"
}
