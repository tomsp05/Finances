//
//  UserPreferences.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/20/25.
//


import Foundation
import SwiftUI

/// Model to store user preferences and onboarding state
struct UserPreferences: Codable {
    // User identification
    var userName: String = ""
    
    // Theme preferences
    var themeColorName: String = "Blue"
    
    // Onboarding state
    var hasCompletedOnboarding: Bool = false
    
    // Currency format
    var currencySymbol: String = "£"
    var locale: String = "en_GB"
    
    // Default preferences
    static var defaultPreferences: UserPreferences {
        UserPreferences(
            userName: "",
            themeColorName: "Blue",
            hasCompletedOnboarding: false,
            currencySymbol: "£",
            locale: "en_GB"
        )
    }
}