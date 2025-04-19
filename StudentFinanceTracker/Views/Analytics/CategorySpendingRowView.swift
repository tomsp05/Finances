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
    
    var percentage: Double {
        guard totalAmount > 0 else { return 0 }
        return categorySpending.amount / totalAmount
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: categorySpending.category.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(.red)
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
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct CategorySpendingRowView_Previews: PreviewProvider {
    static var previews: some View {
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
            formatCurrency: formatter
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
