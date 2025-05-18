import Foundation

enum AccountType: String, Codable, CaseIterable {
    case savings
    case current
    case credit
}

// Define a new struct for account pools
struct Pool: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var color: String // Store color as a string representation
    
    init(name: String, amount: Double, color: String = "blue") {
        self.name = name
        self.amount = amount
        self.color = color
    }
}

struct Account: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: AccountType
    var initialBalance: Double = 0.0
    var balance: Double = 0.0
    var pools: [Pool] = [] // Add the pools array to the Account model
    
    // Computed property to get unallocated balance
    var unallocatedBalance: Double {
        let allocatedAmount = pools.reduce(0.0) { $0 + $1.amount }
        return balance - allocatedAmount
    }
}
