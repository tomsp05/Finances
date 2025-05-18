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
                // Account summary card
                accountSummaryCard
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isAppearing)
                
                // Unallocated funds
                unallocatedBalanceCard
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isAppearing)
                
                // Pool distribution visualization
                if !accountPools.isEmpty {
                    poolVisualizationSection
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
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .navigationTitle("\(account.name) Pools")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showAddPoolSheet) {
            addPoolSheet
        }
        .onAppear {
            // Load pools when view appears
            loadAccountPools()
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
    
    // MARK: - Component Views
    
    private var accountSummaryCard: some View {
        VStack(spacing: 8) {
            // Account icon and type
            HStack {
                ZStack {
                    Circle()
                        .fill(getAccountColor().opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: getAccountIcon())
                        .font(.system(size: 24))
                        .foregroundColor(getAccountColor())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.headline)
                    
                    Text(getAccountTypeName())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Account balance
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(account.balance))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(getBalanceColor())
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
    
    private var unallocatedBalanceCard: some View {
        VStack(spacing: 10) {
            Text("Unallocated Balance")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(formattedUnallocatedBalance)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(unallocatedBalance >= 0 ? .green : .red)
            
            Text("Available to allocate to pools")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
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
                        let proportion = pool.amount / account.balance
                        
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
                        let unallocatedProportion = unallocatedBalance / account.balance
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
            if unallocatedBalance > 0 {
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
                        onDelete: { deletePool(pool) }
                    )
                    .offset(y: isAppearing ? 0 : 20)
                    .opacity(isAppearing ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(0.4 + Double(index) * 0.05),
                        value: isAppearing
                    )
                }
            }
        }
    }
    
    private var emptyPoolsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "drop.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No pools created yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Create pools to allocate your balance to different purposes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
    }
    
    private var addPoolButton: some View {
        Button(action: {
            // Reset form values
            newPoolName = ""
            newPoolAmount = ""
            newPoolColor = "Blue"
            showAddPoolSheet = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Create New Pool")
                    .fontWeight(.semibold)
            }
            .foregroundColor(viewModel.themeColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(viewModel.themeColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var addPoolSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Pool name field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pool Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
                            TextField("Enter pool name", text: $newPoolName)
                                .padding()
                        }
                        .frame(height: 60)
                    }
                    .padding(.horizontal)
                    
                    // Amount field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Amount")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                            
                            HStack {
                                Text("£")
                                    .foregroundColor(.secondary)
                                    .padding(.leading)
                                
                                TextField("0.00", text: $newPoolAmount)
                                    .keyboardType(.decimalPad)
                                    .padding(.vertical)
                                
                                Spacer()
                                
                                if let amount = Double(newPoolAmount) {
                                    Text(formatCurrency(amount))
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .padding(.trailing)
                                }
                            }
                        }
                        .frame(height: 60)
                    }
                    .padding(.horizontal)
                    
                    // Quick amount buttons
                    HStack(spacing: 10) {
                        ForEach(["25%", "50%", "75%", "100%"], id: \.self) { percentage in
                            Button(action: {
                                applyPercentage(percentage)
                            }) {
                                Text(percentage)
                                    .font(.footnote)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(UIColor.tertiarySystemFill))
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    
                    // Available balance
                    HStack {
                        Text("Available balance:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formattedUnallocatedBalance)
                            .fontWeight(.semibold)
                            .foregroundColor(unallocatedBalance >= 0 ? .green : .red)
                    }
                    .padding(.horizontal)
                    
                    // Color selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pool Color")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                            ForEach(poolColorOptions.sorted(by: { $0.key < $1.key }), id: \.key) { colorName, colorValue in
                                Button(action: {
                                    newPoolColor = colorName
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(colorValue)
                                                .frame(width: 40, height: 40)
                                                .shadow(color: colorValue.opacity(0.4), radius: 3, x: 0, y: 2)
                                            
                                            if newPoolColor == colorName {
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: 2)
                                                    .frame(width: 40, height: 40)
                                                
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        
                                        Text(colorName)
                                            .font(.caption)
                                            .foregroundColor(newPoolColor == colorName ? colorValue : .secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Color preview
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
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
    
    // MARK: - Helper Functions
    
    private func loadAccountPools() {
        // Replace this with code to load pools from the account
        // For now, we'll use the state variable
        accountPools = viewModel.getAccountPools(account.id) ?? []
    }
    
    private func getAccountIcon() -> String {
        switch account.type {
        case .savings: return "building.columns.fill"
        case .current: return "banknote.fill"
        case .credit: return "creditcard.fill"
        }
    }
    
    private func getAccountColor() -> Color {
        switch account.type {
        case .savings: return .blue
        case .current: return .green
        case .credit: return .purple
        }
    }
    
    private func getAccountTypeName() -> String {
        switch account.type {
        case .savings: return "Savings Account"
        case .current: return "Current Account"
        case .credit: return "Credit Card"
        }
    }
    
    private func getBalanceColor() -> Color {
        if account.type == .credit {
            return account.balance > 0 ? .red : .green
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
        // Remove the pool from our local array
        accountPools.removeAll { $0.id == pool.id }
        
        // Save the updated pools
        viewModel.saveAccountPools(account.id, pools: accountPools)
        
        // Provide haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Supporting Structs

// Pool Card View component
struct PoolCardView: View {
    let pool: Pool
    let colorScheme: ColorScheme
    let formatCurrency: (Double) -> String
    let poolColor: Color
    let onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Pool color indicator
            ZStack {
                Circle()
                    .fill(poolColor.opacity(colorScheme == .dark ? 0.9 : 0.8))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: poolColor.opacity(colorScheme == .dark ? 0.3 : 0.4), radius: 3, x: 0, y: 2)
            
            // Pool name and details
            VStack(alignment: .leading, spacing: 4) {
                Text(pool.name)
                    .font(.headline)
                
                Text("Allocated amount")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(pool.amount))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(poolColor)
                
                // Delete button
                Button(action: {
                    showDeleteAlert = true
                }) {
                    Text("Delete")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(poolColor.opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
        )
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Pool"),
                message: Text("Are you sure you want to delete the \(pool.name) pool?"),
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
}
