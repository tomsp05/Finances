//
//  OnboardingCategoriesView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/20/25.
//


import SwiftUI

struct OnboardingCategoriesView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @State private var selectedIncomeCategories: Set<UUID> = []
    @State private var selectedExpenseCategories: Set<UUID> = []
    
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Section title
                Text("Customize Categories")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 40)
                
                // Description text
                Text("Select the categories that are relevant to your finances. You can add more later.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Income Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Income Categories")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.incomeCategories) { category in
                            OnboardingCategoryButton(
                                category: category,
                                isSelected: selectedIncomeCategories.contains(category.id),
                                onTap: {
                                    if selectedIncomeCategories.contains(category.id) {
                                        selectedIncomeCategories.remove(category.id)
                                    } else {
                                        selectedIncomeCategories.insert(category.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)
                
                // Expense Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Expense Categories")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.expenseCategories) { category in
                            OnboardingCategoryButton(
                                category: category,
                                isSelected: selectedExpenseCategories.contains(category.id),
                                onTap: {
                                    if selectedExpenseCategories.contains(category.id) {
                                        selectedExpenseCategories.remove(category.id)
                                    } else {
                                        selectedExpenseCategories.insert(category.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.easeOut.delay(0.2), value: animateElements)
                
                Spacer()
            }
            .padding(.bottom, 80)
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
}

// Custom category selection button for onboarding
struct OnboardingCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject var viewModel: FinanceViewModel
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              (category.type == .income ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) :
                              Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ?
                                        (category.type == .income ? .green : .red) :
                                        .gray)
                }
                
                Text(category.name)
                    .font(.callout)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
            .frame(width: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          (category.type == .income ? Color.green.opacity(0.1) : Color.red.opacity(0.1)) :
                          Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ?
                            (category.type == .income ? Color.green : Color.red) :
                            Color.clear,
                            lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}