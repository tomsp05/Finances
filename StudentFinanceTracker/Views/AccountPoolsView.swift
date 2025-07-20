import SwiftUI

struct AccountPoolsView: View {
    let account: Account
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme

    // Pool assignment state
    @State private var accountPools: [Pool] = []
    @State private var showAddPoolSheet = false
    @State private var newPoolName = ""
    @State private var newPoolAmount = ""
    @State private var newPoolColor = "Blue" // Default color
    @State private var showAssignTransactionSheet = false
    @State private var selectedPool: Pool? = nil
    @State private var showPoolTransactionsSheet = false
    @State private var selectedPoolForTransactions: Pool? = nil
    @State private var showInlineAssignment: Bool = false // New state for inline assignment
    @State private var selectedTransaction: Transaction? = nil // New state for inline assignment

    // Available theme colors with their visual representations
    let poolColorOptions = [
        "Blue": Color(red: 0.20, green: 0.40, blue: 0.70),
        "Green": Color(red: 0.20, green: 0.55, blue: 0.30),
        "Orange": Color(red: 0.80, green: 0.40, blue: 0.20),
        "Purple": Color(red: 0.50, green: 0.25, blue: 0.70),
        "Red": Color(red: 0.70, green: 0.20, blue: 0.20),
        "Teal": Color(red: 0.20, green: 0.50, blue: 0.60)
    ]

    private var unallocatedBalance: Double {
        let totalAllocated = accountPools.reduce(0.0) { $0 + $1.amount }
        return account.balance - totalAllocated
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Account details
                VStack(spacing: 12) {
                    Text(viewModel.formatCurrency(account.balance))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.vertical, 8)

                    Text("Account Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Pools section
                poolsSection

                // Quick Assignment Section (inline)
                if !accountPools.isEmpty {
                    quickAssignmentSection
                }

                // Add pool button
                addPoolButton
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("\(account.name) Pools")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showAddPoolSheet) { addPoolSheet }
        .sheet(isPresented: $showAssignTransactionSheet) {
            assignTransactionSheet
                .onAppear {
                    // Refresh data when assignment sheet opens
                    refreshData()
                }
        }
        .sheet(isPresented: $showPoolTransactionsSheet) {
            poolTransactionsSheet
                .onAppear {
                    // Refresh data when transactions sheet opens
                    refreshData()
                }
        }
        .onAppear(perform: refreshData)
        // Add onChange to refresh when returning from sheets
        .onChange(of: showAssignTransactionSheet) { isShowing in
            if !isShowing {
                refreshData()
            }
        }
        .onChange(of: showPoolTransactionsSheet) { isShowing in
            if !isShowing {
                refreshData()
            }
        }
    }

    // MARK: - Main View Components

    private var poolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if accountPools.isEmpty {
                emptyPoolsView
            } else {
                Text("Your Pools")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)

                ForEach(accountPools) { pool in
                    PoolCardView(
                        pool: pool,
                        colorScheme: colorScheme,
                        formatCurrency: viewModel.formatCurrency,
                        poolColor: getPoolColor(pool.color),
                        onDelete: { deletePool(pool) },
                        onSelect: {
                            selectedPoolForTransactions = pool
                            showPoolTransactionsSheet = true
                        },
                        onAssign: {
                            selectedPool = pool
                            showAssignTransactionSheet = true
                        },
                        assignedTransactionCount: viewModel.getTransactionsForPool(pool.id).count
                    )
                }

