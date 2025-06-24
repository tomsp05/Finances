import Foundation

struct WidgetData: Codable {
    let netBalance: Double
    let transactions: [Transaction]
}

// Note: Ensure 'Transaction' is available to both the app and the widget targets. If not, you may need to move its definition to a shared location as well.
