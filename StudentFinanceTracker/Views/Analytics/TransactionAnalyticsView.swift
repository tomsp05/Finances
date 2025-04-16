//
//  TransactionAnalyticsView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/15/25.
//


import SwiftUI
import Charts

struct TransactionAnalyticsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    
    // Time filter options
    enum TimeFilter: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    @State private var selectedTimeFilter: TimeFilter = .month
    
    // MARK: - Computed Properties
    
    // Filter transactions based on selected time period
    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let today = Date()
        
        let filteredDate: Date = {
            switch selectedTimeFilter {
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: today)!
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: today)!
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: today)!
            }
        }()
        
        return viewModel.transactions.filter { transaction in
            transaction.date >= filteredDate && transaction.date <= today
        }
    }
    
    // Expense transactions for the selected time period
    private var filteredExpenses: [Transaction] {
        filteredTransactions.filter { $0.type == .expense }
    }
    
    // Income transactions for the selected time period
    private var filteredIncomes: [Transaction] {
        filteredTransactions.filter { $0.type == .income }
    }
    
    // Group expenses by category
    private var expensesByCategory: [CategorySpending] {
        let expenseDict = Dictionary(grouping: filteredExpenses) { expense in
            expense.categoryId
        }
        
        return expenseDict.compactMap { (categoryId, transactions) in
            guard let category = viewModel.getCategory(id: categoryId) else { return nil }
            let totalAmount = transactions.reduce(0) { $0 + $1.amount }
            return CategorySpending(
                id: categoryId,
                category: category,
                amount: totalAmount,
                count: transactions.count
            )
        }
        .sorted(by: { $0.amount > $1.amount })
    }
    
    // Calculate total expenses
    private var totalExpenses: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Calculate total income
    private var totalIncome: Double {
        filteredIncomes.reduce(0) { $0 + $1.amount }
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
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time filter selection
                timeFilterView
                
                // Summary cards
                summaryCards
                
                // Category spending breakdown
                categorySpendingSection
                
            }
            .padding()
        }
        .navigationTitle("Spending Analytics")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: - Component Views
    
    // Time filter buttons
    private var timeFilterView: some View {
        HStack(spacing: 8) {
            ForEach(TimeFilter.allCases, id: \.self) { filter in
                TimeFilterButton(
                    title: filter.rawValue,
                    isSelected: selectedTimeFilter == filter,
                    themeColor: viewModel.themeColor
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTimeFilter = filter
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // Summary metrics cards
    private var summaryCards: some View {
        VStack(spacing: 16) {
            Text("Summary")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 16) {
                // Total Income Card
                VStack(spacing: 4) {
                    Text("Income")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(totalIncome))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("\(filteredIncomes.count) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Total Expense Card
                VStack(spacing: 4) {
                    Text("Expenses")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(totalExpenses))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("\(filteredExpenses.count) transactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Net Savings Card
            VStack(spacing: 4) {
                Text("Net Savings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(totalIncome - totalExpenses))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(totalIncome >= totalExpenses ? .green : .red)
                
                let savingsPercentage = totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome * 100 : 0
                Text(String(format: "%.1f%% of income", savingsPercentage))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
    
    // Category spending breakdown section
    private var categorySpendingSection: some View {
        VStack(spacing: 16) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if expensesByCategory.isEmpty {
                Text("No expenses in this period")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
            } else {
                // Pie chart
                if #available(iOS 16.0, *) {
                    categoryPieChart
                        .frame(height: 200)
                        .padding(.vertical)
                }
                
                // List of categories with amounts
                ForEach(expensesByCategory) { categorySpending in
                    CategorySpendingRowView(
                        categorySpending: categorySpending,
                        totalAmount: totalExpenses,
                        formatCurrency: formatCurrency
                    )
                }
            }
        }
    }
    
    @available(iOS 16.0, *)
    private var categoryPieChart: some View {
        Chart {
            ForEach(expensesByCategory) { category in
                SectorMark(
                    angle: .value("Spent", category.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", category.category.name))
                .annotation(position: .overlay) {
                    if category.amount / totalExpenses > 0.1 {
                        Text("\(Int(category.amount / totalExpenses * 100))%")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .chartForegroundStyleScale(range: ChartColors.colorArray)
    }
    
}

// MARK: - Supporting Structs

struct CategorySpending: Identifiable {
    let id: UUID
    let category: Category
    let amount: Double
    let count: Int
}

// Custom chart colors
struct ChartColors {
    static let colorArray: [Color] = [
        .blue, .green, .orange, .purple, .red, .teal, .yellow, .pink,
        .cyan, .indigo, .mint, .brown
    ]
}

// MARK: - Previews

struct TransactionAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransactionAnalyticsView()
                .environmentObject(FinanceViewModel())
        }
    }
}
