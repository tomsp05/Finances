import SwiftUI
import Charts

struct TransactionAnalyticsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // Filter state
    @State private var filterState: AnalyticsFilterState = AnalyticsFilterState()
    
    @State private var showFilterSheet = false
    @State private var selectedChartStyle: String = "Pie"
    
    // State for scroll-based animations
    @State private var scrollOffset: CGFloat = 0
    @State private var initialScrollOffset: CGFloat? = nil

    // MARK: - Computed Properties

    private var headerScale: CGFloat {
        guard let initialOffset = initialScrollOffset else { return 1.0 }
        let delta = scrollOffset - initialOffset
        if delta > 0 {
            let scale = 1.0 + (delta / 500)
            return min(scale, 1.1)
        }
        return 1.0
    }
    
    private var dateRange: (start: Date, end: Date) {
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

    private func getTimeIntervalForFilter() -> TimeInterval {
        switch filterState.timeFilter {
        case .week:       return 7 * 24 * 60 * 60
        case .month:      return 30 * 24 * 60 * 60
        case .yearToDate: return 365 * 24 * 60 * 60
        case .pastYear:   return 365 * 24 * 60 * 60
        case .year:       return 365 * 24 * 60 * 60
        }
    }
    
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
        case .pastYear, .year:
            formatter.dateFormat = "MMM d, yyyy"
            return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
        }
    }
    
    private var filteredTransactions: [Transaction] {
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
    
    private var filteredExpenses: [Transaction] { filteredTransactions.filter { $0.type == .expense } }
    private var filteredIncomes: [Transaction] { filteredTransactions.filter { $0.type == .income } }
    
    private var expensesByCategory: [CategorySpending] {
        Dictionary(grouping: filteredExpenses, by: { $0.categoryId }).compactMap { (id, txns) in
            guard let cat = viewModel.getCategory(id: id) else { return nil }
            return CategorySpending(id: id, category: cat, amount: txns.reduce(0, { $0 + $1.amount }), count: txns.count)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    private var incomeByCategory: [CategorySpending] {
        Dictionary(grouping: filteredIncomes, by: { $0.categoryId }).compactMap { (id, txns) in
            guard let cat = viewModel.getCategory(id: id) else { return nil }
            return CategorySpending(id: id, category: cat, amount: txns.reduce(0, { $0 + $1.amount }), count: txns.count)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    private var combinedCategoryData: [CategorySpending] {
        Dictionary(grouping: filteredTransactions, by: { $0.categoryId }).compactMap { (id, txns) in
            guard let cat = viewModel.getCategory(id: id) else { return nil }
            return CategorySpending(id: id, category: cat, amount: txns.reduce(0, { $0 + $1.amount }), count: txns.count)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    private var transactionsByDate: [(date: Date, amount: Double)] {
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
    
    private var totalExpenses: Double { filteredExpenses.reduce(0, { $0 + $1.amount }) }
    private var totalIncome: Double { filteredIncomes.reduce(0, { $0 + $1.amount }) }
    
    private func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch filterState.timeFilter {
        case .week: formatter.dateFormat = "EEE"
        case .month: formatter.dateFormat = "d"
        case .yearToDate, .pastYear, .year: formatter.dateFormat = "MMM"
        }
        return formatter.string(from: date)
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
                
                ZStack(alignment: .top) {
                    OffsetObservingScrollView(offset: $scrollOffset) {
                        VStack(spacing: 24) {
                            summaryCards.padding(.top, 8)
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
                            Spacer().frame(height: 50)
                        }
                        .padding(.horizontal)
                    }
                    .zIndex(1)
                    .onAppear {
                        initialScrollOffset = nil
                    }
                }
            }
        }
        .navigationTitle("Spending Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: filterButton)
        .sheet(isPresented: $showFilterSheet) {
            NavigationView { AnalyticsFilterView(filterState: $filterState) }
        }
        .onChange(of: filterState) {
            // Persist filter state when it changes
            // DataService.shared.saveAnalyticsFilterState(newValue)
        }
        .onChange(of: scrollOffset) {
            if initialScrollOffset == nil {
                initialScrollOffset = scrollOffset
            }
        }
    }
    
    // MARK: - Component Views & Helpers
    
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
    
    private var filterButton: some View {
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
    
    private var activeFilterCount: Int {
        var count = 0
        if filterState.transactionType != .all { count += 1 }
        if !filterState.selectedCategories.isEmpty { count += 1 }
        return count
    }
    
    private var hasDataForCurrentView: Bool { !chartData.isEmpty }
    
    private var timeNavigationView: some View {
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
    
    private var summaryCards: some View {
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
    
    private var noDataView: some View {
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
    private var categoryPieChart: some View {
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
    private var categoryBarChart: some View {
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
    private var timelineChart: some View {
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
    
    private var categorySpendingSection: some View {
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
    
    private func destinationView(for categorySpending: CategorySpending) -> some View {
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
    
    private var chartData: [CategorySpending] {
        switch filterState.transactionType {
        case .all: return combinedCategoryData
        case .income: return incomeByCategory
        case .expense: return expensesByCategory
        }
    }
    
    private var totalForChart: Double { chartData.reduce(0) { $0 + $1.amount } }
    
    private var chartTitle: String {
        switch filterState.transactionType {
        case .all: return "All Transactions by Category"
        case .income: return "Income by Category"
        case .expense: return "Expenses by Category"
        }
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
