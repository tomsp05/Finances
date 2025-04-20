import SwiftUI

struct BudgetCardView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    var budget: Budget
    
    // Helper formatter for currency
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: BudgetDetailView(budget: budget)) {
            VStack(alignment: .leading, spacing: 12) {
                // Budget title and period
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(budget.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(budget.timePeriod.displayName())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Budget amount
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(budget.amount))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(getBudgetStatusText())
                            .font(.caption)
                            .foregroundColor(getBudgetStatusColor())
                    }
                }
                
                // Progress bar with improved dark mode appearance
                ZStack(alignment: .leading) {
                    // Background track - adjusted for dark mode
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .frame(height: 10)
                    
                    // Foreground progress - adjusted color for dark mode
                    RoundedRectangle(cornerRadius: 10)
                        .fill(getProgressColor())
                        .frame(width: max(5, CGFloat(budget.percentUsed) * UIScreen.main.bounds.width * 0.75), height: 10)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: budget.percentUsed)
                }
                
                // Remaining amount
                HStack {
                    Text("Spent: \(formatCurrency(budget.currentSpent))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Remaining: \(formatCurrency(budget.remainingAmount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
            .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                // Add a subtle border in dark mode for better definition
                RoundedRectangle(cornerRadius: 15)
                    .stroke(getProgressColor().opacity(colorScheme == .dark ? 0.3 : 0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Format currency
    private func formatCurrency(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    // Get color based on budget status with enhanced dark mode support
    private func getProgressColor() -> Color {
        let percentUsed = budget.percentUsed
        
        if percentUsed >= 1.0 {
            return colorScheme == .dark ? .red.opacity(0.9) : .red
        } else if percentUsed >= 0.85 {
            return colorScheme == .dark ? .orange.opacity(0.9) : .orange
        } else if percentUsed >= 0.7 {
            return colorScheme == .dark ? .yellow.opacity(0.9) : .yellow
        } else {
            return viewModel.adaptiveThemeColor
        }
    }
    
    // Get budget status text
    private func getBudgetStatusText() -> String {
        let percentUsed = budget.percentUsed * 100
        
        if percentUsed >= 100 {
            return "Over Budget"
        } else {
            return "\(Int(percentUsed))% Used"
        }
    }
    
    // Get budget status color with dark mode enhancement
    private func getBudgetStatusColor() -> Color {
        let percentUsed = budget.percentUsed
        
        if percentUsed >= 1.0 {
            return .red
        } else if percentUsed >= 0.85 {
            return .orange
        } else {
            return colorScheme == .dark ? .green.opacity(0.9) : .green
        }
    }
}
