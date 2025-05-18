import SwiftUI

struct OnboardingCategoriesView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @State private var selectedIncomeCategories: Set<UUID> = []
    @State private var selectedExpenseCategories: Set<UUID> = []
    @Environment(\.colorScheme) var colorScheme
    
    // Add category modal states
    @State private var showingAddCategorySheet = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "dollarsign.circle"
    @State private var newCategoryType: CategoryType = .income
    
    // Square grid layout with 3 items per row
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    // Available icons for category creation
    private let availableIcons = [
        "dollarsign.circle", "creditcard", "giftcard", "cart", "house", "car", "bus", "tram",
        "airplane", "bicycle", "bag", "backpack", "case", "gift", "gamecontroller",
        "tv", "laptopcomputer", "desktopcomputer", "headphones", "wifi", "phone",
        "stethoscope", "cross", "pills", "drop", "flame", "bolt", "lightbulb", "leaf",
        "sun.max", "moon.stars", "cloud", "umbrella", "fork.knife", "wineglass", "cup.and.saucer",
        "figure.walk", "figure.run", "figure.wave", "graduationcap", "book", "pencil", "paintbrush",
        "hammer", "scissors", "music.note", "film", "photo", "theatermasks", "pawprint", "heart"
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
                Text("Select the categories that are relevant to your finances or create your own custom categories.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 15)
                
                // Income Categories Section
                incomeCategoriesSection
                
                // Add Income Category Button
                addCategoryButton(type: .income)
                    .padding(.bottom, 20)
                
                // Expense Categories Section
                expenseCategoriesSection
                
                // Add Expense Category Button
                addCategoryButton(type: .expense)
                
                // Extra padding at the bottom to avoid the navigation controls
                Spacer()
                    .frame(height: 120)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showingAddCategorySheet) {
            addCategoryView()
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
        .onChange(of: selectedIncomeCategories) { _ in
            updateSelectedCategories()
        }
        .onChange(of: selectedExpenseCategories) { _ in
            updateSelectedCategories()
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
    
    // Update the selected categories in the view model
    private func updateSelectedCategories() {
        // This will be called when we finalize the onboarding
        // For now, we're just tracking selections in local state
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
    
    private func addCategoryButton(type: CategoryType) -> some View {
        Button(action: {
            newCategoryType = type
            showingAddCategorySheet = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                
                Text("Add \(type == .income ? "Income" : "Expense") Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(type == .income ? .green : .red)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        type == .income
                        ? Color.green.opacity(colorScheme == .dark ? 0.2 : 0.1)
                        : Color.red.opacity(colorScheme == .dark ? 0.2 : 0.1)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        type == .income
                        ? Color.green.opacity(0.5)
                        : Color.red.opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
        .padding(.horizontal)
        .opacity(animateElements ? 1 : 0)
        .offset(y: animateElements ? 0 : 20)
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
    
    // MARK: - Add Category Sheet
    
    private func addCategoryView() -> some View {
        NavigationView {
            ZStack {
                viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Category name field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            TextField("e.g., Salary or Groceries", text: $newCategoryName)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.themeColor.opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal)
                        }
                        
                        // Type selector
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Category Type")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Picker("Category Type", selection: $newCategoryType) {
                                Text("Income").tag(CategoryType.income)
                                Text("Expense").tag(CategoryType.expense)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal)
                        }
                        
                        // Icon selector
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Select an Icon")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 15) {
                                ForEach(availableIcons, id: \.self) { iconName in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            newCategoryIcon = iconName
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(iconBackgroundColor(for: iconName))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: iconName)
                                                .font(.system(size: 20))
                                                .foregroundColor(iconForegroundColor(for: iconName))
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .scaleEffect(newCategoryIcon == iconName ? 1.1 : 1.0)
                                    .animation(.spring(response: 0.2, dampingFraction: 0.7), value: newCategoryIcon == iconName)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.themeColor.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Selected icon preview
                        HStack {
                            Text("Selected Icon:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ZStack {
                                Circle()
                                    .fill(iconBackgroundColor(for: newCategoryIcon))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: newCategoryIcon)
                                    .font(.system(size: 20))
                                    .foregroundColor(iconForegroundColor(for: newCategoryIcon))
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(viewModel.themeColor.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Buttons
                        VStack(spacing: 15) {
                            Button(action: {
                                saveNewCategory()
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    
                                    Text("Add Category")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            isNewCategoryValid()
                                            ? (newCategoryType == .income ? Color.green : Color.red)
                                            : Color.gray.opacity(0.3)
                                        )
                                )
                                .padding(.horizontal)
                            }
                            .disabled(!isNewCategoryValid())
                            
                            Button(action: {
                                showingAddCategorySheet = false
                                resetNewCategoryForm()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                    
                                    Text("Cancel")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(viewModel.themeColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.themeColor.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(viewModel.themeColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Category")
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Helper Functions for Category Creation
    
    private func iconBackgroundColor(for iconName: String) -> Color {
        if newCategoryIcon == iconName {
            return newCategoryType == .income
                ? Color.green.opacity(colorScheme == .dark ? 0.3 : 0.2)
                : Color.red.opacity(colorScheme == .dark ? 0.3 : 0.2)
        } else {
            return colorScheme == .dark
                ? Color(.systemGray5).opacity(0.3)
                : Color(.systemGray6).opacity(0.8)
        }
    }
    
    private func iconForegroundColor(for iconName: String) -> Color {
        if newCategoryIcon == iconName {
            return newCategoryType == .income ? .green : .red
        } else {
            return colorScheme == .dark ? Color.gray : Color.gray
        }
    }
    
    private func isNewCategoryValid() -> Bool {
        return !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func resetNewCategoryForm() {
        newCategoryName = ""
        newCategoryIcon = "dollarsign.circle"
    }
    
    private func saveNewCategory() {
        guard isNewCategoryValid() else { return }
        
        // Create a new category
        let newCategory = Category(
            id: UUID(),
            name: newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines),
            type: newCategoryType, iconName: newCategoryIcon
        )
        
        // Update the appropriate array in the view model
        if newCategoryType == .income {
            viewModel.incomeCategories.append(newCategory)
            // Also select the new category
            selectedIncomeCategories.insert(newCategory.id)
        } else {
            viewModel.expenseCategories.append(newCategory)
            // Also select the new category
            selectedExpenseCategories.insert(newCategory.id)
        }
        
        // Reset form and close sheet
        resetNewCategoryForm()
        showingAddCategorySheet = false
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
