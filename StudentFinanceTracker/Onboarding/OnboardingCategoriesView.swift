import SwiftUI

struct OnboardingCategoriesView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @State private var selectedIncomeCategories: Set<UUID> = []
    @State private var selectedExpenseCategories: Set<UUID> = []
    @Environment(\.colorScheme) var colorScheme
    
    // Square grid layout with 3 items per row
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 25) {
                // Section title with more padding
                Text("Customise Categories")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 30)
                    .padding(.bottom, 5)
                
                // Description text with better padding
                Text("Select the categories that are relevant to your finances. You can add more later.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 15)
                
                // Income Categories Section
                incomeCategoriesSection
                
                // Expense Categories Section
                expenseCategoriesSection
                
                // Extra padding at the bottom to avoid the navigation controls
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal)
        }
        .onAppear {
            // Initially select all categories
            viewModel.incomeCategories.forEach { selectedIncomeCategories.insert($0.id) }
            viewModel.expenseCategories.forEach { selectedExpenseCategories.insert($0.id) }
            
            // Animate appearance
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateElements = true
            }
        }
    }
    
    // Helper function to toggle category selection
    private func toggleCategory(_ id: UUID, in categories: inout Set<UUID>) {
        if categories.contains(id) {
            categories.remove(id)
        } else {
            categories.insert(id)
        }
    }
    
    // MARK: - UI Components
    
    private var incomeCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.green)
                
                Text("Income Categories")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 5)
            .padding(.bottom, 5)
            
            if viewModel.incomeCategories.isEmpty {
                Text("No categories found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                incomeCategoriesGrid
            }
        }
        .padding()
        .background(categoryBackgroundStyle)
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 20)
        .padding(.bottom, 20)
    }
    
    private var incomeCategoriesGrid: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(viewModel.incomeCategories) { category in
                categoryButton(for: category, isIncome: true)
            }
        }
    }
    
    private var expenseCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.red)
                
                Text("Expense Categories")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 5)
            .padding(.bottom, 5)
            
            if viewModel.expenseCategories.isEmpty {
                Text("No categories found")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                expenseCategoriesGrid
            }
        }
        .padding()
        .background(categoryBackgroundStyle)
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 20)
    }
    
    private var expenseCategoriesGrid: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(viewModel.expenseCategories) { category in
                categoryButton(for: category, isIncome: false)
            }
        }
    }
    
    @ViewBuilder
    private func categoryButton(for category: Category, isIncome: Bool) -> some View {
        let isSelected = isIncome
            ? selectedIncomeCategories.contains(category.id)
            : selectedExpenseCategories.contains(category.id)
        
        SquareCategoryButton(
            category: category,
            isSelected: isSelected
        ) {
            if isIncome {
                toggleCategory(category.id, in: &selectedIncomeCategories)
            } else {
                toggleCategory(category.id, in: &selectedExpenseCategories)
            }
        }
    }
    
    private var categoryBackgroundStyle: some View {
        RoundedRectangle(cornerRadius: 15)
            .fill(colorScheme == .dark
                  ? Color(.systemGray6).opacity(0.2)
                  : Color(.systemBackground))
            .shadow(color: colorScheme == .dark
                    ? Color.clear
                    : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Square category selection button for onboarding
struct SquareCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon in colored square
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColorFill)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(backgroundColorStroke, lineWidth: isSelected ? 2 : 0)
                        )
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 22))
                        .foregroundColor(iconColor)
                }
                
                // Category name with text wrapping
                Text(category.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .contentShape(Rectangle())
            .padding(5)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Computed Properties for Colors
    
    private var backgroundColorFill: Color {
        if isSelected {
            return category.type == .income
                ? Color.green.opacity(colorScheme == .dark ? 0.3 : 0.15)
                : Color.red.opacity(colorScheme == .dark ? 0.3 : 0.15)
        } else {
            return colorScheme == .dark
                ? Color(.systemGray5).opacity(0.3)
                : Color(.systemGray6).opacity(0.8)
        }
    }
    
    private var backgroundColorStroke: Color {
        if isSelected {
            return category.type == .income ? .green : .red
        } else {
            return .clear
        }
    }
    
    private var iconColor: Color {
        if isSelected {
            return category.type == .income ? .green : .red
        } else {
            return colorScheme == .dark ? Color.gray.opacity(0.8) : .gray
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return category.type == .income ? .green : .red
        } else {
            return colorScheme == .dark ? .white.opacity(0.7) : .secondary
        }
    }
}

struct OnboardingCategoriesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingCategoriesView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)
            
            OnboardingCategoriesView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
