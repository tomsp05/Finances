import Foundation

// Time filter options
enum TransactionTimeFilter: String, CaseIterable {
    case all = "All Time"
    case future = "Future"
    case past = "Past"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case custom = "Custom Range"
    
    var systemImage: String {
        switch self {
        case .all: return "calendar"
        case .future: return "clock.arrow.circlepath"
        case .past: return "clock.arrow.2.circlepath"
        case .today: return "sun.max"
        case .thisWeek: return "calendar.badge.clock"
        case .thisMonth: return "calendar"
        case .lastMonth: return "calendar.badge.minus"
        case .custom: return "calendar.badge.clock"
        }
    }
}

// Transaction filter state model
struct TransactionFilterState {
    // Time filtering
    var timeFilter: TransactionTimeFilter = .all
    var customStartDate: Date? = nil
    var customEndDate: Date? = nil
    
    // Transaction type filtering
    var transactionTypes: Set<TransactionType> = []
    
    // Category filtering
    var selectedCategories: Set<UUID> = []
    
    // Amount filtering
    var minAmount: Double? = nil
    var maxAmount: Double? = nil
    
    // Recurring filter
    var onlyRecurring: Bool = false
    
    // Computed property to check if any filters are active
    var hasActiveFilters: Bool {
        return timeFilter != .all ||
               !transactionTypes.isEmpty ||
               !selectedCategories.isEmpty ||
               minAmount != nil ||
               maxAmount != nil ||
               onlyRecurring
    }
}
