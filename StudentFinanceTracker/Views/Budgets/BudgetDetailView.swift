//
//  BudgetDetailView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/17/25.
//


import SwiftUI

struct BudgetDetailView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var showingEditSheet = false
    @Environment(\.colorScheme) var colorScheme

    
    var budget: Budget
    
    // The actual budget might update in the ViewModel, need to find it
    private var currentBudget: Budget {
        viewModel.budgets.first(where: { $0.id == budget.id }) ?? budget
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Budget overview card
                budgetOverviewCard
                
                // Budget details
                budgetDetailsCard
                
                // Recent transactions
                recentTransactionsSection
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(currentBudget.name)
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingEditSheet = true
                }) {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                BudgetEditView(isPresented: $showingEditSheet, budget: currentBudget)
                    .navigationTitle("Edit Budget")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingEditSheet = false
                        }
                    )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var budgetOverviewCard: some View {
        VStack(spacing: 16) {
            // Progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(currentBudget.percentUsed, 1.0)))
                    .stroke(getProgressColor(), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: currentBudget.percentUsed)
                
                VStack(spacing: 4) {
                    Text("\(Int(currentBudget.percentUsed * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Used")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            
            // Budget amount
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentBudget.amount))
                        .font(.headline)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentBudget.currentSpent))
                        .font(.headline)
                }
                
                Divider()
                    .frame(height: 30)
                
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(currentBudget.remainingAmount))
                        .font(.headline)
                        .foregroundColor(getBudgetStatusColor())
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var budgetDetailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Details")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                detailRow(title: "Type", value: getBudgetTypeText())
                
                Divider()
                    .padding(.leading, 120)
                
                detailRow(title: "Period", value: currentBudget.timePeriod.displayName())
                
                Divider()
                    .padding(.leading, 120)
                
                detailRow(title: "Started On", value: formatDate(currentBudget.startDate))
                
                // Show specific details based on budget type
                if currentBudget.type == .category, let categoryId = currentBudget.categoryId,
                   let category = viewModel.getCategory(id: categoryId) {
                    Divider()
                        .padding(.leading, 120)
                    
                    detailRow(title: "Category", value: category.name)
                }
                
                if currentBudget.type == .account, let accountId = currentBudget.accountId,
                   let account = viewModel.accounts.first(where: { $0.id == accountId }) {
                    Divider()
                        .padding(.leading, 120)
                    
                    detailRow(title: "Account", value: account.name)
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .padding(.horizontal)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .fontWeight(.medium)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Transactions")
                .font(.headline)
                .padding(.horizontal)
            
            if relevantTransactions.isEmpty {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        
                        Text("No transactions yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(30)
                    
                    Spacer()
                }
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .padding(.horizontal)
            } else {
                ForEach(relevantTransactions.prefix(5)) { transaction in
                    TransactionCardView(transaction: transaction)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Get relevant transactions for this budget
    private var relevantTransactions: [Transaction] {
        // Filter expense transactions that fall within the budget period
        let expenseTransactions = viewModel.transactions.filter { 
            $0.type == .expense && $0.date >= currentBudget.startDate
        }
        
        // Further filter based on budget type
        switch currentBudget.type {
        case .overall:
            return expenseTransactions
            
        case .category:
            guard let categoryId = currentBudget.categoryId else { return [] }
            return expenseTransactions.filter { $0.categoryId == categoryId }
            
        case .account:
            guard let accountId = currentBudget.accountId,
                  let account = viewModel.accounts.first(where: { $0.id == accountId }) else { return [] }
            return expenseTransactions.filter { $0.fromAccount == account.type }
        }
    }
    
    private func getBudgetTypeText() -> String {
        switch currentBudget.type {
        case .overall: return "Overall"
        case .category: return "Category"
        case .account: return "Account"
        }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func getProgressColor() -> Color {
        let percentUsed = currentBudget.percentUsed
        
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
    
    private func getBudgetStatusColor() -> Color {
        let percentUsed = currentBudget.percentUsed
        
        if percentUsed >= 1.0 {
            return .red
        } else if percentUsed >= 0.85 {
            return .orange
        } else {
            return .green
        }
    }
}
