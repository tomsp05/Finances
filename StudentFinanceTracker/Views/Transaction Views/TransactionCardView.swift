import SwiftUI

struct TransactionCardView: View {
    let transaction: Transaction
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme

    // Animation state
    @State private var isAppearing: Bool = false
    
    // Pool assignment state
    @State private var showPoolAssignment: Bool = false

    var transactionColor: Color {
        switch transaction.type {
        case .income:
            return .green
        case .expense:
            return .red
        case .transfer:
            return .blue
        }
    }
        
    var iconName: String {
        // First try to get the category's icon
        if let category = viewModel.getCategory(id: transaction.categoryId) {
            return category.iconName
        }
        
        // Fallback to default icons based on transaction type
        switch transaction.type {
        case .income:
            return "arrow.down.circle.fill"
        case .expense:
            return "arrow.up.circle.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    var categoryName: String {
        if let category = viewModel.getCategory(id: transaction.categoryId) {
            return category.name
        }
        return "Other" // Fallback
    }
    
    // Check if transaction is in the future
    var isFutureDate: Bool {
        let currentDate = Calendar.current.startOfDay(for: Date())
        return Calendar.current.startOfDay(for: transaction.date) > currentDate
    }
    
    // Formatting date
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: transaction.date)
    }
    
    // Get assigned pool information
    private var assignedPool: Pool? {
        guard let poolId = transaction.poolId,
              let fromAccountId = transaction.fromAccountId ?? transaction.toAccountId else { return nil }
        return viewModel.getAccountPools(fromAccountId)?.first { $0.id == poolId }
    }
    
    // Get available pools for assignment
    private var availablePools: [Pool] {
        guard let accountId = transaction.fromAccountId ?? transaction.toAccountId else { return [] }
        return viewModel.getAccountPools(accountId) ?? []
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Icon with colored background - new modern style
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    transactionColor.opacity(colorScheme == .dark ? 0.9 : 0.8),
                                    transactionColor.opacity(colorScheme == .dark ? 0.7 : 0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: transactionColor.opacity(colorScheme == .dark ? 0.3 : 0.4), radius: 3, x: 0, y: 2)
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
                
                // Transaction details
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.description)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        // Category pill
                        Text(categoryName)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.3 : 0.15))
                            )
                            .foregroundColor(viewModel.themeColor)
                        
                        // Pool assignment indicator
                        if let pool = assignedPool {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(getPoolColor(pool.color))
                                    .frame(width: 8, height: 8)
                                Text(pool.name)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(getPoolColor(pool.color).opacity(colorScheme == .dark ? 0.3 : 0.15))
                            )
                            .foregroundColor(getPoolColor(pool.color))
                        } else if !availablePools.isEmpty {
                            // Show unassigned indicator if pools are available
                            HStack(spacing: 4) {
                                Circle()
                                    .stroke(Color.gray, lineWidth: 1)
                                    .frame(width: 8, height: 8)
                                Text("Unassigned")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            )
                            .foregroundColor(.gray)
                            .opacity(0.7) // Make it less prominent but still visible
                        }
                        
                        if transaction.isSplit {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .opacity(isAppearing ? 1.0 : 0.0)
                .offset(x: isAppearing ? 0 : -10)
                
                Spacer()
                
                // Date & Amount - aligned design with dark mode improvements
                VStack(alignment: .trailing, spacing: 4) {
                    // Date with modern pill style
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(UIColor.tertiarySystemFill))
                        )
                        .foregroundColor(.secondary)
                    
                    // Amount with better styling
                    if transaction.isSplit {
                        // Show both amounts for split transactions with improved layout
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(viewModel.formatCurrency(transaction.amount))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(transactionColor)
                            
                            Text("You: \(viewModel.formatCurrency(transaction.userAmount))")
                                .font(.system(size: 12))
                                .foregroundColor(transactionColor.opacity(0.8))
                        }
                    } else {
                        Text(viewModel.formatCurrency(transaction.amount))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(transactionColor)
                    }
                }
                .scaleEffect(isAppearing ? 1.0 : 1.1)
                .opacity(isAppearing ? 1.0 : 0.0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Status badges for special transaction types
            if isFutureDate || transaction.isRecurring || transaction.isSplit {
                Divider()
                    .padding(.horizontal, 16)
                    .opacity(0.5)
                
                HStack(spacing: 8) {
                    if isFutureDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text("FUTURE")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(colorScheme == .dark ? 0.3 : 0.15))
                        )
                        .foregroundColor(.blue)
                    }
                    
                    if transaction.isRecurring {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text(transaction.recurrenceInterval.rawValue.uppercased())
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.purple.opacity(colorScheme == .dark ? 0.3 : 0.15))
                        )
                        .foregroundColor(.purple)
                    }
                    
                    if transaction.isSplit {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 10))
                            Text("SPLIT: \(transaction.friendName)")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange.opacity(colorScheme == .dark ? 0.3 : 0.15))
                        )
                        .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        )
        .overlay(
            // Improved border with better dark mode visibility
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    isFutureDate ? Color.blue.opacity(colorScheme == .dark ? 0.5 : 0.3) :
                    transaction.isRecurring ? Color.purple.opacity(colorScheme == .dark ? 0.5 : 0.3) :
                    transaction.isSplit ? Color.orange.opacity(colorScheme == .dark ? 0.5 : 0.3) :
                    assignedPool != nil ? getPoolColor(assignedPool!.color).opacity(colorScheme == .dark ? 0.4 : 0.2) :
                    transactionColor.opacity(colorScheme == .dark ? 0.4 : 0.2),
                    lineWidth: 1
                )
        )
        .contextMenu {
            if !availablePools.isEmpty {
                poolAssignmentContextMenu
            }
        }
        .onAppear {
            // Slight delay to ensure smooth appearance animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isAppearing = true
                }
            }
        }
    }
    
    // MARK: - Pool Assignment Context Menu
    
    private var poolAssignmentContextMenu: some View {
        Group {
            if let assignedPool = assignedPool {
                Button(action: { unassignFromPool() }) {
                    Label("Remove from \(assignedPool.name)", systemImage: "minus.circle")
                }
                
                Divider()
                
                Text("Reassign to:")
                    .foregroundColor(.secondary)
            } else {
                Text("Assign to Pool:")
                    .foregroundColor(.secondary)
            }
            
            ForEach(availablePools.filter { $0.id != assignedPool?.id }) { pool in
                Button(action: { assignToPool(pool) }) {
                    Label(pool.name, systemImage: "drop.fill")
                        .foregroundColor(getPoolColor(pool.color))
                }
            }
        }
    }
    
    // MARK: - Pool Assignment Actions
    
    private func assignToPool(_ pool: Pool) {
        var updatedTransaction = transaction
        updatedTransaction.poolId = pool.id
        viewModel.updateTransaction(updatedTransaction)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func unassignFromPool() {
        var updatedTransaction = transaction
        updatedTransaction.poolId = nil
        viewModel.updateTransaction(updatedTransaction)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // Helper function to get pool colors
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
}
