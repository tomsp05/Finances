import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var showingEditSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    // Animation state
    @State private var isAppearing: Bool = false

    var budget: Budget
    
    // The actual budget might update in the ViewModel, need to find it
    private var currentBudget: Budget {
        viewModel.budgets.first(where: { $0.id == budget.id }) ?? budget
    }
    
    // 1. Corrected logic to get transactions only for the current budget period
    private var relevantTransactions: [Transaction] {
        guard let periodStartDate = currentBudget.periodStartDate else { return [] }
        let periodEndDate = currentBudget.timePeriod.getNextResetDate(from: periodStartDate)

        // Filter transactions that fall within the current budget period
        let transactionsInPeriod = viewModel.transactions.filter {
            $0.type == .expense && $0.date >= periodStartDate && $0.date < periodEndDate
        }
        
        let filteredTransactions: [Transaction]
        switch currentBudget.type {
        case .overall:
            filteredTransactions = transactionsInPeriod
            
        case .category:
            guard let categoryId = currentBudget.categoryId else { return [] }
            filteredTransactions = transactionsInPeriod.filter { $0.categoryId == categoryId }
            
        case .account:
            guard let accountId = currentBudget.accountId else { return [] }
            filteredTransactions = transactionsInPeriod.filter { $0.fromAccountId == accountId }
        }
        
        return filteredTransactions.sorted { $0.date > $1.date }
    }

    // 2. New logic to group the relevant transactions by week
    private var weeklyGroupedTransactions: [(weekDescription: String, transactions: [Transaction])] {
        guard !relevantTransactions.isEmpty else { return [] }

        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        let now = Date()

        let groupedByWeek = Dictionary(grouping: relevantTransactions) { transaction -> Date in
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: transaction.date)
            return calendar.date(from: components) ?? transaction.date
        }

        let sortedGroups = groupedByWeek.sorted { $0.key > $1.key }

        return sortedGroups.map { (weekStartDate, transactions) in
            let description = formatWeekDescription(for: weekStartDate, calendar: calendar, now: now)
            return (weekDescription: description, transactions: transactions)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Budget overview card with circular progress
                budgetOverviewCard
                
                // Budget details
                budgetDetailsCard
                
                // Recent transactions, now grouped by week
                recentTransactionsSection
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(currentBudget.name)
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("Edit")
                        .foregroundColor(viewModel.themeColor)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                BudgetEditView(isPresented: $showingEditSheet, budget: currentBudget)
                    .navigationTitle("Edit Budget")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingEditSheet = false
                        }
                    )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                isAppearing = true
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            // Progress circle with animated appearance
            ZStack {
                // Track Circle
                Circle()
                    .stroke(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .scaleEffect(isAppearing ? 1.0 : 0.8)
                    .opacity(isAppearing ? 1.0 : 0.0)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: CGFloat(min(currentBudget.percentUsed, 1.0)))
                    .stroke(getProgressColor(), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut.delay(0.3), value: currentBudget.percentUsed)
                    .scaleEffect(isAppearing ? 1.0 : 0.8)
                    .opacity(isAppearing ? 1.0 : 0.0)
                
                // Center text
                VStack(spacing: 4) {
                    Text("\(Int(currentBudget.percentUsed * 100))%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    Text("Used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
            }
            .padding(20)
            
            // Budget amount info cards
            HStack(spacing: 0) {
                // Budget amount
                VStack(spacing: 6) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentBudget.amount))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
                
                Spacer()
                    .frame(width: 12)
                
                // Spent amount
                VStack(spacing: 6) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentBudget.currentSpent))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
                
                Spacer()
                    .frame(width: 12)
                
                // Remaining amount
                VStack(spacing: 6) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentBudget.remainingAmount))
                        .font(.headline)
                        .foregroundColor(getBudgetStatusColor())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.green.opacity(colorScheme == .dark ? 0.15 : 0.1))
                )
            }
            .padding(.horizontal, 10)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(getProgressColor().opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top)
        .offset(y: isAppearing ? 0 : 20)
        .opacity(isAppearing ? 1.0 : 0.0)
    }
    
    private var budgetDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Details")
                .font(.headline)
                .padding(.horizontal)
                .opacity(isAppearing ? 1.0 : 0.0)
                .offset(y: isAppearing ? 0 : 10)
            
            VStack(spacing: 0) {
                detailRow(title: "Type", value: getBudgetTypeText())
                
                Divider()
                    .padding(.leading, 120)
                
                detailRow(title: "Period", value: currentBudget.timePeriod.displayName())
                
                Divider()
                    .padding(.leading, 120)
                
                detailRow(title: "Started On", value: formatDate(currentBudget.startDate))
                
                // Show specific details based on budget type
                if currentBudget.type == .category, let categoryId = currentBudget.categoryId,
                   let category = viewModel.getCategory(id: categoryId) {
                    Divider()
                        .padding(.leading, 120)
                    
                    detailRow(title: "Category", value: category.name, iconName: category.iconName)
                }
                
                if currentBudget.type == .account, let accountId = currentBudget.accountId,
                   let account = viewModel.accounts.first(where: { $0.id == accountId }) {
                    Divider()
                        .padding(.leading, 120)
                    
                    detailRow(title: "Account", value: account.name, iconName: getAccountIcon(account.type))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal)
            .offset(y: isAppearing ? 0 : 20)
            .opacity(isAppearing ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isAppearing)
        }
    }
    
    private func detailRow(title: String, value: String, iconName: String? = nil) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            if let icon = iconName {
                Image(systemName: icon)
                    .foregroundColor(viewModel.themeColor)
                    .font(.system(size: 14))
                    .padding(.trailing, 4)
            }
            
            Text(value)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    // 3. Updated this section to use the new weekly grouped data
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transactions This Period")
                .font(.headline)
                .padding(.horizontal)
                .opacity(isAppearing ? 1.0 : 0.0)
                .offset(y: isAppearing ? 0 : 10)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: isAppearing)
            
            if weeklyGroupedTransactions.isEmpty {
                emptyTransactionsView
            } else {
                transactionsList
            }
        }
    }
    
    private var emptyTransactionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No transactions in this period yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1), lineWidth: 1)
        )
        .padding(.horizontal)
        .offset(y: isAppearing ? 0 : 20)
        .opacity(isAppearing ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: isAppearing)
    }
    
    private var transactionsList: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(Array(weeklyGroupedTransactions.enumerated()), id: \.element.weekDescription) { weekIndex, group in
                Section(header:
                    Text(group.weekDescription)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top, weekIndex > 0 ? 16 : 0) // Add top padding for subsequent sections
                        .padding(.horizontal)
                ) {
                    ForEach(Array(group.transactions.enumerated()), id: \.element.id) { transactionIndex, transaction in
                        NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                            TransactionCardView(transaction: transaction)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .offset(y: isAppearing ? 0 : 20)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(0.4 + Double(weekIndex) * 0.1 + Double(transactionIndex) * 0.05),
                            value: isAppearing
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // 4. New helper function to format the week's description
    private func formatWeekDescription(for weekStartDate: Date, calendar: Calendar, now: Date) -> String {
        let currentWeekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        
        if calendar.isDate(weekStartDate, inSameDayAs: currentWeekStartDate) {
            return "This Week"
        }
        
        let lastWeekStartDate = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStartDate)!
        if calendar.isDate(weekStartDate, inSameDayAs: lastWeekStartDate) {
            return "Last Week"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        guard let endDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return dateFormatter.string(from: weekStartDate)
        }
        
        return "\(dateFormatter.string(from: weekStartDate)) - \(dateFormatter.string(from: endDate))"
    }

    private func getBudgetTypeText() -> String {
        switch currentBudget.type {
        case .overall: return "Overall"
        case .category: return "Category"
        case .account: return "Account"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getProgressColor() -> Color {
        let percentUsed = currentBudget.percentUsed
        
        if percentUsed >= 1.0 {
            return .red
        } else if percentUsed >= 0.85 {
            return .orange
        } else if percentUsed >= 0.7 {
            return .yellow
        } else {
            return viewModel.themeColor
        }
    }
    
    private func getBudgetStatusColor() -> Color {
        let percentUsed = currentBudget.percentUsed
        
        if percentUsed >= 1.0 {
            return .red
        } else if percentUsed >= 0.85 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getAccountIcon(_ type: AccountType) -> String {
        switch type {
        case .savings: return "building.columns.fill"
        case .current: return "banknote.fill"
        case .credit: return "creditcard.fill"
        }
    }
}
