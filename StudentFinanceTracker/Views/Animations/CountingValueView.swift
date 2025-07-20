import SwiftUI

struct CountingValueView: View {
    let value: Double
    let fromValue: Double
    let isAnimating: Bool
    let fontSize: CGFloat
    let currency: Currency
    let positiveColor: Color
    let negativeColor: Color

    @State private var animatedValue: Double

    init(value: Double, fromValue: Double, isAnimating: Bool, fontSize: CGFloat, currency: Currency, positiveColor: Color, negativeColor: Color) {
        self.value = value
        self.fromValue = fromValue
        self.isAnimating = isAnimating
        self.fontSize = fontSize
        self.currency = currency
        self.positiveColor = positiveColor
        self.negativeColor = negativeColor
        _animatedValue = State(initialValue: fromValue)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency.rawValue
        formatter.locale = Locale(identifier: currency.locale)
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(currency.rawValue)0.00"
    }

    var body: some View {
        Text(formatCurrency(animatedValue))
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(animatedValue >= 0 ? positiveColor : negativeColor)
            .onChange(of: isAnimating) {
                if isAnimating {
                    // Use a spring animation for a more natural effect
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                        animatedValue = value
                    }
                } else {
                    // Instantly set the value if not animating
                    animatedValue = value
                }
            }
            .onAppear {
                // Set the initial value correctly on appear
                animatedValue = isAnimating ? fromValue : value
            }
            .onChange(of: value) {
                // Ensure the view updates if the value changes while not animating
                if !isAnimating {
                    animatedValue = value
                }
            }
    }
}
