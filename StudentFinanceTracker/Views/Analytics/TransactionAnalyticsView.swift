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
    @Environment(\.colorScheme) var colorScheme
    
    // Time filter options
    enum TimeFilter: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    @State private var selectedTimeFilter: TimeFilter = .month
    @State private var selectedCategoryIds: Set<UUID> = []
    @State private var showCategoryFilter: Bool = false
    @State private var timeOffset: Int = 0 // 0 = current period, -1 = previous period, etc.
    @State private var selectedChartStyle: String = "Pie" // "Pie", "Bar", or "Line"
    
    // MARK: - Computed Properties
    
    // Date range based on selected time filter and offset
    private var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let endDate = Date().addingTimeInterval(Double(timeOffset) * getTimeIntervalForFilter())
        
        let startDate: Date
        switch selectedTimeFilter {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        }
        
        return (start: startDate, end: endDate)
    }
    
    // Helper to get time interval in seconds for the selected filter
    private func getTimeIntervalForFilter() -> TimeInterval {
        switch selectedTimeFilter {
        case .week: return 7 * 24 * 60 * 60
        case .month: return 30 * 24 * 60 * 60
        case .year: return 365 * 24 * 60 * 60
        }
    }
    
    // Get time period title
    private var timePeriodTitle: String {
        let formatter = DateFormatter()
        
        switch selectedTimeFilter {
        case .week:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: dateRange.end)
        case .year:
            formatter.dateFormat = "MMM yyyy"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        }
    }
    
    // Filter transactions based on selected time period
    private var filteredTransactions: [Transaction] {
        let transactions = viewModel.transactions.filter { transaction in
            let isInTimeRange = transaction.date >= dateRange.start && transaction.date <= dateRange.end
            
            if selectedCategoryIds.isEmpty {
                return isInTimeRange
            } else {
                return isInTimeRange && selectedCategoryIds.contains(transaction.categoryId)
            }
        }
        
        return transactions
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
    
    // Group expenses by date for timeline view
    private var expensesByDate: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        
        // Group by day for week/month, by month for year
        let groupingBlock: (Transaction) -> Date = { transaction in
            if selectedTimeFilter == .year {
                // For year view, group by month
                var components = calendar.dateComponents([.year, .month], from: transaction.date)
                components.day = 1 // Start of month
                return calendar.date(from: components) ?? transaction.date
            } else {
                // For week/month view, group by day
                return calendar.startOfDay(for: transaction.date)
            }
        }
        
        let groups = Dictionary(grouping: filteredExpenses, by: groupingBlock)
            .mapValues { transactions in
                transactions.reduce(0) { $0 + $1.amount }
            }
        
        // Sort by date
        return groups.map { (date, amount) in
            (date: date, amount: amount)
        }.sorted { $0.date < $1.date }
    }
    
    // Calculate total expenses
    private var totalExpenses: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    // Calculate total income
    private var totalIncome: Double {
        filteredIncomes.reduce(0) { $0 + $1.amount }
    }
    
    // Get all categories that have data in current period
    private var availableCategories: [Category] {
        let categoryIds = Set(filteredTransactions.map { $0.categoryId })
        
        let expenseCategories = viewModel.expenseCategories.filter { categoryIds.contains($0.id) }
        let incomeCategories = viewModel.incomeCategories.filter { categoryIds.contains($0.id) }
        
        return expenseCategories + incomeCategories
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
    
    // Format date label for chart
    private func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedTimeFilter {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d"
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time navigation and filters
                timeNavigationView
                
                // Summary cards
                summaryCards
                
                // Chart type selector
                chartTypeSelector
                
                // Chart view based on selected type
                if !expensesByCategory.isEmpty {
                    if selectedChartStyle == "Pie" {
                        if #available(iOS 16.0, *) {
                            categoryPieChart
                        } else {
                            Text("Pie charts require iOS 16")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    } else if selectedChartStyle == "Bar" {
                        if #available(iOS 16.0, *) {
                            categoryBarChart
                        } else {
                            Text("Bar charts require iOS 16")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    } else if selectedChartStyle == "Line" {
                        if #available(iOS 16.0, *) {
                            timelineChart
                        } else {
                            Text("Line charts require iOS 16")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                } else {
                    noDataView
                }
                
                // Category spending breakdown
                categorySpendingSection
            }
            .padding()
        }
        .navigationTitle("Spending Analytics")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showCategoryFilter) {
            CategoryFilterSheet(
                availableCategories: availableCategories,
                selectedCategories: $selectedCategoryIds
            )
        }
        .onAppear {
            // Initialize selected categories with all available categories
            if selectedCategoryIds.isEmpty {
                selectedCategoryIds = Set(availableCategories.map { $0.id })
            }
        }
    }
    
    // MARK: - Component Views
    
    // Time navigation view
    private var timeNavigationView: some View {
        VStack(spacing: 16) {
            // Period title with navigation arrows
            HStack {
                Button(action: {
                    timeOffset -= 1
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(viewModel.themeColor)
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(0.1)))
                }
                
                Spacer()
                
                Text(timePeriodTitle)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    if timeOffset < 0 {
                        timeOffset += 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(viewModel.themeColor)
                        .padding(8)
                        .background(Circle().fill(viewModel.themeColor.opacity(0.1)))
                }
                .disabled(timeOffset == 0)
            }
            .padding(.vertical, 4)
            
            // Time filter buttons
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
                
                Spacer()
                
                // Category filter button
                Button(action: {
                    showCategoryFilter = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 14))
                        
                        Text("Filter")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(viewModel.themeColor.opacity(0.1))
                    .foregroundColor(viewModel.themeColor)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(viewModel.themeColor.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // Chart type selector
    private var chartTypeSelector: some View {
        HStack(spacing: 12) {
            Button(action: { selectedChartStyle = "Pie" }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 14))
                    
                    Text("Pie")
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selectedChartStyle == "Pie"
                    ? viewModel.themeColor.opacity(0.2)
                    : Color(.systemGray5)
                )
                .foregroundColor(
                    selectedChartStyle == "Pie"
                    ? viewModel.themeColor
                    : Color(.systemGray)
                )
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { selectedChartStyle = "Bar" }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14))
                    
                    Text("Bar")
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selectedChartStyle == "Bar"
                    ? viewModel.themeColor.opacity(0.2)
                    : Color(.systemGray5)
                )
                .foregroundColor(
                    selectedChartStyle == "Bar"
                    ? viewModel.themeColor
                    : Color(.systemGray)
                )
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: { selectedChartStyle = "Line" }) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 14))
                    
                    Text("Line")
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    selectedChartStyle == "Line"
                    ? viewModel.themeColor.opacity(0.2)
                    : Color(.systemGray5)
                )
                .foregroundColor(
                    selectedChartStyle == "Line"
                    ? viewModel.themeColor
                    : Color(.systemGray)
                )
                .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
    }
    
    // Summary metrics cards
    private var summaryCards: some View {
        VStack(spacing: 16) {
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
                .background(Color.green.opacity(colorScheme == .dark ? 0.15 : 0.1))
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
                .background(Color.red.opacity(colorScheme == .dark ? 0.15 : 0.1))
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
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }
    
    // No data view
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            
            Text("No expense data for this period")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if !selectedCategoryIds.isEmpty && selectedCategoryIds.count != availableCategories.count {
                Button(action: {
                    // Reset category filters
                    selectedCategoryIds = Set(availableCategories.map { $0.id })
                }) {
                    Text("Reset Category Filters")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.themeColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 30)
    }
    
    // Category pie chart
    @available(iOS 16.0, *)
    private var categoryPieChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.secondary)
            
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
            .frame(height: 240)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Category bar chart
    @available(iOS 16.0, *)
    private var categoryBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(expensesByCategory) { category in
                    BarMark(
                        x: .value("Amount", category.amount),
                        y: .value("Category", category.category.name)
                    )
                    .foregroundStyle(by: .value("Category", category.category.name))
                    .annotation(position: .trailing) {
                        Text(formatCurrency(category.amount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartForegroundStyleScale(range: ChartColors.colorArray)
            .frame(height: min(CGFloat(expensesByCategory.count * 50), 300))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Timeline chart
    @available(iOS 16.0, *)
    private var timelineChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending Over Time")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(expensesByDate, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.amount)
                    )
                    .foregroundStyle(viewModel.themeColor)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.amount)
                    )
                    .foregroundStyle(viewModel.themeColor.opacity(0.2))
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.amount)
                    )
                    .foregroundStyle(viewModel.themeColor)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatDateLabel(date))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text("£\(Int(amount))")
                        }
                    }
                }
            }
            .frame(height: 240)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Category spending breakdown section
    private var categorySpendingSection: some View {
        VStack(spacing: 16) {
            if !expensesByCategory.isEmpty {
                Text("Category Breakdown")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
}

// MARK: - Supporting Structs

struct CategoryFilterSheet: View {
    let availableCategories: [Category]
    @Binding var selectedCategories: Set<UUID>
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: FinanceViewModel
    
    // Split categories by type
    private var expenseCategories: [Category] {
        availableCategories.filter { $0.type == .expense }
    }
    
    private var incomeCategories: [Category] {
        availableCategories.filter { $0.type == .income }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Expense categories
                    if !expenseCategories.isEmpty {
                        categorySection(
                            title: "Expense Categories",
                            categories: expenseCategories,
                            color: .red
                        )
                    }
                    
                    // Income categories
                    if !incomeCategories.isEmpty {
                        categorySection(
                            title: "Income Categories",
                            categories: incomeCategories,
                            color: .green
                        )
                    }
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button(action: {
                            // Clear all selected categories
                            selectedCategories.removeAll()
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Clear All")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            // Select all categories
                            selectedCategories = Set(availableCategories.map { $0.id })
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Select All")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(viewModel.themeColor)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding()
            }
            .navigationTitle("Filter Categories")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Category section view
    private func categorySection(title: String, categories: [Category], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 12)
            ], spacing: 12) {
                ForEach(categories) { category in
                    categoryButton(category: category, color: color)
                }
            }
        }
    }
    
    // Category selection button
    private func categoryButton(category: Category, color: Color) -> some View {
        let isSelected = selectedCategories.contains(category.id)
        
        return Button(action: {
            // Toggle selection
            if isSelected {
                selectedCategories.remove(category.id)
            } else {
                selectedCategories.insert(category.id)
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? color : Color.gray)
                }
                
                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 100)
    }
}

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
