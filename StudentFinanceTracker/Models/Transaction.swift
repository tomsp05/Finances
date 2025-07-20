import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
    case transfer
}

enum RecurrenceInterval: String, Codable, CaseIterable {
    case none
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly
    
    var description: String {
        switch self {
        case .none: return "None"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .quarterly: return "Every 3 Months"
        case .yearly: return "Yearly"
        }
    }
}

struct Transaction: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var amount: Double
    var description: String
    var fromAccount: AccountType?
    var toAccount: AccountType?
    var fromAccountId: UUID?
    var toAccountId: UUID?
    var type: TransactionType
    
    /// Category ID for the transaction
    var categoryId: UUID
    
    // Split payment properties
    var isSplit: Bool = false
    var friendName: String = ""
    var friendAmount: Double = 0.0
    var userAmount: Double = 0.0
    
    // New property for split payment destination
    var friendPaymentDestination: String = ""
    var friendPaymentAccountId: UUID? = nil
    var friendPaymentIsAccount: Bool = false
    
    // New properties for future and recurring transactions
    var isFutureTransaction: Bool = false
    var isRecurring: Bool = false
    var recurrenceInterval: RecurrenceInterval = .none
    var recurrenceEndDate: Date? = nil
    var parentTransactionId: UUID? = nil // For recurring transactions
    
    // New property for pool assignment
    var poolId: UUID? = nil
    
    // Helper computed property to get total amount
    var totalAmount: Double {
        isSplit ? (userAmount + friendAmount) : amount
    }
}
