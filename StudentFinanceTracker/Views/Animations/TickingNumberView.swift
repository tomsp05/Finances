//
//  TickingNumberView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/15/25.
//


import SwiftUI

struct TickingNumberView: View {
    /// The target value to display
    let value: Double
    /// The previous value (to animate from)
    let fromValue: Double
    /// Whether animation is active
    let isAnimating: Bool
    /// Font size for the text
    let fontSize: CGFloat
    /// Font weight for the text
    let fontWeight: Font.Weight
    /// Color for positive values
    let positiveColor: Color
    /// Color for negative values
    let negativeColor: Color
    
    // Animation state
    @State private var displayValue: Double
    @State private var animationDuration: Double = 1.0
    
    init(
        value: Double,
        fromValue: Double,
        isAnimating: Bool,
        fontSize: CGFloat = 42,
        fontWeight: Font.Weight = .bold,
        positiveColor: Color = .green,
        negativeColor: Color = .red
    ) {
        self.value = value
        self.fromValue = fromValue
        self.isAnimating = isAnimating
        self.fontSize = fontSize
        self.fontWeight = fontWeight
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        
        // Initialize with the final value for safety
        // Will be set to fromValue when animation starts
        self._displayValue = State(initialValue: value)
    }
    
    var body: some View {
        // Color based on the final value (not the transitional one)
        let textColor = value >= 0 ? positiveColor : negativeColor
        
        Text(formatCurrency(displayValue))
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(textColor)
            .onAppear {
                // Always show the correct final value if not animating
                if !isAnimating {
                    displayValue = value
                }
            }
            .onChange(of: isAnimating) { startAnimation in
                if startAnimation {
                    // Start the animation from fromValue to value
                    startTickingAnimation()
                } else {
                    // If animation stops, show final value
                    displayValue = value
                }
            }
            .onChange(of: value) { newValue in
                if !isAnimating {
                    // Update immediately if not animating
                    displayValue = newValue
                }
            }
    }
    
    private func startTickingAnimation() {
        // Set to starting value
        displayValue = fromValue
        
        // Calculate animation steps
        let totalSteps = 20
        let stepDuration = animationDuration / Double(totalSteps)
        
        // Create a sequence of steps for smoother animation
        for step in 1...totalSteps {
            let delayTime = stepDuration * Double(step)
            let stepFraction = Double(step) / Double(totalSteps)
            
            // Calculate intermediate value using easing
            let animationProgress = 1 - pow(1 - stepFraction, 2) // Ease out quad
            let stepValue = fromValue + (value - fromValue) * animationProgress
            
            // Schedule update for this step
            DispatchQueue.main.asyncAfter(deadline: .now() + delayTime) {
                self.displayValue = stepValue
                
                // Ensure we end at the exact value
                if step == totalSteps {
                    self.displayValue = self.value
                }
            }
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

struct TickingNumberView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 50) {
            TickingNumberView(
                value: 1250.50,
                fromValue: 1200.00,
                isAnimating: true
            )
            
            TickingNumberView(
                value: -250.75,
                fromValue: -200.00,
                isAnimating: true
            )
        }
        .padding()
    }
}