import SwiftUI

struct TransactionCardView: View {
    let transaction: Transaction
    @EnvironmentObject var viewModel: FinanceViewModel
    
    // Animation state
    @State private var isAppearing: Bool = false
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                // Icon with colored background - new modern style
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    transactionColor.opacity(0.7),
                                    transactionColor.opacity(0.5)
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
                .shadow(color: transactionColor.opacity(0.3), radius: 3, x: 0, y: 2)
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
                            .background(viewModel.themeColor.opacity(0.15))
                            .foregroundColor(viewModel.themeColor)
                            .cornerRadius(4)
                        
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
                
                // Date & Amount - new aligned design
                VStack(alignment: .trailing, spacing: 4) {
                    // Date with modern pill style
                    Text(formattedDate)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                    
                    // Amount with better styling
                    if transaction.isSplit {
                        // Show both amounts for split transactions with improved layout
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(formatCurrency(transaction.totalAmount))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(transactionColor)
                            
                            Text("You: \(formatCurrency(transaction.amount))")
                                .font(.system(size: 12))
                                .foregroundColor(transactionColor.opacity(0.8))
                        }
                    } else {
                        Text(formatCurrency(transaction.amount))
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
                                .fill(Color.blue.opacity(0.15))
                        )
                        .foregroundColor(.blue)
                    }
                    
                    if transaction.isRecurring {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                            Text(transaction.recurrenceInterval.description.uppercased())
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.purple.opacity(0.15))
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
                                .fill(Color.orange.opacity(0.15))
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
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
        )
        .overlay(
            // Add a subtle accent border based on transaction type
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    isFutureDate ? Color.blue.opacity(0.3) :
                    transaction.isRecurring ? Color.purple.opacity(0.3) :
                    transaction.isSplit ? Color.orange.opacity(0.3) :
                    transactionColor.opacity(0.2),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
}

struct TransactionCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard transaction
            TransactionCardView(transaction:
                Transaction(
                    date: Date(),
                    amount: 45.99,
                    description: "Groceries",
                    type: .expense,
                    categoryId: UUID()
                )
            )
            
            // Future transaction
            TransactionCardView(transaction:
                Transaction(
                    date: Date().addingTimeInterval(60*60*24*5),
                    amount: 200.00,
                    description: "Rent",
                    type: .expense,
                    categoryId: UUID(),
                    isFutureTransaction: true
                )
            )
            
            // Recurring transaction
            TransactionCardView(transaction:
                Transaction(
                    date: Date(),
                    amount: 9.99,
                    description: "Netflix Subscription",
                    type: .expense,
                    categoryId: UUID(),
                    isRecurring: true,
                    recurrenceInterval: .monthly
                )
            )
            
            // Split transaction
            TransactionCardView(transaction: {
                var transaction = Transaction(
                    date: Date(),
                    amount: 24.50,
                    description: "Dinner with Alex",
                    type: .expense,
                    categoryId: UUID()
                )
                transaction.isSplit = true
                transaction.friendName = "Alex"
                transaction.friendAmount = 24.50
                transaction.userAmount = 24.50
                return transaction
            }())
        }
        .environmentObject(FinanceViewModel())
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
