//
//  AnimatedBalanceView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/15/25.
//


import SwiftUI

/// A view that animates the transition between two balance values
struct AnimatedBalanceView: View {
    let value: Double
    let previousValue: Double
    let isAnimating: Bool
    let fontWeight: Font.Weight
    let fontSize: CGFloat
    let positiveColor: Color
    let negativeColor: Color
    
    @State private var animatedValue: Double
    
    init(
        value: Double,
        previousValue: Double,
        isAnimating: Bool,
        fontSize: CGFloat = 42,
        fontWeight: Font.Weight = .bold,
        positiveColor: Color = .green,
        negativeColor: Color = .red
    ) {
        self.value = value
        self.previousValue = previousValue
        self.isAnimating = isAnimating
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        
        // Initialize the animated value with the previous value
        self._animatedValue = State(initialValue: previousValue)
    }
    
    var body: some View {
        // Format the animated value as currency
        let formattedValue = formatCurrency(animatedValue)
        
        // Determine the text color based on whether the value is positive or negative
        let textColor = animatedValue >= 0 ? positiveColor : negativeColor
        
        Text(formattedValue)
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .onChange(of: value) { newValue in
                if isAnimating {
                    // Animate to the new value
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animatedValue = newValue
                    }
                } else {
                    // Update without animation if not animating
                    animatedValue = newValue
                }
            }
            .onChange(of: isAnimating) { animating in
                if animating {
                    // When animation starts, animate to the current value
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animatedValue = value
                    }
                }
            }
            .onAppear {
                // When view first appears, set the animated value without animation
                animatedValue = value
            }
    }
    
    // Helper function to format currency
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
}

struct AnimatedBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            AnimatedBalanceView(
                value: 1250.75,
                previousValue: 1200.00,
                isAnimating: true
            )
            
            AnimatedBalanceView(
                value: -450.25,
                previousValue: -500.00,
                isAnimating: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}