import SwiftUI
import Charts

struct TransactionAnalyticsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // Filter state
    @State private var filterState = AnalyticsFilterState()
    @State private var showFilterSheet = false
    
    // Chart type
    @State private var selectedChartStyle: String = "Pie" // "Pie", "Bar", or "Line"
    
    // Scroll state tracking
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollOffset: CGFloat = 0
    @State private var headerHeight: CGFloat = 80
    @State private var filterHeight: CGFloat = 40
    
    // MARK: - Computed Properties
    
    // Date range based on selected time filter and offset
    private var dateRange: (start: Date, end: Date) {
        // We'll need to mutate both start & end
        var startDate: Date
        var endDate: Date
        let calendar = Calendar.current
        let now = Date()
        
        switch filterState.timeFilter {
        case .week:
            // 1. Find this week's Monday
            var weekCal = calendar
            weekCal.firstWeekday = 2      // 1 = Sunday, 2 = Monday
            guard let thisWeekStart = weekCal.dateInterval(of: .weekOfYear, for: now)?.start else {
                // Fallback to "past 7 days"
                endDate   = now
                startDate = weekCal.date(byAdding: .day, value: -6, to: now)!
                break
            }
            // 2. Shift that Monday by offset weeks
            startDate = weekCal.date(
                byAdding: .weekOfYear,
                value: filterState.timeOffset,
                to: thisWeekStart
            )!
            // 3. Sunday is 6 days later
            endDate = weekCal.date(byAdding: .day, value: 6, to: startDate)!
            
        case .month:
            // 1. Find the 1st of this month
            guard let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start else {
                // Fallback to "past 30 days"
                endDate   = now
                startDate = calendar.date(byAdding: .day, value: -29, to: now)!
                break
            }
            // 2. Shift that 1st by offset months
            startDate = calendar.date(
                byAdding: .month,
                value: filterState.timeOffset,
                to: thisMonthStart
            )!
            if filterState.timeOffset == 0 {
                // "Current day" of the *current* month
                endDate = now
            } else {
                // For past/future months, show the *entire* month
                let nextMonthStart = calendar.date(
                    byAdding: .month,
                    value: 1,
                    to: startDate
                )!
                endDate = nextMonthStart.addingTimeInterval(-1) // last moment of that month
            }
            
        case .yearToDate:
            // end = now shifted by offset*year‑length
            endDate = now.addingTimeInterval(
                Double(filterState.timeOffset) * getTimeIntervalForFilter()
            )
            // start = 1 Jan of that year
            var comps = calendar.dateComponents([.year], from: endDate)
            comps.month = 1
            comps.day   = 1
            startDate = calendar.date(from: comps)!
            
        case .pastYear:
            endDate = now.addingTimeInterval(
                Double(filterState.timeOffset) * getTimeIntervalForFilter()
            )
            let comps = calendar.dateComponents([.year, .month], from: endDate)
            let monthStart = calendar.date(from: comps)!
            startDate = calendar.date(
                byAdding: .year,
                value: -1,
                to: monthStart
            )!
            
        case .year:
            endDate   = now.addingTimeInterval(
                Double(filterState.timeOffset) * getTimeIntervalForFilter()
            )
            startDate = calendar.date(
                byAdding: .year,
                value: -1,
                to: endDate
            )!
        }
        
        return (start: startDate, end: endDate)
    }

    // Helper to get time interval in seconds for the selected filter
    private func getTimeIntervalForFilter() -> TimeInterval {
        switch filterState.timeFilter {
        case .week:       return 7 * 24 * 60 * 60
        case .month:      return 30 * 24 * 60 * 60
        case .yearToDate: return 365 * 24 * 60 * 60   // Approximate
        case .pastYear:   return 365 * 24 * 60 * 60
        case .year:       return 365 * 24 * 60 * 60
        }
    }
    
    // Get time period title
    private var timePeriodTitle: String {
        let formatter = DateFormatter()
        
        switch filterState.timeFilter {
        case .week:
            formatter.dateFormat = "MMM d"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: dateRange.end)
        case .yearToDate:
            formatter.dateFormat = "yyyy"
            let year = formatter.string(from: dateRange.end)
            return "\(year) YTD"
        case .pastYear:
            formatter.dateFormat = "MMM yyyy"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        case .year:
            formatter.dateFormat = "MMM yyyy"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        }
    }
    
    // Filter transactions based on selected filters
    private var filteredTransactions: [Transaction] {
        let transactions = viewModel.transactions.filter { transaction in
            // Time range filter
            let isInTimeRange = transaction.date >= dateRange.start && transaction.date <= dateRange.end
            
            // Transaction type filter
            let matchesType: Bool
            switch filterState.transactionType {
            case .all:
                matchesType = true
            case .income:
                matchesType = transaction.type == .income
            case .expense:
                matchesType = transaction.type == .expense
            }
            
            // Category filter
            let matchesCategory = filterState.selectedCategories.isEmpty ||
                filterState.selectedCategories.contains(transaction.categoryId)
            
            return isInTimeRange && matchesType && matchesCategory
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
    
    // Group income by category
    private var incomeByCategory: [CategorySpending] {
        let incomeDict = Dictionary(grouping: filteredIncomes) { income in
            income.categoryId
        }
        
        return incomeDict.compactMap { (categoryId, transactions) in
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
    
    // Combined categories for charts when showing all transactions
    private var combinedCategoryData: [CategorySpending] {
        let allTransactions = filteredTransactions
        let categoryDict = Dictionary(grouping: allTransactions) { transaction in
            transaction.categoryId
        }
        
        return categoryDict.compactMap { (categoryId, transactions) in
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
    
    // Group transactions by date for timeline view
    private var transactionsByDate: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let transactions = filteredTransactions
        
        // Group by day for week/month, by month for year type views
        let groupingBlock: (Transaction) -> Date = { transaction in
            if filterState.timeFilter == .yearToDate || filterState.timeFilter == .pastYear || filterState.timeFilter == .year {
                // For year type views, group by month
                var components = calendar.dateComponents([.year, .month], from: transaction.date)
                components.day = 1 // Start of month
                return calendar.date(from: components) ?? transaction.date
            } else {
                // For week/month view, group by day
                return calendar.startOfDay(for: transaction.date)
            }
        }
        
        let groups = Dictionary(grouping: transactions, by: groupingBlock)
            .mapValues { transactions in
                transactions.reduce(0) { result, transaction in
                    result + (transaction.type == .expense ? -transaction.amount : transaction.amount)
                }
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
        
        switch filterState.timeFilter {
        case .week:
            formatter.dateFormat = "EEE"
        case .month:
            formatter.dateFormat = "d"
        case .yearToDate, .pastYear, .year:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea()
            
            // Content with static header
            VStack(spacing: 0) {
                // Time navigation view (always visible)
                timeNavigationView
                    .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .zIndex(2)
                
                // Main content
                ZStack(alignment: .top) {
                    // Offset tracking view
                    OffsetObservingScrollView(offset: $scrollOffset) {
                        VStack(spacing: 24) {
                            // Summary cards
                            summaryCards
                                .padding(.top, 8)
                            
                            // Chart type selector
                            chartTypeSelector
                            
                            // Chart view based on selected type
                            if !hasDataForCurrentView {
                                noDataView
                            } else {
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
                            }
                            
                            // Category spending breakdown
                            categorySpendingSection
                            
                            // Bottom padding
                            Spacer().frame(height: 50)
                        }
                        .padding(.horizontal)
                    }
                    .zIndex(1)
                }
            }
        }
        .navigationTitle("Spending Analytics")
        .navigationBarItems(trailing: filterButton)
        .sheet(isPresented: $showFilterSheet) {
            NavigationView {
                AnalyticsFilterView(filterState: $filterState)
            }
        }
    }
    
    // Custom offset-tracking ScrollView
    struct OffsetObservingScrollView<Content: View>: View {
        @Binding var offset: CGFloat
        let content: Content
        
        init(offset: Binding<CGFloat>, @ViewBuilder content: () -> Content) {
            self._offset = offset
            self.content = content()
        }
        
        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    GeometryReader { geo in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minY)
                    }
                    .frame(height: 0)
                    
                    content
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
        }
    }
    
    // MARK: - Component Views
    
    // Filter button for navigation bar with active filters count
    private var filterButton: some View {
        Button(action: {
            showFilterSheet = true
        }) {
            HStack(spacing: 5) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22))
                
                // Show count of active filters
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(viewModel.themeColor)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    // Helper to count active filters (only category and transaction type)
    private var activeFilterCount: Int {
        var count = 0
        
        if filterState.transactionType != .all { count += 1 }
        if !filterState.selectedCategories.isEmpty { count += 1 }
        
        return count
    }
    
    // Check if there's data for the current view
    private var hasDataForCurrentView: Bool {
        switch filterState.transactionType {
        case .all:
            return !combinedCategoryData.isEmpty
        case .income:
            return !incomeByCategory.isEmpty
        case .expense:
            return !expensesByCategory.isEmpty
        }
    }
    
    // Active filters display (only shows category and transaction type)
    private var activeFiltersView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if filterState.transactionType != .all {
                        filterTag(
                            icon: filterState.transactionType == .income ? "arrow.down.circle" : "arrow.up.circle",
                            text: filterState.transactionType.rawValue,
                            color: filterState.transactionType == .income ? .green : .red
                        )
                    }
                    
                    if !filterState.selectedCategories.isEmpty {
                        filterTag(
                            icon: "tag",
                            text: "\(filterState.selectedCategories.count) Categories",
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
                .opacity(0.7)
        }
        .background(Color.clear) // Ensure background is clear for smooth animation
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
    
    // Time navigation view with adaptive layout
    private var timeNavigationView: some View {
        HStack {
            Button(action: {
                filterState.timeOffset -= 1
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(viewModel.adaptiveThemeColor)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(10)
                    .background(
                        Circle().fill(viewModel.adaptiveThemeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    )
            }
            
            Spacer()
            
            Text(timePeriodTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
            Button(action: {
                if filterState.timeOffset < 0 {
                    filterState.timeOffset += 1
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(viewModel.adaptiveThemeColor)
                    .font(.system(size: 18, weight: .semibold))
                    .padding(10)
                    .background(
                        Circle().fill(viewModel.adaptiveThemeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    )
            }
            .disabled(filterState.timeOffset == 0)
            .opacity(filterState.timeOffset == 0 ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // Chart type selector
    private var chartTypeSelector: some View {
        HStack(spacing: 12) {
            chartTypeButton(type: "Pie", icon: "chart.pie.fill")
            chartTypeButton(type: "Bar", icon: "chart.bar.fill")
            chartTypeButton(type: "Line", icon: "chart.line.uptrend.xyaxis")
            Spacer()
        }
    }
    
    private func chartTypeButton(type: String, icon: String) -> some View {
        Button(action: { selectedChartStyle = type }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(type)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                selectedChartStyle == type
                ? viewModel.adaptiveThemeColor.opacity(colorScheme == .dark ? 0.3 : 0.2)
                : Color(UIColor.tertiarySystemFill)
            )
            .foregroundColor(
                selectedChartStyle == type
                ? viewModel.adaptiveThemeColor
                : Color(UIColor.secondaryLabel)
            )
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
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
                .background(Color.green.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
                )
                
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
                .background(Color.red.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
                )
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
            .background(viewModel.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
            .shadow(color: viewModel.shadowColor(for: colorScheme), radius: 3, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.adaptiveThemeColor.opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 1)
            )
        }
    }
    
    // No data view
    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 42))
                .foregroundColor(.secondary)
            
            Text("No \(filterState.transactionType == .all ? "" : filterState.transactionType.rawValue.lowercased()) data for this period")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if filterState.hasActiveFilters {
                Button(action: {
                    // Reset filters
                    filterState = AnalyticsFilterState()
                }) {
                    Text("Reset Filters")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(viewModel.adaptiveThemeColor)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 30)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(viewModel.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: viewModel.shadowColor(for: colorScheme), radius: 3, x: 0, y: 2)
    }
    
    // Category pie chart
    @available(iOS 16.0, *)
    private var categoryPieChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chartTitle)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(chartData) { category in
                    SectorMark(
                        angle: .value("Amount", category.amount),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Category", category.category.name))
                    .annotation(position: .overlay) {
                        if category.amount / totalForChart > 0.1 {
                            Text("\(Int(category.amount / totalForChart * 100))%")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .chartForegroundStyleScale(range: ChartColors.adaptiveColorArray(for: colorScheme))
            .frame(height: 240)
        }
        .padding()
        .background(viewModel.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: viewModel.shadowColor(for: colorScheme), radius: 3, x: 0, y: 2)
    }
    
    // Category bar chart
    @available(iOS 16.0, *)
    private var categoryBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chartTitle)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(chartData) { category in
                    BarMark(
                        x: .value("Amount", category.amount),
                        y: .value("Category", category.category.name)
                    )
                    .foregroundStyle(by: .value("Type", category.category.type.rawValue))
                    .annotation(position: .trailing) {
                        Text(formatCurrency(category.amount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartForegroundStyleScale([
                "income": Color.green,
                "expense": Color.red
            ])
            .frame(height: min(CGFloat(chartData.count * 50), 300))
        }
        .padding()
        .background(viewModel.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: viewModel.shadowColor(for: colorScheme), radius: 3, x: 0, y: 2)
    }
    
    // Timeline chart
    @available(iOS 16.0, *)
    private var timelineChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cash Flow Over Time")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(transactionsByDate, id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.amount)
                    )
                    .foregroundStyle(viewModel.adaptiveThemeColor)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.amount)
                    )
                    .foregroundStyle(
                        viewModel.adaptiveThemeColor.opacity(colorScheme == .dark ? 0.25 : 0.2)
                    )
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Amount", dataPoint.amount)
                    )
                    .foregroundStyle(viewModel.adaptiveThemeColor)
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatDateLabel(date))
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .secondary : .primary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text("£\(Int(amount))")
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .secondary : .primary)
                        }
                    }
                }
            }
            .frame(height: 240)
        }
        .padding()
        .background(viewModel.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: viewModel.shadowColor(for: colorScheme), radius: 3, x: 0, y: 2)
    }
    
    // Category spending breakdown section
    private var categorySpendingSection: some View {
        VStack(spacing: 16) {
            if !chartData.isEmpty {
                Text("Category Breakdown")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // List of categories with amounts
                ForEach(chartData) { categorySpending in
                    CategorySpendingRowView(
                        categorySpending: categorySpending,
                        totalAmount: totalForChart,
                        formatCurrency: formatCurrency,
                        colorScheme: colorScheme
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Properties for Charts
    
    private var chartData: [CategorySpending] {
        switch filterState.transactionType {
        case .all:
            return combinedCategoryData
        case .income:
            return incomeByCategory
        case .expense:
            return expensesByCategory
        }
    }
    
    private var totalForChart: Double {
        switch filterState.transactionType {
        case .all:
            return combinedCategoryData.reduce(0) { $0 + $1.amount }
        case .income:
            return totalIncome
        case .expense:
            return totalExpenses
        }
    }
    
    private var chartTitle: String {
        switch filterState.transactionType {
        case .all:
            return "All Transactions by Category"
        case .income:
            return "Income by Category"
        case .expense:
            return "Expenses by Category"
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
}

// MARK: - Supporting Structs

// Preference key to track scroll position
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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
    
    // Add dark mode adapted colors
    static func adaptiveColorArray(for colorScheme: ColorScheme) -> [Color] {
        if colorScheme == .dark {
            return colorArray.map { $0.opacity(0.85) }
        } else {
            return colorArray
        }
    }
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
