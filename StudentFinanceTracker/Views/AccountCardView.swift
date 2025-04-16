import SwiftUI

struct AccountCardView: View {
    // Access the global FinanceViewModel to get the user-selected theme.
    @EnvironmentObject var viewModel: FinanceViewModel
    // The account to display.
    var account: Account

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(account.name)
                .font(.headline)
                .foregroundColor(.white)
                
            // Format the balance manually using NumberFormatter instead of the extension
            Text(formatCurrency(account.balance))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(viewModel.themeColor) // Uses the user-selected pastel theme colour.
        .cornerRadius(15)
        .shadow(color: viewModel.themeColor.opacity(0.5), radius: 8, x: 0, y: 4)
    }
    
    // Helper function to format currency without relying on the extension
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

struct AccountCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a sample account and a FinanceViewModel for previewing.
        AccountCardView(account: Account(name: "Savings Account",
                                          type: .savings,
                                          initialBalance: 1000.0,
                                          balance: 1200.50))
            .environmentObject(FinanceViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
