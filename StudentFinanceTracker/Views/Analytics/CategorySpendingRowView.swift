//
//  CategorySpendingRowView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/15/25.
//


import SwiftUI

struct CategorySpendingRowView: View {
    let categorySpending: CategorySpending
    let totalAmount: Double
    let formatCurrency: (Double) -> String
    let colorScheme: ColorScheme
    
    var percentage: Double {
        guard totalAmount > 0 else { return 0 }
        return categorySpending.amount / totalAmount
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(getCategoryColor().opacity(colorScheme == .dark ? 0.25 : 0.2))
                    .frame(width: 42, height: 42)
                
                Image(systemName: categorySpending.category.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(getCategoryColor())
            }
            
            // Category details
            VStack(alignment: .leading, spacing: 4) {
                Text(categorySpending.category.name)
                    .font(.headline)
                
                Text("\(categorySpending.count) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount and percentage
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(categorySpending.amount))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(String(format: "%.1f%%", percentage * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(getCategoryColor().opacity(colorScheme == .dark ? 0.2 : 0.1))
                    )
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(getCategoryColor().opacity(colorScheme == .dark ? 0.25 : 0.1), lineWidth: 1)
        )
    }
    
    // Get appropriate color based on category type
    private func getCategoryColor() -> Color {
        return categorySpending.category.type == .expense ? .red : .green
    }
}

struct CategorySpendingRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let formatter: (Double) -> String = { value in
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencySymbol = "£"
                return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
            }
            
            let category = Category(name: "Food", type: .expense, iconName: "fork.knife")
            let categorySpending = CategorySpending(id: UUID(), category: category, amount: 250.0, count: 12)
            
            CategorySpendingRowView(
                categorySpending: categorySpending,
                totalAmount: 1000.0,
                formatCurrency: formatter,
                colorScheme: .light
            )
            .padding()
            .previewDisplayName("Light Mode")
            
            CategorySpendingRowView(
                categorySpending: categorySpending,
                totalAmount: 1000.0,
                formatCurrency: formatter,
                colorScheme: .dark
            )
            .padding()
            .background(Color.black)
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark Mode")
        }
        .previewLayout(.sizeThatFits)
    }
}
