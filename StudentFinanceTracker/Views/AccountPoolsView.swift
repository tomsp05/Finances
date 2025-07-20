import SwiftUI

struct AccountPoolsView: View {
    let account: Account
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // State for managing pools
    @State private var accountPools: [Pool] = []
    @State private var showAddPoolSheet = false
    @State private var newPoolName = ""
    @State private var newPoolAmount = ""
    @State private var newPoolColor = "Blue" // Default color
    @State private var isAppearing: Bool = false
    @State private var showAssignTransactionSheet = false
    @State private var selectedPool: Pool? = nil
    @State private var showPoolTransactionsSheet = false
    @State private var selectedPoolForTransactions: Pool? = nil
    
    // Available theme colours with their visual representations - matching the app's theme colors
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
    
    private var formattedUnallocatedBalance: String {
        return formatCurrency(unallocatedBalance)
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Account details
                VStack(spacing: 12) {
                    // Account balance
                    Text(formatCurrency(account.balance))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.vertical, 8)
                        .offset(y: isAppearing ? 0 : 20)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isAppearing)
                    
                    Text("Account Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .offset(y: isAppearing ? 0 : 20)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: isAppearing)
                }
                
                // Pools section
                poolsSection
                
                // Add pool button
                addPoolButton
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: isAppearing)
                
                // Assign transaction button
                assignTransactionButton
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: isAppearing)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("\(account.name) Pools")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showAddPoolSheet) {
            addPoolSheet
        }
        .sheet(isPresented: $showAssignTransactionSheet) {
            assignTransactionSheet
        }
        .sheet(isPresented: $showPoolTransactionsSheet) {
            poolTransactionsSheet
        }
        .onAppear {
            // Load pools when view appears
            loadAccountPools()
            
            // Animate appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    isAppearing = true
                }
            }
        }
    }
    
    // MARK: - Main View Components
    
    private var poolsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if accountPools.isEmpty {
                emptyPoolsView
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: isAppearing)
            } else {
                Text("Your Pools")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: isAppearing)
                
                ForEach(Array(accountPools.enumerated()), id: \.element.id) { index, pool in
                    PoolCardView(
                        pool: pool,
                        colorScheme: colorScheme,
                        formatCurrency: formatCurrency,
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
                    .offset(y: isAppearing ? 0 : CGFloat(index) * 20 + 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1 + 0.5), value: isAppearing)
                }
                
                // Pool visualization
                poolVisualizationSection
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: isAppearing)
            }
        }
    }
    
    private var emptyPoolsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 56))
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
            
            // Distribution chart
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    // Calculate the proportion of each pool
                    ForEach(accountPools) { pool in
                        let proportion = pool.amount / max(0.01, account.balance) // Avoid division by zero
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(getPoolColor(pool.color))
                            .frame(width: max(5, geometry.size.width * CGFloat(proportion)))
                            .overlay(
                                Text(proportion > 0.1 ? "\(Int(proportion * 100))%" : "")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .padding(2)
                            )
                    }
                    
                    // Unallocated proportion
                    if unallocatedBalance > 0 {
                        let unallocatedProportion = unallocatedBalance / max(0.01, account.balance) // Avoid division by zero
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.5))
                            .frame(width: max(5, geometry.size.width * CGFloat(unallocatedProportion)))
                            .overlay(
                                Text(unallocatedProportion > 0.1 ? "\(Int(unallocatedProportion * 100))%" : "")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white)
                                    .padding(2)
                            )
                    }
                }
                .frame(height: 25)
                .cornerRadius(6)
            }
            .frame(height: 25)
            .padding(.vertical, 8)
            
            // Legends for each pool
            ForEach(accountPools) { pool in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(getPoolColor(pool.color))
                        .frame(width: 16, height: 16)
                    
                    Text(pool.name)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(formatCurrency(pool.amount))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
            
            // Legend for unallocated
            if unallocatedBalance > 0 || account.balance <= 0 {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 16, height: 16)
                    
                    Text("Unallocated")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(formattedUnallocatedBalance)
                        .font(.subheadline)
                        .fontWeight(.medium)
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
            // Reset new pool inputs
            newPoolName = ""
            newPoolAmount = ""
            newPoolColor = "Blue"
            showAddPoolSheet = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add New Pool")
                    .fontWeight(.medium)
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
    
    private var assignTransactionButton: some View {
        Button(action: {
            showAssignTransactionSheet = true
            selectedPool = nil
        }) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                Text("Assign Transaction to Pool")
                    .fontWeight(.medium)
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
        .disabled(accountPools.isEmpty)
        .opacity(accountPools.isEmpty ? 0.5 : 1.0)
    }
    
    // MARK: - Add Pool Sheet
    
    private var addPoolSheet: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Form
                Form {
                    Section(header: Text("Pool Details")) {
                        // Name input
                        TextField("Pool Name", text: $newPoolName)
                        
                        // Amount Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("£")
                                    .foregroundColor(.secondary)
                                
                                TextField("0.00", text: $newPoolAmount)
                                    .keyboardType(.decimalPad)
                            }
                            
                            // Available balance indicator
                            Text("Available: \(formattedUnallocatedBalance)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Quick percentage buttons
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(["25%", "50%", "75%", "100%"], id: \.self) { percentage in
                                        Button(action: {
                                            applyPercentage(percentage)
                                        }) {
                                            Text(percentage)
                                                .font(.system(size: 14, weight: .medium))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color(.systemGray5))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Pool Color")) {
                        // Color options
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 12) {
                            ForEach(Array(poolColorOptions.keys.sorted()), id: \.self) { colorName in
                                Button(action: {
                                    newPoolColor = colorName
                                }) {
                                    Circle()
                                        .fill(poolColorOptions[colorName] ?? .blue)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2)
                                                .padding(2)
                                                .opacity(newPoolColor == colorName ? 1 : 0)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Color Preview
                        RoundedRectangle(cornerRadius: 15)
                            .fill(getPoolColor(newPoolColor))
                            .frame(height: 60)
                            .overlay(
                                HStack {
                                    Image(systemName: "drop.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(.leading)
                                    
                                    Text(newPoolName.isEmpty ? "Pool Preview" : newPoolName)
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                }
                            )
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Create New Pool")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showAddPoolSheet = false
                },
                trailing: Button("Create") {
                    addNewPool()
                    showAddPoolSheet = false
                }
                .disabled(!isPoolInputValid())
            )
        }
    }
    
    // MARK: - Assign Transaction Sheet
    
    private var assignTransactionSheet: some View {
        NavigationView {
            VStack {
                // Filter to only show transactions for this account
                let accountTransactions = viewModel.transactions.filter { transaction in
                    (transaction.fromAccountId == account.id || transaction.toAccountId == account.id) &&
                    (transaction.poolId == nil || (selectedPool != nil && transaction.poolId == selectedPool!.id)) // Show unassigned or transactions assigned to selected pool
                }
                
                if accountTransactions.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "tray")
                            .font(.system(size: 56))
                            .foregroundColor(viewModel.themeColor.opacity(0.5))
                        
                        Text("No unassigned transactions")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("All transactions have already been assigned to pools or there are no transactions for this account.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                } else {
                    // Pool Selection (only show if no pool was preselected)
                    if selectedPool == nil {
                        VStack(alignment: .leading) {
                            Text("Select pool to assign transaction to:")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(accountPools) { pool in
                                        Button(action: {
                                            selectedPool = pool
                                        }) {
                                            HStack {
                                                Circle()
                                                    .fill(getPoolColor(pool.color))
                                                    .frame(width: 24, height: 24)
                                                
                                                Text(pool.name)
                                                    .font(.headline)
                                                
                                                Spacer()
                                                
                                                Text(formatCurrency(pool.amount))
                                                    .font(.subheadline)
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(Color(UIColor.secondarySystemBackground))
                                            )
                                            .padding(.horizontal)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.bottom)
                    }
                    
                    // Transactions List
                    if let selectedPool = selectedPool {
                        VStack(alignment: .leading) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Assigning to:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Circle()
                                            .fill(getPoolColor(selectedPool.color))
                                            .frame(width: 16, height: 16)
                                        
                                        Text(selectedPool.name)
                                            .font(.headline)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    self.selectedPool = nil
                                }) {
                                    Text("Change Pool")
                                        .foregroundColor(viewModel.themeColor)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top)
                            
                            Text("Select a transaction:")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }
                    
                    List {
                        ForEach(accountTransactions) { transaction in
                            Button(action: {
                                if let pool = selectedPool {
                                    if transaction.poolId == pool.id {
                                        // If transaction is already assigned to this pool, unassign it
                                        assignTransactionToPool(transaction: transaction, pool: nil)
                                    } else {
                                        // Otherwise assign it to the selected pool
                                        assignTransactionToPool(transaction: transaction, pool: pool)
                                    }
                                }
                            }) {
                                HStack {
                                    // Transaction icon based on type
                                    Image(systemName: transaction.type == .expense ? "arrow.down" :
                                                     transaction.type == .income ? "arrow.up" : "arrow.left.arrow.right")
                                        .foregroundColor(transaction.type == .expense ? .red :
                                                         transaction.type == .income ? .green : .blue)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(Color(UIColor.tertiarySystemFill))
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(transaction.description)
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        HStack {
                                            Text(formatDate(transaction.date))
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            // Show category if available
                                            if let category = viewModel.getCategory(id: transaction.categoryId) {
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                
                                                Text(category.name)
                                                    .font(.caption)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        Capsule()
                                                            .fill(Color(UIColor.tertiarySystemFill))
                                                    )
                                            }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(formatCurrency(transaction.amount))
                                            .foregroundColor(transaction.type == .expense ? .red : .green)
                                            .fontWeight(.semibold)
                                        
                                        if let pool = selectedPool, transaction.poolId == pool.id {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                                Text("Assigned")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.green)
                                        } else if transaction.poolId != nil {
                                            HStack(spacing: 4) {
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.caption)
                                                Text("In another pool")
                                                    .font(.caption)
                                            }
                                            .foregroundColor(.orange)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Assign to Pool")
            .navigationBarItems(
                trailing: Button("Done") {
                    showAssignTransactionSheet = false
                    selectedPool = nil
                }
            )
        }
    }
    
    // MARK: - Pool Transactions Sheet
    
    private var poolTransactionsSheet: some View {
        NavigationView {
            VStack {
                if let pool = selectedPoolForTransactions {
                    let poolTransactions = viewModel.getTransactionsForPool(pool.id)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(getPoolColor(pool.color))
                                .frame(width: 20, height: 20)
                            
                            Text(pool.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Text(formatCurrency(pool.amount))
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        if poolTransactions.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                
                                Image(systemName: "tray")
                                    .font(.system(size: 56))
                                    .foregroundColor(viewModel.themeColor.opacity(0.5))
                                
                                Text("No transactions in this pool")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Assign transactions to this pool using the 'Assign Transaction to Pool' button.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    selectedPool = pool
                                    showPoolTransactionsSheet = false
                                    
                                    // Add a small delay before showing assign sheet
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        showAssignTransactionSheet = true
                                    }
                                }) {
                                    Text("Assign Transactions")
                                        .foregroundColor(.white)
                                        .fontWeight(.medium)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(viewModel.themeColor)
                                        .cornerRadius(10)
                                        .padding(.horizontal)
                                }
                                
                                Spacer()
                            }
                        } else {
                            Text("Transactions in this pool:")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            List {
                                ForEach(poolTransactions) { transaction in
                                    HStack {
                                        // Transaction icon based on type
                                        Image(systemName: transaction.type == .expense ? "arrow.down" :
                                                        transaction.type == .income ? "arrow.up" : "arrow.left.arrow.right")
                                            .foregroundColor(transaction.type == .expense ? .red :
                                                            transaction.type == .income ? .green : .blue)
                                            .frame(width: 24, height: 24)
                                            .background(
                                                Circle()
                                                    .fill(Color(UIColor.tertiarySystemFill))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(transaction.description)
                                                .font(.headline)
                                                .lineLimit(1)
                                            
                                            HStack {
                                                Text(formatDate(transaction.date))
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                                
                                                // Show category if available
                                                if let category = viewModel.getCategory(id: transaction.categoryId) {
                                                    Text("•")
                                                        .foregroundColor(.secondary)
                                                    
                                                    Text(category.name)
                                                        .font(.caption)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(
                                                            Capsule()
                                                                .fill(Color(UIColor.tertiarySystemFill))
                                                        )
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(formatCurrency(transaction.amount))
                                                .foregroundColor(transaction.type == .expense ? .red : .green)
                                                .fontWeight(.semibold)
                                            
                                            Button(action: {
                                                assignTransactionToPool(transaction: transaction, pool: nil)
                                            }) {
                                                Text("Remove")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                } else {
                    Text("No pool selected")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Pool Transactions")
            .navigationBarItems(
                trailing: Button("Close") {
                    showPoolTransactionsSheet = false
                    selectedPoolForTransactions = nil
                }
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadAccountPools() {
        if let pools = viewModel.getAccountPools(account.id) {
            accountPools = pools
        } else {
            accountPools = []
        }
    }
    
    private func assignTransactionToPool(transaction: Transaction, pool: Pool?) {
        // First check if the transaction is already assigned to a pool
        let oldPoolId = transaction.poolId
        
        // Create updated transaction with pool assignment
        var updatedTransaction = transaction
        updatedTransaction.poolId = pool?.id
        
        // Handle the effect on pool balances
        if let oldPoolId = oldPoolId,
           let oldPoolIndex = accountPools.firstIndex(where: { $0.id == oldPoolId }) {
            // Undo the effect of this transaction on the old pool
            var oldPool = accountPools[oldPoolIndex]
            
            if transaction.type == .expense && transaction.fromAccountId == account.id {
                // If expense transaction is unassigned, add back the amount to the old pool
                oldPool.amount += transaction.amount
            } else if transaction.type == .income && transaction.toAccountId == account.id {
                // If income transaction is unassigned, subtract the amount from the old pool
                oldPool.amount -= transaction.amount
            }
            
            accountPools[oldPoolIndex] = oldPool
        }
        
        // If assigning to a new pool, update that pool's amount
        if let pool = pool, let poolIndex = accountPools.firstIndex(where: { $0.id == pool.id }) {
            var updatedPool = accountPools[poolIndex]
            
            if transaction.type == .expense && transaction.fromAccountId == account.id {
                // For expense transactions, reduce the pool amount
                updatedPool.amount -= transaction.amount
            } else if transaction.type == .income && transaction.toAccountId == account.id {
                // For income transactions, add to the pool amount
                updatedPool.amount += transaction.amount
            }
            
            accountPools[poolIndex] = updatedPool
        }
        
        // Update the transaction
        viewModel.updateTransaction(updatedTransaction)
        
        // Save the updated pools
        viewModel.saveAccountPools(account.id, pools: accountPools)
        
        // Refresh the transactions list if we're viewing pool transactions
        if showPoolTransactionsSheet && selectedPoolForTransactions != nil {
            // Find and update the selected pool if needed
            if let updatedPool = accountPools.first(where: { $0.id == selectedPoolForTransactions?.id }) {
                selectedPoolForTransactions = updatedPool
            }
        }
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    private func getThemeColor() -> Color {
        if account.type == .credit {
            return .red
        } else {
            return account.balance >= 0 ? .green : .red
        }
    }
    
    private func getPoolColor(_ colorName: String) -> Color {
        poolColorOptions[colorName] ?? .blue
    }
    
    private func applyPercentage(_ percentageString: String) {
        // Extract percentage value
        let percentage = Double(percentageString.replacingOccurrences(of: "%", with: "")) ?? 0
        let amount = unallocatedBalance * (percentage / 100)
        newPoolAmount = String(format: "%.2f", amount)
    }
    
    private func isPoolInputValid() -> Bool {
        guard !newPoolName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amount = Double(newPoolAmount) else { return false }
        return amount > 0 && amount <= unallocatedBalance
    }
    
    private func addNewPool() {
        guard isPoolInputValid(), let amount = Double(newPoolAmount) else { return }
        
        let newPool = Pool(
            name: newPoolName,
            amount: amount,
            color: newPoolColor
        )
        
        // Add the new pool to our local array
        accountPools.append(newPool)
        
        // Save the updated pools
        viewModel.saveAccountPools(account.id, pools: accountPools)
        
        // Force UI update with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            loadAccountPools()
        }
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func deletePool(_ pool: Pool) {
        // Check if any transactions are assigned to this pool
        let assignedTransactions = viewModel.transactions.filter { $0.poolId == pool.id }
        
        // Unassign any transactions from this pool
        for transaction in assignedTransactions {
            var updatedTransaction = transaction
            updatedTransaction.poolId = nil
            viewModel.updateTransaction(updatedTransaction)
        }
        
        // Remove the pool from our local array
        accountPools.removeAll { $0.id == pool.id }
        
        // Save the updated pools
        viewModel.saveAccountPools(account.id, pools: accountPools)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Structs

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
    @State private var showContextMenu = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Color indicator
                Circle()
                    .fill(poolColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "drop.fill")
                            .foregroundColor(.white)
                    )
                
                // Pool info
                VStack(alignment: .leading, spacing: 4) {
                    Text(pool.name)
                        .font(.headline)
                    
                    HStack {
                        Text(formatCurrency(pool.amount))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if assignedTransactionCount > 0 {
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text("\(assignedTransactionCount) transaction\(assignedTransactionCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Menu button
                Menu {
                    Button(action: onSelect) {
                        Label("View Transactions", systemImage: "list.bullet")
                    }
                    
                    Button(action: onAssign) {
                        Label("Assign Transaction", systemImage: "arrow.right")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: {
                        showDeleteAlert = true
                    }) {
                        Label("Delete Pool", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(8)
                        .contentShape(Rectangle())
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
                primaryButton: .destructive(Text("Delete")) {
                    onDelete()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - ViewModel Extension

extension FinanceViewModel {
    // Get pools for an account
    func getAccountPools(_ accountId: UUID) -> [Pool]? {
        // In a real app, this would fetch from persistent storage
        // For now we'll use UserDefaults for demonstration
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
    
    // Save pools for an account
    func saveAccountPools(_ accountId: UUID, pools: [Pool]) {
        // In a real app, this would save to persistent storage
        // For now we'll use UserDefaults for demonstration
        do {
            let data = try JSONEncoder().encode(pools)
            UserDefaults.standard.set(data, forKey: "pools_\(accountId.uuidString)")
        } catch {
            print("Error saving pools: \(error)")
        }
    }
    
    // Get transactions assigned to a specific pool
    func getTransactionsForPool(_ poolId: UUID) -> [Transaction] {
        return transactions.filter { $0.poolId == poolId }
    }
}
