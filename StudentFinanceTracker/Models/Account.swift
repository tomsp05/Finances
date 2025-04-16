import Foundation

enum AccountType: String, Codable, CaseIterable {
    case savings
    case current
    case credit
}

struct Account: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: AccountType
    var initialBalance: Double = 0.0
    var balance: Double = 0.0
}
