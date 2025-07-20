import Foundation
import SwiftUI

/// Model to store user preferences and onboarding state
struct UserPreferences: Codable {
    var userName: String = ""
    var themeColorName: String = "Blue"
    var hasCompletedOnboarding: Bool = false
    var currency: Currency = .gbp
    
    static var defaultPreferences: UserPreferences {
        UserPreferences(
            userName: "",
            themeColorName: "Blue",
            hasCompletedOnboarding: false,
            currency: .gbp
        )
    }
}

enum Currency: String, Codable, CaseIterable, Identifiable {
    case gbp = "£"
    case usd = "$"
    case eur = "€"
    
    var id: String { self.rawValue }

    var locale: String {
        switch self {
        case .gbp:
            return "en_GB"
        case .usd:
            return "en_US"
        case .eur:
            return "fr_FR"
        }
    }
    
    var name: String {
        switch self {
        case .gbp:
            return "Pound Sterling"
        case .usd:
            return "US Dollar"
        case .eur:
            return "Euro"
        }
    }
}
