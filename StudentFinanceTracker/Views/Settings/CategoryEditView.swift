import SwiftUI

struct CategoryEditView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingAddSheet = false
    @State private var editedCategory: Category?
    
    // Used when creating a new category
    @State private var newCategoryName = ""
    @State private var newCategoryType: CategoryType = .expense
    @State private var newCategoryIcon = "tag"
    
    // Common SF Symbols that would work well as category icons
    let availableIcons = [
        "tag", "star", "dollarsign.circle", "creditcard", "banknote", "gift",
        "car", "bus", "tram", "bicycle", "airplane", "house", "building",
        "fork.knife", "cup.and.saucer", "cart", "bag", "briefcase",
        "graduationcap", "book", "newspaper", "tv", "gamecontroller",
        "laptopcomputer", "desktopcomputer", "headphones", "music.note",
        "camera", "theatermasks", "figure.walk", "heart", "cross",
        "pills", "waveform.path.ecg", "bandage", "bed.double",
        "studentdesk", "building.columns", "keyboard",
        "hammer", "screwdriver", "wrench", "scissors", "pencil",
        "doc.text", "folder", "paperplane", "phone"
    ]
    
    var body: some View {
        NavigationView {
            List {
                // Income Categories Section
                incomeCategoriesSection
                
                // Expense Categories Section
                expenseCategoriesSection
            }
            .navigationTitle("Edit Categories")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Reset for a new category
                        editedCategory = nil
                        newCategoryName = ""
                        newCategoryType = .expense
                        newCategoryIcon = "tag"
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            categoryEditSheet
        }
    }
    
    // MARK: - Extracted Views
    
    // Income Categories Section
    private var incomeCategoriesSection: some View {
        Section(header: Text("Income Categories")) {
            ForEach(viewModel.incomeCategories) { category in
                categoryRow(for: category)
            }
            .onDelete { indexSet in
                deleteCategories(from: viewModel.incomeCategories, at: indexSet)
            }
        }
    }
    
    // Expense Categories Section
    private var expenseCategoriesSection: some View {
        Section(header: Text("Expense Categories")) {
            ForEach(viewModel.expenseCategories) { category in
                categoryRow(for: category)
            }
            .onDelete { indexSet in
                deleteCategories(from: viewModel.expenseCategories, at: indexSet)
            }
        }
    }
    
    // Individual category row
    private func categoryRow(for category: Category) -> some View {
        HStack {
            Image(systemName: category.iconName)
                .foregroundColor(category.type == .income ? .green : .red)
                .frame(width: 30)
            
            Text(category.name)
            
            Spacer()
            
            Button(action: {
                editedCategory = category
                newCategoryName = category.name
                newCategoryType = category.type
                newCategoryIcon = category.iconName
                showingAddSheet = true
            }) {
                Image(systemName: "pencil")
                    .foregroundColor(.blue)
            }
        }
    }
    
    // Category Edit Sheet
    private var categoryEditSheet: some View {
        NavigationView {
            Form {
                // Category Details Section
                categoryDetailsSection
                
                // Icon Selection Section
                iconSelectionSection
            }
            .navigationTitle(editedCategory == nil ? "Add Category" : "Edit Category")
            .navigationBarItems(
                leading: Button("Cancel") {
                    showingAddSheet = false
                },
                trailing: Button("Save") {
                    saveCategory()
                    showingAddSheet = false
                }
                .disabled(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    // Category Details Section in Edit Sheet
    private var categoryDetailsSection: some View {
        Section(header: Text("Category Details")) {
            TextField("Category Name", text: $newCategoryName)
            
            Picker("Type", selection: $newCategoryType) {
                Text("Income").tag(CategoryType.income)
                Text("Expense").tag(CategoryType.expense)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // Icon Selection Section in Edit Sheet
    private var iconSelectionSection: some View {
        Section(header: Text("Choose Icon")) {
            iconSelectionGrid
        }
    }
    
    // Icon Selection Grid
    private var iconSelectionGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
            ForEach(availableIcons, id: \.self) { iconName in
                iconSelectionButton(for: iconName)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Icon Selection Button
    private func iconSelectionButton(for iconName: String) -> some View {
        Button(action: {
            newCategoryIcon = iconName
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(getBackgroundColor(for: iconName))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(getForegroundColor())
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Functions
    
    // Get background color for icon button
    private func getBackgroundColor(for iconName: String) -> Color {
        if newCategoryIcon == iconName {
            return newCategoryType == .income ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
        } else {
            return Color.gray.opacity(0.1)
        }
    }
    
    // Get foreground color for icon
    private func getForegroundColor() -> Color {
        return newCategoryType == .income ? .green : .red
    }
    
    private func saveCategory() {
        let trimmedName = newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        if let existingCategory = editedCategory {
            // Update existing category
            let updatedCategory = Category(
                id: existingCategory.id,
                name: trimmedName,
                type: newCategoryType,
                iconName: newCategoryIcon
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
        CategoryEditView().environmentObject(FinanceViewModel())
    }
}
