import SwiftUI

struct CategoryEditView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingAddSheet = false
    @State private var editedCategory: Category?
    
    // Used when creating a new category
    @State private var newCategoryName = ""
    @State private var newCategoryType: CategoryType = .expense
    @State private var newCategoryIcon = "tag"
    
    // Available icons for category creation - expanded collection matching onboarding
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
        NavigationView {
            List {
                // Income Categories Section
                Section(header: sectionHeader(title: "Income Categories", iconName: "arrow.down.circle.fill", color: .green)) {
                    if viewModel.incomeCategories.isEmpty {
                        Text("No income categories")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(viewModel.incomeCategories) { category in
                            categoryRow(for: category)
                        }
                        .onDelete { indexSet in
                            deleteCategories(from: viewModel.incomeCategories, at: indexSet)
                        }
                    }
                    
                    // Add Income Category Button
                    addCategoryButton(type: .income)
                }
                
                // Expense Categories Section
                Section(header: sectionHeader(title: "Expense Categories", iconName: "arrow.up.circle.fill", color: .red)) {
                    if viewModel.expenseCategories.isEmpty {
                        Text("No expense categories")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(viewModel.expenseCategories) { category in
                            categoryRow(for: category)
                        }
                        .onDelete { indexSet in
                            deleteCategories(from: viewModel.expenseCategories, at: indexSet)
                        }
                    }
                    
                    // Add Expense Category Button
                    addCategoryButton(type: .expense)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Edit Categories")
        }
        .sheet(isPresented: $showingAddSheet) {
            categoryEditSheet()
        }
    }
    
    // MARK: - UI Components
    
    private func sectionHeader(title: String, iconName: String, color: Color) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
    
    private func categoryRow(for category: Category) -> some View {
        HStack(spacing: 15) {
            // Category icon
            ZStack {
                Circle()
                    .fill(category.type == .income ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: category.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(category.type == .income ? .green : .red)
            }
            
            // Category name
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            // Edit button
            Button(action: {
                editedCategory = category
                newCategoryName = category.name
                newCategoryType = category.type
                newCategoryIcon = category.iconName
                showingAddSheet = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                    Text("Edit")
                        .font(.footnote)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 6)
    }
    
    private func addCategoryButton(type: CategoryType) -> some View {
        Button(action: {
            // Reset for a new category
            editedCategory = nil
            newCategoryName = ""
            newCategoryType = type
            newCategoryIcon = "dollarsign.circle"
            showingAddSheet = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                
                Text("Add \(type == .income ? "Income" : "Expense") Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(type == .income ? .green : .red)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Category Edit Sheet
    
    private func categoryEditSheet() -> some View {
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
                                saveCategory()
                                showingAddSheet = false
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title3)
                                    
                                    Text(editedCategory == nil ? "Add Category" : "Update Category")
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
                                showingAddSheet = false
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
            .navigationTitle(editedCategory == nil ? "Add Category" : "Edit Category")
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Helper Functions
    
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
    
    private func saveCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existingCategory = editedCategory {
            // Update existing category
            let updatedCategory = Category(
                id: existingCategory.id,
                name: trimmedName,
                type: newCategoryType, iconName: newCategoryIcon
            )
            viewModel.updateCategory(updatedCategory)
        } else {
            // Create new category
            let newCategory = Category(
                name: trimmedName,
                type: newCategoryType,
                iconName: newCategoryIcon
            )
            viewModel.addCategory(newCategory)
        }
    }
    
    private func deleteCategories(from categories: [Category], at indexSet: IndexSet) {
        for index in indexSet {
            let category = categories[index]
            viewModel.deleteCategory(category)
        }
    }
}

struct CategoryEditView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CategoryEditView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)
            
            CategoryEditView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
