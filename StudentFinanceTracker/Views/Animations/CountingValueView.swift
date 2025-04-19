import SwiftUI

/// A view that displays a number that animates from one value to another
struct CountingValueView: View {
    /// The target value to display
    let value: Double
    /// The previous value (to animate from)
    let fromValue: Double
    /// Whether counting animation is active
    let isAnimating: Bool
    /// Font size for the text
    let fontSize: CGFloat
    /// Font weight for the text
    let fontWeight: Font.Weight
    /// Color for positive values
    let positiveColor: Color
    /// Color for negative values
    let negativeColor: Color
    
    @State private var displayValue: Double
    @State private var animationTimer: Timer?
    
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
        
        // Initialize with the from value
        self._displayValue = State(initialValue: fromValue)
    }
    
    var body: some View {
        // Get color based on the displayed value
        let color = value >= 0 ? positiveColor : negativeColor
        
        Text(formatCurrency(displayValue))
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(color)
            .onAppear {
                // Start with from value
                displayValue = fromValue
                // Immediately start animation if needed
                if isAnimating {
                    startCounting()
                }
            }
            .onChange(of: isAnimating) { oldValue, newValue in
                if newValue {
                    startCounting()
                } else {
                    // If animation is turned off, jump to final value
                    displayValue = value
                    // Cancel any running timer
                    animationTimer?.invalidate()
                    animationTimer = nil
                }
            }
            .onChange(of: value) { oldValue, newValue in
                if isAnimating {
                    // If already animating, restart the animation
                    startCounting()
                } else {
                    // If not animating, just set the value directly
                    displayValue = newValue
                }
            }
            .onDisappear {
                // Clean up timer when view disappears
                animationTimer?.invalidate()
                animationTimer = nil
            }
    }
    
    /// Starts the counting animation from current displayValue to target value
    private func startCounting() {
        // Cancel any existing animation
        animationTimer?.invalidate()
        
        // Set the starting value correctly
        displayValue = fromValue
        
        // Calculate animation parameters
        let duration = 1.0  // Animation duration in seconds
        let steps = 20      // Number of steps in the animation
        let stepDuration = duration / Double(steps)
        let valueChange = value - fromValue
        let stepValue = valueChange / Double(steps)
        var currentStep = 0
        
        // Create a repeating timer for the animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { timer in
            currentStep += 1
            
            // Update display value
            displayValue += stepValue
            
            // Stop when we've reached the required number of steps
            if currentStep >= steps {
                // Ensure we end exactly at the target value
                displayValue = value
                timer.invalidate()
                animationTimer = nil
            }
        }
    }
    
    /// Formats a double as currency
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
