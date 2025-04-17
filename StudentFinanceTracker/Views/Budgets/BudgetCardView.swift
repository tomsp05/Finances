//
//  BudgetCardView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/17/25.
//


import SwiftUI

struct BudgetCardView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
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
                        
                        Text(budget.timePeriod.displayName())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Budget amount
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatCurrency(budget.amount))
                            .font(.headline)
                        
                        Text(getBudgetStatusText())
                            .font(.caption)
                            .foregroundColor(getBudgetStatusColor())
                    }
                }
                
                // Progress bar
                ProgressView(value: budget.percentUsed)
                    .progressViewStyle(LinearProgressViewStyle(tint: getProgressColor()))
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
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
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Format currency
    private func formatCurrency(_ value: Double) -> String {
        return currencyFormatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    // Get color based on budget status
    private func getProgressColor() -> Color {
        let percentUsed = budget.percentUsed
        
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
    
    // Get budget status text
    private func getBudgetStatusText() -> String {
        let percentUsed = budget.percentUsed * 100
        
        if percentUsed >= 100 {
            return "Over Budget"
        } else {
            return "\(Int(percentUsed))% Used"
        }
    }
    
    // Get budget status color
    private func getBudgetStatusColor() -> Color {
        let percentUsed = budget.percentUsed
        
        if percentUsed >= 1.0 {
            return .red
        } else if percentUsed >= 0.85 {
            return .orange
        } else {
            return .green
        }
    }
}