import SwiftUI

struct BudgetListView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var showingAddBudget = false
    @State private var selectedBudgetForEdit: Budget? = nil
    @Environment(\.colorScheme) var colorScheme

    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with summary
                summaryCard
                
                // Budget sections
                if !overallBudgets.isEmpty {
                    budgetSection(title: "Overall Budgets", icon: "chart.pie.fill", budgets: overallBudgets)
                }
                
                if !categoryBudgets.isEmpty {
                    budgetSection(title: "Category Budgets", icon: "tag.fill", budgets: categoryBudgets)
                }
                
                if !accountBudgets.isEmpty {
                    budgetSection(title: "Account Budgets", icon: "creditcard.fill", budgets: accountBudgets)
                }
                
                // Empty state
                if viewModel.budgets.isEmpty {
                    emptyState
                }
                
                // Add budget button
                addBudgetButton
            }
            .padding(.bottom, 20)
        }
        .navigationTitle("Budgets")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .sheet(isPresented: $showingAddBudget) {
            NavigationView {
                BudgetEditView(isPresented: $showingAddBudget, budget: nil)
                    .navigationTitle("Add Budget")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            showingAddBudget = false
                        }
                    )
            }
        }
        .sheet(item: $selectedBudgetForEdit) { budget in
            NavigationView {
                BudgetEditView(isPresented: $showingAddBudget, budget: budget)
                    .navigationTitle("Edit Budget")
                    .navigationBarItems(
                        leading: Button("Cancel") {
                            selectedBudgetForEdit = nil
                        }
                    )
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var summaryCard: some View {
        VStack(spacing: 16) {
            Text("Budget Overview")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                budgetStat(
                    icon: "chart.pie.fill",
                    value: "\(viewModel.budgets.count)",
                    label: "Active Budgets"
                )
                
                Divider()
                    .background(Color.white.opacity(0.5))
                    .frame(height: 40)
                
                budgetStat(
                    icon: "exclamationmark.triangle.fill",
                    value: "\(overBudgetCount)",
                    label: "Over Budget"
                )
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    viewModel.themeColor.opacity(0.7),
                    viewModel.themeColor
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: viewModel.themeColor.opacity(0.5), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private func budgetStat(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private func budgetSection(title: String, icon: String, budgets: [Budget]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(viewModel.themeColor)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(budgets.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Budget items
            ForEach(budgets) { budget in
                Button(action: {
                    selectedBudgetForEdit = budget
                }) {
                    BudgetCardView(budget: budget)
                        .padding(.horizontal)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48))
                .foregroundColor(.gray.opacity(0.7))
            
            Text("No Budgets Set")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start tracking your spending by creating budgets")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
    
    private var addBudgetButton: some View {
        Button(action: {
            showingAddBudget = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                
                Text("Add New Budget")
                    .fontWeight(.semibold)
            }
            .foregroundColor(viewModel.themeColor)
            .padding()
            .frame(maxWidth: .infinity)
            .background(viewModel.themeColor.opacity(0.1))
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Helper Properties
    
    private var overallBudgets: [Budget] {
        viewModel.budgets.filter { $0.type == .overall }
    }
    
    private var categoryBudgets: [Budget] {
        viewModel.budgets.filter { $0.type == .category }
    }
    
    private var accountBudgets: [Budget] {
        viewModel.budgets.filter { $0.type == .account }
    }
    
    private var overBudgetCount: Int {
        viewModel.budgets.filter { $0.currentSpent > $0.amount }.count
    }
}
