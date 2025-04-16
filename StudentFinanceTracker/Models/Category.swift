//
//  CategoryType.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/14/25.
//


import Foundation
import SwiftUI

enum CategoryType: String, Codable, CaseIterable {
    case income
    case expense
}

struct Category: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var type: CategoryType
    var iconName: String
    
    static func == (lhs: Category, rhs: Category) -> Bool {
        return lhs.id == rhs.id
    }
}

// Default category collections
extension Category {
    static let defaultIncomeCategories: [Category] = [
        Category(name: "Salary", type: .income, iconName: "dollarsign.circle"),
        Category(name: "Student Loan", type: .income, iconName: "studentdesk"),
        Category(name: "Bursary", type: .income, iconName: "banknote"),
        Category(name: "Gift", type: .income, iconName: "gift"),
        Category(name: "Part-time Job", type: .income, iconName: "briefcase")
    ]
    
    static let defaultExpenseCategories: [Category] = [
        Category(name: "Food", type: .expense, iconName: "fork.knife"),
        Category(name: "Transport", type: .expense, iconName: "bus"),
        Category(name: "Bills", type: .expense, iconName: "doc.text"),
        Category(name: "Entertainment", type: .expense, iconName: "film"),
        Category(name: "Education", type: .expense, iconName: "book"),
        Category(name: "Shopping", type: .expense, iconName: "cart"),
        Category(name: "Housing", type: .expense, iconName: "house"),
        Category(name: "Other", type: .expense, iconName: "ellipsis")
    ]
}
