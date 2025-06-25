// StudentFinanceTracker/ViewModels/WidgetData.swift

import Foundation

struct WidgetData: Codable {
    let netBalance: Double
    let transactions: [Transaction]
    let themeColorData: Data?
    let categories: [Category] // <-- ADD THIS
}
