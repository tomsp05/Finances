//
//  EnhancedBudgetCardView.swift
//   
//
//  Created by Tom Speake on 8/12/25.
//

import SwiftUI


// MARK: - Enhanced Budget Card View

struct EnhancedBudgetCardView: View {
    let budget: Budget
    let viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(budget.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(budget.type.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(Color.secondary.opacity(colorScheme == .dark ? 0.7 : 1))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(colorScheme == .dark ? 0.15 : 0.2))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                // Status indicator
                statusIndicator
            }
            
            // Progress section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(viewModel.formatCurrency(budget.currentSpent))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(progressColor)
                    
                    Text("of \(viewModel.formatCurrency(budget.amount))")
                        .font(.callout)
                        .foregroundColor(Color.secondary.opacity(colorScheme == .dark ? 0.7 : 1))
                    
                    Spacer()
                    
                    Text("\(Int(progressPercentage))%")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(progressColor)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(colorScheme == .dark ? 0.15 : 0.3))
                            .frame(height: 6)
                            .cornerRadius(3)
                        
                        Rectangle()
                            .fill(progressColor)
                            .frame(
                                width: min(geometry.size.width,
                                         geometry.size.width * CGFloat(progressPercentage / 100)),
                                height: 6
                            )
                            .cornerRadius(3)
                            .animation(.easeInOut(duration: 0.3), value: progressPercentage)
                    }
                }
                .frame(height: 6)
            }
            
            // Time remaining (if applicable)
            if let timeRemaining = timeRemainingText {
                Text(timeRemaining)
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(colorScheme == .dark ? 0.7 : 1))
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.1), radius: colorScheme == .dark ? 8 : 5, x: 0, y: colorScheme == .dark ? 3 : 2)
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(progressColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
    }
    
    private var progressColor: Color {
        if progressPercentage <= 80 {
            return .green
        } else if progressPercentage <= 100 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var progressPercentage: Double {
        guard budget.amount > 0 else { return 0 }
        return (budget.currentSpent / budget.amount) * 100
    }
    
    private var timeRemainingText: String? {
        // Implement based on your budget period logic
        return nil // Placeholder
    }
}
