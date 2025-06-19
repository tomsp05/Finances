//
//  BudgetCardView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/17/25.
//

import SwiftUI

struct BudgetCardView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    let budget: Budget
    
    // FIXED: Use computed property to get current budget state
    private var currentBudget: Budget {
        viewModel.budgets.first(where: { $0.id == budget.id }) ?? budget
    }
    
    // Helper formatter for currency - FIXED: Make static to avoid recreation
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        NavigationLink(destination: BudgetDetailView(budget: currentBudget)) {
            VStack(alignment: .leading, spacing: 12) {
                // Budget title and icon
                HStack(spacing: 12) {
                    // Budget type icon
                    budgetIconView
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentBudget.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(currentBudget.timePeriod.displayName())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Budget amount and status
                    budgetAmountView
                }
                
                // Progress bar - FIXED: Simplified animation
                progressBarView
                
                // Spending summary
                spendingSummaryView
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(15)
            .shadow(color: shadowColor, radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Subviews
    
    private var budgetIconView: some View {
        ZStack {
            Circle()
                .fill(getBudgetIconBackground())
                .frame(width: 42, height: 42)
            
            Image(systemName: getBudgetIcon())
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(getProgressColor())
        }
    }
    
    private var budgetAmountView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formatCurrency(currentBudget.amount))
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Status tag with pill design
            statusTag
        }
    }
    
    private var statusTag: some View {
        Text(getBudgetStatusText())
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(getBudgetStatusColor())
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(getBudgetStatusColor().opacity(colorScheme == .dark ? 0.3 : 0.15))
            )
    }
    
    private var progressBarView: some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                .frame(height: 8)
            
            // Foreground progress
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 10)
                    .fill(getProgressColor())
                    .frame(width: progressWidth(geometry: geometry))
                    .animation(.easeInOut(duration: 0.3), value: currentBudget.percentUsed)
            }
            .frame(height: 8)
        }
    }
    
    private var spendingSummaryView: some View {
        HStack {
            Text("Spent: \(formatCurrency(currentBudget.currentSpent))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Remaining: \(formatCurrency(currentBudget.remainingAmount))")
                .font(.caption)
                .foregroundColor(remainingAmountColor)
        }
    }
    
    // MARK: - Helper Methods
    
    private func progressWidth(geometry: GeometryProxy) -> CGFloat {
        let progress = min(1.0, max(0.0, currentBudget.percentUsed))
        return geometry.size.width * CGFloat(progress)
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.1)
    }
    
    private var borderColor: Color {
        getProgressColor().opacity(colorScheme == .dark ? 0.3 : 0.1)
    }
    
    private var remainingAmountColor: Color {
        currentBudget.remainingAmount > 0 ? .secondary : .red
    }
    
    // Get budget icon based on budget type
    private func getBudgetIcon() -> String {
        switch currentBudget.type {
        case .overall:
            return "sterlingsign.circle.fill"
        case .category:
            return "tag.fill"
        case .account:
            return "creditcard.fill"
        }
    }
    
    // Get icon background color based on budget type and color scheme
    private func getBudgetIconBackground() -> Color {
        let baseColor = getProgressColor()
        return baseColor.opacity(colorScheme == .dark ? 0.25 : 0.15)
    }
    
    // Format currency - FIXED: Use static formatter
    private func formatCurrency(_ value: Double) -> String {
        return Self.currencyFormatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    // Get color based on budget status with enhanced dark mode support
    private func getProgressColor() -> Color {
        let percentUsed = currentBudget.percentUsed
        
        if percentUsed >= 1.0 {
            return colorScheme == .dark ? .red.opacity(0.9) : .red
        } else if percentUsed >= 0.85 {
            return colorScheme == .dark ? .orange.opacity(0.95) : .orange
        } else if percentUsed >= 0.7 {
            return colorScheme == .dark ? .yellow.opacity(0.9) : .yellow
        } else {
            return viewModel.adaptiveThemeColor
        }
    }
    
    // Get budget status text
    private func getBudgetStatusText() -> String {
        let percentUsed = currentBudget.percentUsed * 100
        
        if percentUsed >= 100 {
            return "Over Budget"
        } else {
            return "\(Int(percentUsed))% Used"
        }
    }
    
    // Get budget status color with dark mode enhancement
    private func getBudgetStatusColor() -> Color {
        let percentUsed = currentBudget.percentUsed
        
        if percentUsed >= 1.0 {
            return .red
        } else if percentUsed >= 0.85 {
            return .orange
        } else {
            return colorScheme == .dark ? .green.opacity(0.9) : .green
        }
    }
}
