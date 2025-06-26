//
//  darkMode.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/17/25.
//


import SwiftUI

extension FinanceViewModel {
    /// Returns a dynamic version of the theme color that adapts to dark mode
    var adaptiveThemeColor: Color {
        switch themeColorName {
        case "Blue":
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 1.0) :
                UIColor(red: 0.20, green: 0.40, blue: 0.70, alpha: 1.0)
            })
        case "Green":
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.25, green: 0.60, blue: 0.35, alpha: 1.0) :
                UIColor(red: 0.20, green: 0.55, blue: 0.30, alpha: 1.0)
            })
        case "Orange":
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.85, green: 0.45, blue: 0.25, alpha: 1.0) :
                UIColor(red: 0.80, green: 0.40, blue: 0.20, alpha: 1.0)
            })
        case "Purple":
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.55, green: 0.30, blue: 0.75, alpha: 1.0) :
                UIColor(red: 0.50, green: 0.25, blue: 0.70, alpha: 1.0)
            })
        case "Red":
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ?
                UIColor(red: 0.75, green: 0.25, blue: 0.25, alpha: 1.0) :
                UIColor(red: 0.70, green: 0.20, blue: 0.20, alpha: 1.0)
            })
        case "Teal":
                    return Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark ?
                        UIColor(red: 0.25, green: 0.55, blue: 0.65, alpha: 1.0) :
                        UIColor(red: 0.20, green: 0.50, blue: 0.60, alpha: 1.0)
                    })
                case "Pink":
                    return Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark ?
                        UIColor(red: 0.90, green: 0.50, blue: 0.70, alpha: 1.0) :
                        UIColor(red: 0.90, green: 0.40, blue: 0.60, alpha: 1.0)
                    })
                default:
                    return Color(UIColor { traitCollection in
                        traitCollection.userInterfaceStyle == .dark ?
                        UIColor(red: 0.25, green: 0.45, blue: 0.85, alpha: 1.0) :
                        UIColor(red: 0.20, green: 0.40, blue: 0.70, alpha: 1.0)
                    })
                }
            }
    
    /// Returns appropriate background colors for cards
    func cardBackgroundColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color(UIColor.systemBackground)
    }
    
    /// Returns appropriate shadow for the current color scheme
    func shadowColor(for colorScheme: ColorScheme) -> Color {
        return colorScheme == .dark ? Color.clear : Color.black.opacity(0.07)
    }
    
    /// Returns appropriate opacity for overlays in the current scheme
    func overlayOpacity(for colorScheme: ColorScheme, baseOpacity: Double = 0.1) -> Double {
        return colorScheme == .dark ? baseOpacity * 2 : baseOpacity
    }
}
