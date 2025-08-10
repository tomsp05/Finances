import SwiftUI
import Charts

struct TransactionAnalyticsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // Filter state
    @State private var filterState: AnalyticsFilterState = AnalyticsFilterState()
    
    @State private var showFilterSheet = false
    @State private var selectedChartStyle: String = "Pie"
    @State private var selectedAnalyticsTab: AnalyticsTab = .overview
    
    // State for scroll-based animations
    @State private var scrollOffset: CGFloat = 0
    @State private var initialScrollOffset: CGFloat? = nil

    // MARK: - Analytics Tabs
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case trends = "Trends"
        case insights = "Insights"
        case comparison = "Compare"
    }

    // MARK: - Computed Properties

    var headerScale: CGFloat {
        guard let initialOffset = initialScrollOffset else { return 1.0 }
        let delta = scrollOffset - initialOffset
        if delta > 0 {
            let scale = 1.0 + (delta / 500)
            return min(scale, 1.1)
        }
        return 1.0
    }
    
    var dateRange: (start: Date, end: Date) {
        var startDate: Date
        var endDate: Date
        let calendar = Calendar.current
        let now = Date()
        
        switch filterState.timeFilter {
        case .week:
            var weekCal = calendar
            weekCal.firstWeekday = 2 // Monday
            guard let thisWeekStart = weekCal.dateInterval(of: .weekOfYear, for: now)?.start else {
                endDate   = now
                startDate = weekCal.date(byAdding: .day, value: -6, to: now)!
                break
            }
            startDate = weekCal.date(byAdding: .weekOfYear, value: filterState.timeOffset, to: thisWeekStart)!
            endDate = weekCal.date(byAdding: .day, value: 6, to: startDate)!
        case .month:
            guard let thisMonthStart = calendar.dateInterval(of: .month, for: now)?.start else {
                endDate   = now
                startDate = calendar.date(byAdding: .day, value: -29, to: now)!
                break
            }
            startDate = calendar.date(byAdding: .month, value: filterState.timeOffset, to: thisMonthStart)!
            if filterState.timeOffset == 0 {
                endDate = now
            } else {
                let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: startDate)!
                endDate = nextMonthStart.addingTimeInterval(-1)
            }
        case .yearToDate:
            endDate = now.addingTimeInterval(Double(filterState.timeOffset) * getTimeIntervalForFilter())
            var comps = calendar.dateComponents([.year], from: endDate)
            comps.month = 1
            comps.day   = 1
            startDate = calendar.date(from: comps)!
        case .pastYear:
            endDate = now.addingTimeInterval(Double(filterState.timeOffset) * getTimeIntervalForFilter())
            let comps = calendar.dateComponents([.year, .month], from: endDate)
            let monthStart = calendar.date(from: comps)!
            startDate = calendar.date(byAdding: .year, value: -1, to: monthStart)!
        case .year:
            endDate   = now.addingTimeInterval(Double(filterState.timeOffset) * getTimeIntervalForFilter())
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        }
        
        return (start: startDate, end: endDate)
    }
    
    // Previous period for comparison
    var previousDateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 0
        let previousEnd = calendar.date(byAdding: .day, value: -1, to: dateRange.start)!
        let previousStart = calendar.date(byAdding: .day, value: -daysBetween, to: previousEnd)!
        return (start: previousStart, end: previousEnd)
    }

    func getTimeIntervalForFilter() -> TimeInterval {
        switch filterState.timeFilter {
        case .week:       return 7 * 24 * 60 * 60
        case .month:      return 30 * 24 * 60 * 60
        case .yearToDate: return 365 * 24 * 60 * 60
        case .pastYear:   return 365 * 24 * 60 * 60
        case .year:       return 365 * 24 * 60 * 60
        }
    }
    
    var timePeriodTitle: String {
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
        case .pastYear, .year:
            formatter.dateFormat = "MMM d, yyyy"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        }
    }
    
    var filteredTransactions: [Transaction] {
        return viewModel.transactions.filter { transaction in
            let isInTimeRange = transaction.date >= dateRange.start && transaction.date <= dateRange.end
            
            let matchesType: Bool
            switch filterState.transactionType {
            case .all: matchesType = true
            case .income: matchesType = transaction.type == .income
            case .expense: matchesType = transaction.type == .expense
            }
            
            let matchesCategory = filterState.selectedCategories.isEmpty || filterState.selectedCategories.contains(transaction.categoryId)
            
            return isInTimeRange && matchesType && matchesCategory
        }
    }
    
    var previousPeriodTransactions: [Transaction] {
        return viewModel.transactions.filter { transaction in
            let isInTimeRange = transaction.date >= previousDateRange.start && transaction.date <= previousDateRange.end
            
            let matchesType: Bool
            switch filterState.transactionType {
            case .all: matchesType = true
            case .income: matchesType = transaction.type == .income
            case .expense: matchesType = transaction.type == .expense
            }
            
            let matchesCategory = filterState.selectedCategories.isEmpty || filterState.selectedCategories.contains(transaction.categoryId)
            
            return isInTimeRange && matchesType && matchesCategory
        }
    }
    
    var filteredExpenses: [Transaction] { filteredTransactions.filter { $0.type == .expense } }
    var filteredIncomes: [Transaction] { filteredTransactions.filter { $0.type == .income } }
    
    var previousExpenses: [Transaction] { previousPeriodTransactions.filter { $0.type == .expense } }
    var previousIncomes: [Transaction] { previousPeriodTransactions.filter { $0.type == .income } }
    
    var expensesByCategory: [CategorySpending] {
        Dictionary(grouping: filteredExpenses, by: { $0.categoryId }).compactMap { (id, txns) in
            guard let cat = viewModel.getCategory(id: id) else { return nil }
            return CategorySpending(id: id, category: cat, amount: txns.reduce(0, { $0 + $1.amount }), count: txns.count)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    var incomeByCategory: [CategorySpending] {
        Dictionary(grouping: filteredIncomes, by: { $0.categoryId }).compactMap { (id, txns) in
            guard let cat = viewModel.getCategory(id: id) else { return nil }
            return CategorySpending(id: id, category: cat, amount: txns.reduce(0, { $0 + $1.amount }), count: txns.count)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    var combinedCategoryData: [CategorySpending] {
        Dictionary(grouping: filteredTransactions, by: { $0.categoryId }).compactMap { (id, txns) in
            guard let cat = viewModel.getCategory(id: id) else { return nil }
            return CategorySpending(id: id, category: cat, amount: txns.reduce(0, { $0 + $1.amount }), count: txns.count)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    var transactionsByDate: [(date: Date, amount: Double)] {
        let calendar = Calendar.current
        let groupingBlock: (Transaction) -> Date = { transaction in
            if [.yearToDate, .pastYear, .year].contains(filterState.timeFilter) {
                var components = calendar.dateComponents([.year, .month], from: transaction.date)
                components.day = 1
                return calendar.date(from: components) ?? transaction.date
            } else {
                return calendar.startOfDay(for: transaction.date)
            }
        }
        let groups = Dictionary(grouping: filteredTransactions, by: groupingBlock)
            .mapValues { $0.reduce(0) { $0 + ($1.type == .expense ? -$1.amount : $1.amount) } }
        return groups.map { (date: $0.key, amount: $0.value) }.sorted { $0.date < $1.date }
    }
    
    // Enhanced analytics properties
    var totalExpenses: Double { filteredExpenses.reduce(0, { $0 + $1.amount }) }
    var totalIncome: Double { filteredIncomes.reduce(0, { $0 + $1.amount }) }
    var previousTotalExpenses: Double { previousExpenses.reduce(0, { $0 + $1.amount }) }
    var previousTotalIncome: Double { previousIncomes.reduce(0, { $0 + $1.amount }) }
    
    var averageTransactionAmount: Double {
        guard !filteredTransactions.isEmpty else { return 0 }
        return filteredTransactions.reduce(0, { $0 + $1.amount }) / Double(filteredTransactions.count)
    }
    
    var dailyAverageSpending: Double {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
        return totalExpenses / Double(max(days, 1))
    }
    
    var expenseChangePercent: Double {
        guard previousTotalExpenses > 0 else { return totalExpenses > 0 ? 100 : 0 }
        return ((totalExpenses - previousTotalExpenses) / previousTotalExpenses) * 100
    }
    
    var incomeChangePercent: Double {
        guard previousTotalIncome > 0 else { return totalIncome > 0 ? 100 : 0 }
        return ((totalIncome - previousTotalIncome) / previousTotalIncome) * 100
    }
    
    var topSpendingCategory: CategorySpending? { expensesByCategory.first }
    var topIncomeCategory: CategorySpending? { incomeByCategory.first }
    
    var weekdaySpending: [(day: String, amount: Double)] {
        let calendar = Calendar.current
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        
        let groupedByWeekday = Dictionary(grouping: filteredExpenses) { transaction in
            weekdayFormatter.string(from: transaction.date)
        }
        
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return weekdays.map { weekday in
            let amount = groupedByWeekday[weekday]?.reduce(0) { $0 + $1.amount } ?? 0
            return (day: weekday, amount: amount)
        }
    }
    
    var monthlyTrend: [(month: String, income: Double, expenses: Double)] {
        let calendar = Calendar.current
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        
        // Get last 6 months of data
        var months: [(month: String, income: Double, expenses: Double)] = []
        for i in 0..<6 {
            let monthDate = calendar.date(byAdding: .month, value: -i, to: Date()) ?? Date()
            let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start ?? monthDate
            let monthEnd = calendar.dateInterval(of: .month, for: monthDate)?.end ?? monthDate
            
            let monthTransactions = viewModel.transactions.filter { $0.date >= monthStart && $0.date < monthEnd }
            let monthIncome = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let monthExpenses = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            
            months.append((
                month: monthFormatter.string(from: monthDate),
                income: monthIncome,
                expenses: monthExpenses
            ))
        }
        
        return months.reversed()
    }
    
    func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch filterState.timeFilter {
        case .week: formatter.dateFormat = "EEE"
        case .month: formatter.dateFormat = "d"
        case .yearToDate, .pastYear, .year: formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
    }
    
    var filterButton: some View {
        Button(action: { showFilterSheet = true }) {
            HStack(spacing: 5) {
                Image(systemName: "line.3.horizontal.decrease.circle").font(.system(size: 22))
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.caption).fontWeight(.bold).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(viewModel.themeColor).clipShape(Capsule())
                }
            }
        }
    }
    
    var activeFilterCount: Int {
        var count = 0
        if filterState.transactionType != .all { count += 1 }
        if !filterState.selectedCategories.isEmpty { count += 1 }
        return count
    }
    
    var hasDataForCurrentView: Bool { !chartData.isEmpty }
    
    var timeNavigationView: some View {
        HStack {
            Button(action: { filterState.timeOffset -= 1 }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(viewModel.themeColor)
                    .font(.system(size: 16, weight: .medium))
                    .padding(8)
                    .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
            }
            Spacer()
            Text(timePeriodTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Button(action: { if filterState.timeOffset < 0 { filterState.timeOffset += 1 } }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(viewModel.themeColor)
                    .font(.system(size: 16, weight: .medium))
                    .padding(8)
                    .background(Circle().fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1)))
            }
            .disabled(filterState.timeOffset == 0).opacity(filterState.timeOffset == 0 ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    var chartTypeSelector: some View {
        HStack(spacing: 12) {
            chartTypeButton(type: "Pie", icon: "chart.pie.fill")
            chartTypeButton(type: "Bar", icon: "chart.bar.fill")
            chartTypeButton(type: "Line", icon: "chart.line.uptrend.xyaxis")
            Spacer()
        }
    }
    
    func chartTypeButton(type: String, icon: String) -> some View {
        Button(action: { selectedChartStyle = type }) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14))
                Text(type).font(.subheadline)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(selectedChartStyle == type ? viewModel.themeColor.opacity(colorScheme == .dark ? 0.3 : 0.2) : Color(UIColor.tertiarySystemFill))
            .foregroundColor(selectedChartStyle == type ? viewModel.themeColor : Color(UIColor.secondaryLabel))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var summaryCards: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Income").font(.subheadline).foregroundColor(.secondary)
                    Text(viewModel.formatCurrency(totalIncome)).font(.title2).fontWeight(.bold).foregroundColor(.green)
                    Text("\(filteredIncomes.count) transactions").font(.caption).foregroundColor(.secondary)
                }
                .padding().frame(maxWidth: .infinity).background(Color.green.opacity(colorScheme == .dark ? 0.2 : 0.1)).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1))
                
                VStack(spacing: 4) {
                    Text("Expenses").font(.subheadline).foregroundColor(.secondary)
                    Text(viewModel.formatCurrency(totalExpenses)).font(.title2).fontWeight(.bold).foregroundColor(.red)
                    Text("\(filteredExpenses.count) transactions").font(.caption).foregroundColor(.secondary)
                }
                .padding().frame(maxWidth: .infinity).background(Color.red.opacity(colorScheme == .dark ? 0.2 : 0.1)).cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1))
            }
            VStack(spacing: 4) {
                Text("Net Savings").font(.subheadline).foregroundColor(.secondary)
                Text(viewModel.formatCurrency(totalIncome - totalExpenses)).font(.title2).fontWeight(.bold).foregroundColor(totalIncome >= totalExpenses ? .green : .red)
                let savingsPercentage = totalIncome > 0 ? (totalIncome - totalExpenses) / totalIncome * 100 : 0
                Text(String(format: "%.1f%% of income", savingsPercentage)).font(.caption).foregroundColor(.secondary)
            }
            .padding().frame(maxWidth: .infinity).background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 1)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(viewModel.themeColor.opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 1))
        }
    }
    
    var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis").font(.system(size: 42)).foregroundColor(.secondary)
            Text("No \(filterState.transactionType == .all ? "" : filterState.transactionType.rawValue.lowercased()) data for this period").font(.headline).foregroundColor(.secondary)
            if filterState.selectedCategories.count > 0 || filterState.transactionType != .all {
                Button(action: { filterState = AnalyticsFilterState() }) {
                    Text("Reset Filters").font(.subheadline).foregroundColor(.white).padding(.horizontal, 16).padding(.vertical, 8)
                        .background(viewModel.themeColor).cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 30).padding(.horizontal).frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    @available(iOS 16.0, *)
    var categoryPieChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chartTitle).font(.headline).foregroundColor(.secondary)
            Chart {
                ForEach(chartData) { category in
                    SectorMark(angle: .value("Amount", category.amount), innerRadius: .ratio(0.6), angularInset: 1.5)
                        .foregroundStyle(by: .value("Category", category.category.name))
                        .annotation(position: .overlay) {
                            if category.amount / totalForChart > 0.1 { Text("\(Int(category.amount / totalForChart * 100))%").font(.caption).bold().foregroundColor(.white) }
                        }
                }
            }
            .chartForegroundStyleScale(range: ChartColors.adaptiveColorArray(for: colorScheme))
            .frame(height: 240)
        }
        .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    @available(iOS 16.0, *)
    var categoryBarChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chartTitle).font(.headline).foregroundColor(.secondary)
            Chart {
                ForEach(chartData) { category in
                    BarMark(x: .value("Amount", category.amount), y: .value("Category", category.category.name))
                        .foregroundStyle(by: .value("Type", category.category.type.rawValue))
                        .annotation(position: .trailing) { Text(viewModel.formatCurrency(category.amount)).font(.caption).foregroundColor(.secondary) }
                }
            }
            .chartForegroundStyleScale(["income": Color.green, "expense": Color.red])
            .frame(height: min(CGFloat(chartData.count * 50), 300))
        }
        .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    @available(iOS 16.0, *)
    var timelineChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cash Flow Over Time").font(.headline).foregroundColor(.secondary)
            Chart {
                ForEach(transactionsByDate, id: \.date) { dataPoint in
                    LineMark(x: .value("Date", dataPoint.date), y: .value("Amount", dataPoint.amount))
                        .foregroundStyle(viewModel.themeColor).interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Date", dataPoint.date), y: .value("Amount", dataPoint.amount))
                        .foregroundStyle(viewModel.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.2)).interpolationMethod(.catmullRom)
                    PointMark(x: .value("Date", dataPoint.date), y: .value("Amount", dataPoint.amount))
                        .foregroundStyle(viewModel.themeColor)
                }
            }
            .chartXAxis { AxisMarks { value in if let date = value.as(Date.self) { AxisValueLabel { Text(formatDateLabel(date)) } } } }
            .chartYAxis { AxisMarks { value in if let amount = value.as(Double.self) { AxisValueLabel { Text("\(viewModel.userPreferences.currency.rawValue)\(Int(amount))") } } } }
            .frame(height: 240)
        }
        .padding().background(Color(UIColor.secondarySystemBackground)).cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    var categorySpendingSection: some View {
        VStack(spacing: 16) {
            if !chartData.isEmpty {
                Text("Category Breakdown")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(chartData) { categorySpending in
                    NavigationLink(destination: destinationView(for: categorySpending)) {
                        CategorySpendingRowView(
                            categorySpending: categorySpending,
                            totalAmount: totalForChart,
                            formatCurrency: viewModel.formatCurrency,
                            colorScheme: colorScheme
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    func destinationView(for categorySpending: CategorySpending) -> some View {
        var transactionFilter = TransactionFilterState()

        transactionFilter.timeFilter = .custom
        transactionFilter.customStartDate = self.dateRange.start
        transactionFilter.customEndDate = self.dateRange.end
        transactionFilter.selectedCategories = [categorySpending.category.id]

        if categorySpending.category.type == .income {
            transactionFilter.transactionTypes = [.income]
        } else {
            transactionFilter.transactionTypes = [.expense]
        }
        
        return TransactionsListView(initialFilterState: transactionFilter)
    }
    
    var chartData: [CategorySpending] {
        switch filterState.transactionType {
        case .all: return combinedCategoryData
        case .income: return incomeByCategory
        case .expense: return expensesByCategory
        }
    }
    
    var totalForChart: Double { chartData.reduce(0) { $0 + $1.amount } }
    
    var chartTitle: String {
        switch filterState.transactionType {
        case .all: return "All Transactions by Category"
        case .income: return "Income by Category"
        case .expense: return "Expenses by Category"
        }
    }

    // MARK: - Analytics Tab Views
    
    var overviewContent: some View {
        VStack(spacing: 24) {
            summaryCards
            chartTypeSelector
            
            if !hasDataForCurrentView {
                noDataView
            } else {
                if selectedChartStyle == "Pie" {
                    if #available(iOS 16.0, *) { categoryPieChart } else { Text("Pie charts require iOS 16") }
                } else if selectedChartStyle == "Bar" {
                    if #available(iOS 16.0, *) { categoryBarChart } else { Text("Bar charts require iOS 16") }
                } else if selectedChartStyle == "Line" {
                    if #available(iOS 16.0, *) { timelineChart } else { Text("Line charts require iOS 16") }
                }
            }
            
            categorySpendingSection
        }
    }
    
    var trendsContent: some View {
        VStack(spacing: 24) {
            if !hasDataForCurrentView {
                noDataView
            } else {
                trendAnalysisCards
                
                if #available(iOS 16.0, *) {
                    monthlyTrendChart
                    weekdaySpendingChart
                    cumulativeSpendingChart
                } else {
                    Text("Charts require iOS 16")
                }
            }
        }
    }
    
    var insightsContent: some View {
        VStack(spacing: 24) {
            if !hasDataForCurrentView {
                noDataView
            } else {
                insightCards
                spendingPatternsSection
                budgetAnalysisSection
            }
        }
    }
    
    var comparisonContent: some View {
        VStack(spacing: 24) {
            if !hasDataForCurrentView {
                noDataView
            } else {
                periodComparisonCards
                
                if #available(iOS 16.0, *) {
                    categoryComparisonChart
                } else {
                    Text("Charts require iOS 16")
                }
                
                detailedComparisonSection
            }
        }
    }
    
    // MARK: - Enhanced Component Views
    
    var analyticsTabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedAnalyticsTab = tab }) {
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: tabIcon(for: tab))
                                    .font(.system(size: 14))
                                Text(tab.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(selectedAnalyticsTab == tab ? viewModel.themeColor : Color.clear)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundColor(selectedAnalyticsTab == tab ? viewModel.themeColor : Color.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    func tabIcon(for tab: AnalyticsTab) -> String {
        switch tab {
        case .overview: return "chart.pie.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .insights: return "lightbulb.fill"
        case .comparison: return "rectangle.split.2x1.fill"
        }
    }
    
    var trendAnalysisCards: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .foregroundColor(expenseChangePercent >= 0 ? .red : .green)
                        Text("Expense Trend")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Text(String(format: "%.1f%%", abs(expenseChangePercent)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(expenseChangePercent >= 0 ? .red : .green)
                    Text("vs. previous period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "calendar.day.timeline.leading")
                            .foregroundColor(viewModel.themeColor)
                        Text("Daily Average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    Text(viewModel.formatCurrency(dailyAverageSpending))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("spending per day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    @available(iOS 16.0, *)
    var monthlyTrendChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("6-Month Trend")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(monthlyTrend, id: \.month) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Income", data.income)
                    )
                    .foregroundStyle(Color.green)
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Expenses", data.expenses)
                    )
                    .foregroundStyle(Color.red)
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartForegroundStyleScale([
                "Income": Color.green,
                "Expenses": Color.red
            ])
            .frame(height: 200)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    @available(iOS 16.0, *)
    var weekdaySpendingChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spending by Day of Week")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Chart {
                ForEach(weekdaySpending, id: \.day) { data in
                    BarMark(
                        x: .value("Day", String(data.day.prefix(3))),
                        y: .value("Amount", data.amount)
                    )
                    .foregroundStyle(viewModel.themeColor.gradient)
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    @available(iOS 16.0, *)
    var cumulativeSpendingChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cumulative Spending")
                .font(.headline)
                .foregroundColor(.secondary)
            
            let cumulativeData = filteredExpenses
                .sorted { $0.date < $1.date }
                .reduce(into: [(date: Date, cumulative: Double)]()) { result, transaction in
                    let previousTotal = result.last?.cumulative ?? 0
                    result.append((date: transaction.date, cumulative: previousTotal + transaction.amount))
                }
            
            Chart {
                ForEach(cumulativeData, id: \.date) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Cumulative", data.cumulative)
                    )
                    .foregroundStyle(viewModel.themeColor)
                    .interpolationMethod(.monotone)
                    
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Cumulative", data.cumulative)
                    )
                    .foregroundStyle(viewModel.themeColor.opacity(0.2))
                    .interpolationMethod(.monotone)
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    var insightCards: some View {
        VStack(spacing: 16) {
            Text("Key Insights")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let topCategory = topSpendingCategory {
                InsightCard(
                    icon: "crown.fill",
                    title: "Top Spending Category",
                    value: topCategory.category.name,
                    subtitle: "\(viewModel.formatCurrency(topCategory.amount)) • \(topCategory.count) transactions",
                    color: .orange,
                    colorScheme: colorScheme
                )
            }
            
            InsightCard(
                icon: "calendar",
                title: "Average Transaction",
                value: viewModel.formatCurrency(averageTransactionAmount),
                subtitle: "across \(filteredTransactions.count) transactions",
                color: viewModel.themeColor,
                colorScheme: colorScheme
            )
            
            if totalIncome > 0 {
                let savingsRate: Double = totalIncome != 0 ? ((totalIncome - totalExpenses) / totalIncome) * 100 : 0
                InsightCard(
                    icon: "percent",
                    title: "Savings Rate",
                    value: String(format: "%.1f%%", savingsRate),
                    subtitle: savingsRate > 20 ? "Great job!" : "Consider saving more",
                    color: savingsRate > 20 ? .green : .yellow,
                    colorScheme: colorScheme
                )
            }
        }
    }
    
    var spendingPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Patterns")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                if let highestDay = weekdaySpending.max(by: { $0.amount < $1.amount }) {
                    PatternRow(
                        icon: "calendar.day.timeline.leading",
                        title: "Highest Spending Day",
                        value: highestDay.day,
                        amount: viewModel.formatCurrency(highestDay.amount),
                        color: .red
                    )
                }
                
                if filteredExpenses.count > 0 {
                    let dayCount: Int = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
                    let avgTransactionsPerDay = Double(filteredExpenses.count) / Double(max(dayCount, 1))
                    PatternRow(
                        icon: "chart.bar",
                        title: "Avg Transactions/Day",
                        value: String(format: "%.1f", avgTransactionsPerDay),
                        amount: "",
                        color: viewModel.themeColor
                    )
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    @available(iOS 16.0, *)
    var categoryComparisonChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category Comparison")
                .font(.headline)
                .foregroundColor(.secondary)
            
            let topCategories = expensesByCategory.prefix(5)
            let previousCategoriesDict = Dictionary(grouping: previousExpenses, by: { $0.categoryId })
                .mapValues { $0.reduce(0, { $0 + $1.amount }) }
            
            Chart {
                ForEach(topCategories, id: \.id) { categorySpending in
                    let previousAmount = previousCategoriesDict[categorySpending.id] ?? 0
                    
                    BarMark(
                        x: .value("Amount", categorySpending.amount),
                        y: .value("Category", categorySpending.category.name),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(viewModel.themeColor)
                    .position(by: .value("Period", "Current"))
                    
                    BarMark(
                        x: .value("Amount", previousAmount),
                        y: .value("Category", categorySpending.category.name),
                        width: .ratio(0.4)
                    )
                    .foregroundStyle(Color.gray.opacity(0.6))
                    .position(by: .value("Period", "Previous"))
                }
            }
            .chartForegroundStyleScale([
                "Current": viewModel.themeColor,
                "Previous": Color.gray.opacity(0.6)
            ])
            .frame(height: min(CGFloat(topCategories.count * 60), 300))
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    var detailedComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Comparison")
                .font(.headline)
                .foregroundColor(.secondary)
            
            comparisonDetailRows
        }
    }
    
    var comparisonDetailRows: some View {
        let transactionCountRow = ComparisonDetailRow(
            title: "Transaction Count",
            current: "\(filteredTransactions.count)",
            previous: "\(previousPeriodTransactions.count)",
            icon: "number",
            themeColor: viewModel.themeColor
        )
        
        let previousAvgTransaction: Double = {
            if previousPeriodTransactions.isEmpty { return 0 }
            return previousPeriodTransactions.reduce(0, { $0 + $1.amount }) / Double(previousPeriodTransactions.count)
        }()
        let avgTransactionRow = ComparisonDetailRow(
            title: "Average Transaction",
            current: viewModel.formatCurrency(averageTransactionAmount),
            previous: viewModel.formatCurrency(previousAvgTransaction),
            icon: "chart.bar.fill",
            themeColor: viewModel.themeColor
        )
        
        let topCategoryName = topSpendingCategory?.category.name ?? "N/A"
        let previousCategoryGroups = Dictionary(grouping: previousExpenses, by: { $0.categoryId })
        let previousCategoryTotals = previousCategoryGroups.mapValues { $0.reduce(0, { $0 + $1.amount }) }
        let previousTopCategoryId = previousCategoryTotals.max(by: { $0.value < $1.value })?.key
        let previousTopCategoryName = previousTopCategoryId.flatMap { viewModel.getCategory(id: $0)?.name } ?? "N/A"
        let topCategoryRow = ComparisonDetailRow(
            title: "Top Category",
            current: topCategoryName,
            previous: previousTopCategoryName,
            icon: "crown.fill",
            themeColor: viewModel.themeColor
        )
        
        return VStack(spacing: 12) {
            transactionCountRow
            avgTransactionRow
            topCategoryRow
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    var budgetAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Analysis")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                ForEach(expensesByCategory.prefix(3)) { categorySpending in
                    BudgetAnalysisRow(
                        categorySpending: categorySpending,
                        formatCurrency: viewModel.formatCurrency,
                        themeColor: viewModel.themeColor,
                        colorScheme: colorScheme
                    )
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    var periodComparisonCards: some View {
        VStack(spacing: 16) {
            Text("Period Comparison")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ComparisonCard(
                        title: "Income",
                        current: totalIncome,
                        previous: previousTotalIncome,
                        formatCurrency: viewModel.formatCurrency,
                        color: .green,
                        colorScheme: colorScheme
                    )
                    
                    ComparisonCard(
                        title: "Expenses",
                        current: totalExpenses,
                        previous: previousTotalExpenses,
                        formatCurrency: viewModel.formatCurrency,
                        color: .red,
                        colorScheme: colorScheme
                    )
                }
                
                ComparisonCard(
                    title: "Net Savings",
                    current: totalIncome - totalExpenses,
                    previous: previousTotalIncome - previousTotalExpenses,
                    formatCurrency: viewModel.formatCurrency,
                    color: viewModel.themeColor,
                    colorScheme: colorScheme
                )
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .top) {
            viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea()
            
            VStack(spacing: 0) {
                timeNavigationView
                    .scaleEffect(headerScale)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: headerScale)
                    .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    .zIndex(2)
                
                analyticsTabSelector
                    .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.1 : 0.05))
                    .zIndex(2)
                
                ZStack(alignment: .top) {
                    OffsetObservingScrollView(offset: $scrollOffset) {
                        VStack(spacing: 24) {
                            switch selectedAnalyticsTab {
                            case .overview:
                                overviewContent
                            case .trends:
                                trendsContent
                            case .insights:
                                insightsContent
                            case .comparison:
                                comparisonContent
                            }
                            
                            Spacer().frame(height: 50)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .zIndex(1)
                    .onAppear {
                        initialScrollOffset = nil
                    }
                }
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: filterButton)
        .sheet(isPresented: $showFilterSheet) {
            NavigationView { AnalyticsFilterView(filterState: $filterState) }
        }
        .onChange(of: filterState) { _ in
            // Persist filter state when it changes
        }
        .onChange(of: scrollOffset) { newValue in
            if initialScrollOffset == nil {
                initialScrollOffset = newValue
            }
        }
    }
    
    // MARK: - Supporting Views
    
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
                    GeometryReader { geo in Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: geo.frame(in: .global).minY) }
                        .frame(height: 0)
                    content
                }
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
        }
    }
}

// MARK: - Supporting Views Outside Main Struct

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(colorScheme == .dark ? 0.2 : 0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct PatternRow: View {
    let icon: String
    let title: String
    let value: String
    let amount: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text(value)
                        .font(.headline)
                        .fontWeight(.semibold)
                    if !amount.isEmpty {
                        Text(amount)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
        }
    }
}

struct BudgetAnalysisRow: View {
    let categorySpending: CategorySpending
    let formatCurrency: (Double) -> String
    let themeColor: Color
    let colorScheme: ColorScheme
    
    private var recommendedBudget: Double {
        // Simple heuristic: suggest 20% more than current spending
        return categorySpending.amount * 1.2
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(categorySpending.category.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(formatCurrency(categorySpending.amount))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Suggested budget:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(recommendedBudget))
                        .font(.caption)
                        .foregroundColor(themeColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(themeColor)
                            .frame(width: geometry.size.width * min(categorySpending.amount / recommendedBudget, 1.0), height: 4)
                    }
                    .cornerRadius(2)
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ComparisonCard: View {
    let title: String
    let current: Double
    let previous: Double
    let formatCurrency: (Double) -> String
    let color: Color
    let colorScheme: ColorScheme
    
    private var changePercent: Double {
        guard previous != 0 else { return current > 0 ? 100 : 0 }
        return ((current - previous) / previous) * 100
    }
    
    private var isPositiveChange: Bool {
        title == "Income" ? changePercent >= 0 : changePercent <= 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: changePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                        .foregroundColor(isPositiveChange ? .green : .red)
                    Text(String(format: "%.1f%%", abs(changePercent)))
                        .font(.caption)
                        .foregroundColor(isPositiveChange ? .green : .red)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(current))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                }
                
                HStack {
                    Text("Previous")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatCurrency(previous))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct ComparisonDetailRow: View {
    let title: String
    let current: String
    let previous: String
    let icon: String
    let themeColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(themeColor)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(current)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(previous)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Structs

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct CategorySpending: Identifiable {
    let id: UUID
    let category: Category
    let amount: Double
    let count: Int
}

struct ChartColors {
    static let colorArray: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .yellow, .pink, .cyan, .indigo, .mint, .brown]
    static func adaptiveColorArray(for colorScheme: ColorScheme) -> [Color] {
        colorScheme == .dark ? colorArray.map { $0.opacity(0.85) } : colorArray
    }
}

