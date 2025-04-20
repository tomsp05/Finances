//
//  TimeFilterButton.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/15/25.
//


import SwiftUI

struct TimeFilterButton: View {
    let title: String
    let isSelected: Bool
    let themeColor: Color
    let colorScheme: ColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? themeColor.opacity(colorScheme == .dark ? 0.3 : 0.2)
                    : Color(UIColor.tertiarySystemFill)
                )
                .foregroundColor(
                    isSelected
                    ? themeColor
                    : Color(UIColor.secondaryLabel)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? themeColor.opacity(colorScheme == .dark ? 0.5 : 1.0) : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeFilterButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HStack {
                TimeFilterButton(
                    title: "Week",
                    isSelected: true,
                    themeColor: Color.blue,
                    colorScheme: .light,
                    action: {}
                )
                
                TimeFilterButton(
                    title: "Month",
                    isSelected: false,
                    themeColor: Color.blue,
                    colorScheme: .light,
                    action: {}
                )
            }
            .padding()
            .previewDisplayName("Light Mode")
            
            HStack {
                TimeFilterButton(
                    title: "Week",
                    isSelected: true,
                    themeColor: Color.blue,
                    colorScheme: .dark,
                    action: {}
                )
                
                TimeFilterButton(
                    title: "Month",
                    isSelected: false,
                    themeColor: Color.blue,
                    colorScheme: .dark,
                    action: {}
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .environment(\.colorScheme, .dark)
            .previewDisplayName("Dark Mode")
        }
        .previewLayout(.sizeThatFits)
    }
}
