//
//  AnimatedValueView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/15/25.
//


import SwiftUI

/// A simple view that animates a value change with a counting effect
struct AnimatedValueView: View {
    // The current value to display
    let value: Double
    // Font size for the display
    let fontSize: CGFloat
    // Font weight for the display
    let fontWeight: Font.Weight
    // Color for positive values
    let positiveColor: Color
    // Color for negative values
    let negativeColor: Color
    
    // Animation state
    @State private var animatedValue: Double
    
    init(
        value: Double,
        fontSize: CGFloat = 42,
        fontWeight: Font.Weight = .bold,
        positiveColor: Color = .green,
        negativeColor: Color = .red
    ) {
        self.value = value
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        
        // Initialize animated value
        self._animatedValue = State(initialValue: value)
    }
    
    var body: some View {
        // Determine the text color based on the value
        let textColor = value >= 0 ? positiveColor : negativeColor
        
        // Display the formatted currency value
        Text(formatCurrency(animatedValue))
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .onChange(of: value) { newValue in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    animatedValue = newValue
                }
            }
            .onAppear {
                // Initialize to the actual value
                animatedValue = value
            }
    }
    
    // Format as currency
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

// Preview provider
struct AnimatedValueView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedValueView(value: 1234.56)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}