                poolVisualizationSection
            }
        }
    }

    private var emptyPoolsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 72))
                .foregroundColor(viewModel.themeColor.opacity(0.5))

            Text("No pools yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Create pools to organize your money")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var poolVisualizationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pool Allocation")
                .font(.headline)
                .foregroundColor(.secondary)

            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(accountPools) { pool in
                        let proportion = pool.amount / max(0.01, account.balance)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(getPoolColor(pool.color))
                            .frame(width: max(5, geometry.size.width * CGFloat(proportion)))
                            .overlay(Text(proportion > 0.1 ? "\(Int(proportion * 100))%" : "").font(.system(size: 10)).foregroundColor(.white).padding(2))
                    }

                    if unallocatedBalance > 0 {
                        let unallocatedProportion = unallocatedBalance / max(0.01, account.balance)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: max(5, geometry.size.width * CGFloat(unallocatedProportion)))
                            .overlay(Text(unallocatedProportion > 0.1 ? "\(Int(unallocatedProportion * 100))%" : "").font(.system(size: 10)).foregroundColor(.white).padding(2))
                    }
                }
                .frame(height: 25)
                .cornerRadius(6)
            }
            .frame(height: 25)
            .padding(.vertical, 8)

            ForEach(accountPools) { pool in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).fill(getPoolColor(pool.color)).frame(width: 16, height: 16)
                    Text(pool.name).font(.subheadline)
                    Spacer()
                    Text(viewModel.formatCurrency(pool.amount)).font(.subheadline).fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }

            if unallocatedBalance > 0 || account.balance <= 0 {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.5)).frame(width: 16, height: 16)
                    Text("Unallocated").font(.subheadline)
                    Spacer()
                    Text(viewModel.formatCurrency(unallocatedBalance)).font(.subheadline).fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }

    private var addPoolButton: some View {
        Button(action: {
            newPoolName = ""
            newPoolAmount = ""
            newPoolColor = "Blue"
            showAddPoolSheet = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill").font(.system(size: 20))
                Text("Add New Pool").fontWeight(.medium)
            }
            .foregroundColor(viewModel.themeColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Quick Assignment Section
    
    private var quickAssignmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Assign Transactions")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 5)
            
            VStack(spacing: 12) {
                // Get fresh unassigned transactions for this account
                let unassignedTransactions = getAccountTransactionsForAssignment(poolId: UUID()).filter { $0.poolId == nil }.prefix(5)
                
                if unassignedTransactions.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("All transactions are assigned")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.green.opacity(colorScheme == .dark ? 0.2 : 0.1))
                    )
                } else {
                    ForEach(Array(unassignedTransactions.enumerated()), id: \.element.id) { index, transaction in
                        QuickAssignmentRow(
                            transaction: transaction,
                            availablePools: accountPools,
                            onAssign: { pool in
                                assignTransactionToPool(transaction: transaction, pool: pool)
                            }
                        )
                    }
                    
                    if viewModel.transactions.filter({ 
                        ($0.fromAccountId == account.id || $0.toAccountId == account.id) && $0.poolId == nil 
                    }).count > 5 {
                        Button(action: {
                            selectedPool = accountPools.first
                            showAssignTransactionSheet = true
                        }) {
                            Text("View All Unassigned (\(viewModel.transactions.filter({ 
                                ($0.fromAccountId == account.id || $0.toAccountId == account.id) && $0.poolId == nil 
                            }).count))")
                                .font(.subheadline)
                                .foregroundColor(viewModel.themeColor)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }

    // MARK: - Add Pool Sheet

    private var addPoolSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Pool Details")) {
                    TextField("Pool Name", text: $newPoolName)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount").font(.subheadline).foregroundColor(.secondary)
                        HStack {
                            Text(viewModel.userPreferences.currency.rawValue).foregroundColor(.secondary)
                            TextField("0.00", text: $newPoolAmount).keyboardType(.decimalPad)
                        }
                        Text("Available: \(viewModel.formatCurrency(unallocatedBalance))").font(.caption).foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(["25%", "50%", "75%", "100%"], id: \.self) { percentage in
                                    Button(action: { applyPercentage(percentage) }) {
                                        Text(percentage)
                                            .font(.system(size: 14, weight: .medium))
                                            .padding(.horizontal, 16).padding(.vertical, 8)
                                            .background(Color(.systemGray5)).cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                }

                Section(header: Text("Pool Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                        ForEach(Array(poolColorOptions.keys.sorted()), id: \.self) { colorName in
                            Button(action: { newPoolColor = colorName }) {
                                Circle()
                                    .fill(poolColorOptions[colorName] ?? .blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2).padding(2).opacity(newPoolColor == colorName ? 1 : 0))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)

                    RoundedRectangle(cornerRadius: 15)
                        .fill(getPoolColor(newPoolColor))
                        .frame(height: 60)
                        .overlay(
                            HStack {
                                Image(systemName: "drop.fill").font(.title2).foregroundColor(.white).padding(.leading)
                                Text(newPoolName.isEmpty ? "Pool Preview" : newPoolName).foregroundColor(.white).fontWeight(.semibold)
                                Spacer()
                            }
                        )
                }
            }
            .navigationTitle("Create New Pool")
            .navigationBarItems(
                leading: Button("Cancel") { showAddPoolSheet = false },
                trailing: Button("Create") {
                    addNewPool()
                    showAddPoolSheet = false
                }
                .disabled(!isPoolInputValid())
            )
        }
    }

    // MARK: - Assign Transaction Sheet (IMPROVED)

    private var assignTransactionSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                if let pool = selectedPool {
                    VStack(spacing: 4) {
                        Text("Assign Transactions to")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        HStack {
                            Circle().fill(getPoolColor(pool.color)).frame(width: 12, height: 12)
                            Text(pool.name)
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))

                    Divider()

                    // Get fresh transaction data each time the view is rendered
                    let accountTransactions = getAccountTransactionsForAssignment(poolId: pool.id)

                    if accountTransactions.isEmpty {
                        emptyTransactionsForAssignmentView
                    } else {
                        // Group transactions by date ("Today", "Yesterday", or formatted date)
                        List {
                            ForEach(groupTransactionsByDate(accountTransactions), id: \.key) { section in
                                Section(header: Text(section.key)) {
                                    ForEach(section.value) { transaction in
                                        TransactionAssignmentRow(
                                            transaction: transaction,
                                            isAssigned: transaction.poolId == pool.id,
                                            onToggle: {
                                                if transaction.poolId == pool.id {
                                                    assignTransactionToPool(transaction: transaction, pool: nil)
                                                } else {
                                                    assignTransactionToPool(transaction: transaction, pool: pool)
                                                }
                                            }
                                        )
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    }
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .refreshable {
                            refreshData()
                        }
                        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                        .padding(.top, 4)
                    }
                } else {
                    Text("No Pool Selected")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                }
            }
            .navigationTitle("Assign Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAssignTransactionSheet = false
                        selectedPool = nil
                    }
                    .bold()
                    .accessibilityIdentifier("AssignTransactionDoneButton")
                }
            }
        }
    }

    private var emptyTransactionsForAssignmentView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("No Available Transactions")
                .font(.headline)
            Text("All transactions for this account have already been assigned to other pools.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }

    private var poolTransactionsSheet: some View {
        NavigationView {
             VStack {
                 if let pool = selectedPoolForTransactions {
                     // Get fresh transaction data each time the view is rendered
                     // Filter to transactions assigned to pool and related to this account
                     let poolTransactions = getPoolTransactions(poolId: pool.id)

                     if poolTransactions.isEmpty {
                         emptyTransactionsForAssignmentView
                     } else {
                         // Group transactions by date ("Today", "Yesterday", or formatted date)
                         List {
                             ForEach(groupTransactionsByDate(poolTransactions), id: \.key) { section in
                                 Section(header: Text(section.key)) {
                                     ForEach(section.value) { transaction in
                                         TransactionCardView(transaction: transaction)
                                     }
                                     .onDelete { offsets in
                                         offsets.forEach { index in
                                             let transaction = section.value[index]
                                             assignTransactionToPool(transaction: transaction, pool: nil)
                                         }
                                     }
                                 }
                             }
                         }
                         .listStyle(InsetGroupedListStyle())
                         .refreshable {
                             refreshData()
                         }
                         .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                         .padding(.top, 4)
                     }
                 } else {
                     Text("No Pool Selected")
                         .foregroundColor(.secondary)
                         .frame(maxWidth: .infinity, maxHeight: .infinity)
                         .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                 }
             }
             .navigationTitle(selectedPoolForTransactions?.name ?? "Pool Transactions")
             .toolbar {
                 ToolbarItem(placement: .navigationBarTrailing) {
                     Button("Close") {
                         showPoolTransactionsSheet = false
                         selectedPoolForTransactions = nil
                     }
                     .bold()
                     .accessibilityIdentifier("PoolTransactionsCloseButton")
                 }
             }
         }
    }

    // MARK: - Helper Functions

    private func refreshData() {
        loadAccountPools()
    }

    private func loadAccountPools() {
        accountPools = viewModel.getAccountPools(account.id) ?? []
    }

    // Get fresh transaction data for assignment (not cached)
    // Includes only transactions related to this account (from or to) and unassigned or assigned to this pool
    // Sorted by date descending
    private func getAccountTransactionsForAssignment(poolId: UUID) -> [Transaction] {
        return viewModel.transactions.filter {
            ($0.fromAccountId == account.id || $0.toAccountId == account.id) && ($0.poolId == nil || $0.poolId == poolId)
        }.sorted { $0.date > $1.date }
    }

    // Get fresh transaction data for pool (not cached)
    // Includes only transactions assigned to this pool AND related to this account (from or to)
    // Sorted by date descending
    private func getPoolTransactions(poolId: UUID) -> [Transaction] {
        return viewModel.transactions.filter {
            $0.poolId == poolId && ($0.fromAccountId == account.id || $0.toAccountId == account.id)
        }.sorted { $0.date > $1.date }
    }

    // Group transactions by date string ("Today", "Yesterday", or formatted date)
    private func groupTransactionsByDate(_ transactions: [Transaction]) -> [(key: String, value: [Transaction])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: transactions) { transaction -> String in
            if calendar.isDateInToday(transaction.date) {
                return "Today"
            } else if calendar.isDateInYesterday(transaction.date) {
                return "Yesterday"
            } else {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return formatter.string(from: transaction.date)
            }
        }
        // Sort keys by date descending
        let sortedKeys = grouped.keys.sorted { key1, key2 in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            let date1: Date
            let date2: Date

            if key1 == "Today" {
                date1 = Date()
            } else if key1 == "Yesterday" {
                date1 = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            } else {
                date1 = formatter.date(from: key1) ?? Date.distantPast
            }

            if key2 == "Today" {
                date2 = Date()
            } else if key2 == "Yesterday" {
                date2 = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            } else {
                date2 = formatter.date(from: key2) ?? Date.distantPast
            }
            return date1 > date2
        }

        return sortedKeys.compactMap { key in
            if let value = grouped[key] {
                return (key: key, value: value)
            }
            return nil
        }
    }

    private func assignTransactionToPool(transaction: Transaction, pool: Pool?) {
        var updatedTransaction = transaction
        let oldPoolId = updatedTransaction.poolId
        updatedTransaction.poolId = pool?.id

        viewModel.updateTransaction(updatedTransaction)

        if let oldPoolId = oldPoolId, var oldPool = accountPools.first(where: { $0.id == oldPoolId }) {
            if transaction.type == .expense { oldPool.amount += transaction.amount }
            else if transaction.type == .income { oldPool.amount -= transaction.amount }
            updatePool(oldPool)
        }

        if let newPool = pool, var mutableNewPool = accountPools.first(where: { $0.id == newPool.id }) {
            if transaction.type == .expense { mutableNewPool.amount -= transaction.amount }
            else if transaction.type == .income { mutableNewPool.amount += transaction.amount }
            updatePool(mutableNewPool)
        }

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        refreshData()
    }

    private func updatePool(_ pool: Pool) {
        if let index = accountPools.firstIndex(where: { $0.id == pool.id }) {
            accountPools[index] = pool
            viewModel.saveAccountPools(account.id, pools: accountPools)
            refreshData()
        }
    }

    private func getPoolColor(_ colorName: String) -> Color {
        poolColorOptions[colorName] ?? .blue
    }

    private func applyPercentage(_ percentageString: String) {
        let percentage = Double(percentageString.replacingOccurrences(of: "%", with: "")) ?? 0
        let amount = unallocatedBalance * (percentage / 100)
        newPoolAmount = String(format: "%.2f", amount)
    }

    private func isPoolInputValid() -> Bool {
        guard !newPoolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let amount = Double(newPoolAmount) else { return false }
        return amount > 0 && amount <= unallocatedBalance
    }

    private func addNewPool() {
        guard isPoolInputValid(), let amount = Double(newPoolAmount) else { return }
        let newPool = Pool(name: newPoolName, amount: amount, color: newPoolColor)
        accountPools.append(newPool)
        viewModel.saveAccountPools(account.id, pools: accountPools)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        refreshData()
    }

    private func deletePool(_ pool: Pool) {
        let assignedTransactions = viewModel.getTransactionsForPool(pool.id)
        for transaction in assignedTransactions {
            assignTransactionToPool(transaction: transaction, pool: nil)
        }
        accountPools.removeAll { $0.id == pool.id }
        viewModel.saveAccountPools(account.id, pools: accountPools)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        refreshData()
    }
}

