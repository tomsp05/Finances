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
            VStack(alignment: .leading, spacing: 14) {
                // Budget title and icon
                HStack(spacing: 12) {
                    // Budget type icon
                    ZStack {
                        Circle()
                            .fill(getBudgetIconBackground())
                            .frame(width: 42, height: 42)
                        
                        Image(systemName: getBudgetIcon())
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(getProgressColor())
                    }
                    
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
                        
                        // Status tag with pill design
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
                }
                
                // Progress bar - using 1.0 for budget.percentUsed when budget is over
                ZStack(alignment: .leading) {
                    // Background track - adjusted for dark mode
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .frame(height: 10)
                    
                    // Foreground progress - adjusted color for dark mode
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getProgressColor())
                            .frame(width: budget.currentSpent >= budget.amount ?
                                  geometry.size.width :
                                  geometry.size.width * CGFloat(budget.percentUsed))
                    }
                    .frame(height: 10)
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
                        .foregroundColor(budget.remainingAmount > 0 ? .secondary : .red)
                }
            }
            .padding(16)
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
    
    // Get budget icon based on budget type
    private func getBudgetIcon() -> String {
        switch budget.type {
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
            return colorScheme == .dark ? .orange.opacity(0.95) : .orange
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
