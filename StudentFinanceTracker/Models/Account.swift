import Foundation

enum AccountType: String, Codable, CaseIterable {
    case savings
    case current
    case credit
}

struct Pool: Identifiable, Codable {
    var id = UUID()
    var name: String
    var amount: Double
    var color: String 
    
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
    var pools: [Pool] = []
    
    var unallocatedBalance: Double {
        let allocatedAmount = pools.reduce(0.0) { $0 + $1.amount }
        return balance - allocatedAmount
    }
}
