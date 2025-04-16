//
//  IncomeCategory.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/14/25.
//


import Foundation

enum IncomeCategory: String, Codable, CaseIterable {
    case studentLoan
    case bursary
    case partTimeJob
}

struct IncomeSource: Identifiable, Codable {
    var id = UUID()
    var category: IncomeCategory
    var amount: Double
    var dateReceived: Date
}