// MARK: - Supporting Views

struct TransactionAssignmentRow: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    let transaction: Transaction
    let isAssigned: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TransactionCardView(transaction: transaction)

            Button(action: onToggle) {
                Image(systemName: isAssigned ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isAssigned ? .green : .gray.opacity(0.5))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct PoolCardView: View {
    let pool: Pool
    let colorScheme: ColorScheme
    let formatCurrency: (Double) -> String
    let poolColor: Color
    let onDelete: () -> Void
    let onSelect: () -> Void
    let onAssign: () -> Void
    let assignedTransactionCount: Int

    @State private var showDeleteAlert = false

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Circle()
                    .fill(poolColor)
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "drop.fill").foregroundColor(.white))

                VStack(alignment: .leading, spacing: 4) {
                    Text(pool.name).font(.headline)
                    HStack {
                        Text(formatCurrency(pool.amount)).font(.subheadline).foregroundColor(.secondary)
                        if assignedTransactionCount > 0 {
                            Text("•").foregroundColor(.secondary)
                            Text("\(assignedTransactionCount) transaction\(assignedTransactionCount == 1 ? "" : "s")")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Menu {
                    Button(action: onSelect) { Label("View Transactions", systemImage: "list.bullet") }
                    Button(action: onAssign) { Label("Assign Transaction", systemImage: "arrow.right") }
                    Divider()
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Pool", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis").foregroundColor(.secondary).padding(8).contentShape(Rectangle())
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(poolColor.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
        )
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Pool"),
                message: Text("Are you sure you want to delete the \(pool.name) pool? This will remove all transaction assignments."),
                primaryButton: .destructive(Text("Delete"), action: onDelete),
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Quick Assignment Row

struct QuickAssignmentRow: View {
    let transaction: Transaction
    let availablePools: [Pool]
    let onAssign: (Pool) -> Void
    
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private var transactionColor: Color {
        switch transaction.type {
        case .income: return .green
        case .expense: return .red
        case .transfer: return .blue
        }
    }
    
    private var categoryName: String {
        if let category = viewModel.getCategory(id: transaction.categoryId) {
            return category.name
        }
        return "Other"
    }
    
    private func getPoolColor(_ colorName: String) -> Color {
        let poolColorOptions = [
            "Blue": Color(red: 0.20, green: 0.40, blue: 0.70),
            "Green": Color(red: 0.20, green: 0.55, blue: 0.30),
            "Orange": Color(red: 0.80, green: 0.40, blue: 0.20),
            "Purple": Color(red: 0.50, green: 0.25, blue: 0.70),
            "Red": Color(red: 0.70, green: 0.20, blue: 0.20),
            "Teal": Color(red: 0.20, green: 0.50, blue: 0.60)
        ]
        return poolColorOptions[colorName] ?? .blue
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Transaction info
            HStack(spacing: 12) {
                // Transaction icon
                Circle()
                    .fill(transactionColor.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: transaction.type == .income ? "arrow.down" : 
                                           transaction.type == .expense ? "arrow.up" : "arrow.left.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(categoryName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(viewModel.formatCurrency(transaction.amount))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(transactionColor)
                    }
                }
                
                Spacer()
            }
            
            // Pool assignment buttons
            if !availablePools.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availablePools) { pool in
                            Button(action: { onAssign(pool) }) {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(getPoolColor(pool.color))
                                        .frame(width: 12, height: 12)
                                    Text(pool.name)
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(getPoolColor(pool.color).opacity(colorScheme == .dark ? 0.25 : 0.15))
                                )
                                .foregroundColor(getPoolColor(pool.color))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.tertiarySystemFill))
        )
    }
}

// MARK: - ViewModel Extension

extension FinanceViewModel {
    func getAccountPools(_ accountId: UUID) -> [Pool]? {
        if let data = UserDefaults.standard.data(forKey: "pools_\(accountId.uuidString)") {
            do {
                return try JSONDecoder().decode([Pool].self, from: data)
            } catch {
                print("Error loading pools: \(error)")
                return []
            }
        }
        return []
    }

    func saveAccountPools(_ accountId: UUID, pools: [Pool]) {
        do {
            let data = try JSONEncoder().encode(pools)
            UserDefaults.standard.set(data, forKey: "pools_\(accountId.uuidString)")
        } catch {
            print("Error saving pools: \(error)")
        }
    }

    /// Note: Caller is responsible for sorting transactions by date if needed
    func getTransactionsForPool(_ poolId: UUID) -> [Transaction] {
        return transactions.filter { $0.poolId == poolId }
    }
}
