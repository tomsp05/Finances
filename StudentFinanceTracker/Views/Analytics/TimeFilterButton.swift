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
                    ? themeColor.opacity(0.2)
                    : Color(.systemGray5)
                )
                .foregroundColor(
                    isSelected
                    ? themeColor
                    : Color(.systemGray)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? themeColor : Color.clear,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TimeFilterButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            TimeFilterButton(
                title: "Week",
                isSelected: true,
                themeColor: Color.blue,
                action: {}
            )
            
            TimeFilterButton(
                title: "Month",
                isSelected: false,
                themeColor: Color.blue,
                action: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}