import SwiftUI

struct AccountsListView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    
    /// Computes the net current balance:
    /// (Current account balance) minus (sum of credit card balances)
    private var netCurrentBalance: Double {
        let currentBalance = viewModel.accounts.first(where: { $0.type == .current })?.balance ?? 0.0
        let creditCards = viewModel.accounts.filter { $0.type == .credit }
        let creditTotal = creditCards.reduce(0.0) { $0 + $1.balance }
        return currentBalance - creditTotal
    }
    
    // Split accounts by type for better organization
    private var savingsAccounts: [Account] {
        viewModel.accounts.filter { $0.type == .savings }
    }
    
    private var currentAccounts: [Account] {
        viewModel.accounts.filter { $0.type == .current }
    }
    
    private var creditAccounts: [Account] {
        viewModel.accounts.filter { $0.type == .credit }
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary card at the top showing net balance
                VStack(spacing: 8) {
                    Text("Net Balance")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(formatCurrency(netCurrentBalance))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Current balance minus credit card debt")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            viewModel.themeColor.opacity(0.7),
                            viewModel.themeColor
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: viewModel.themeColor.opacity(0.5), radius: 10, x: 0, y: 5)
                .padding(.horizontal)
                .padding(.top)
                
                // Current Accounts Section
                if !currentAccounts.isEmpty {
                    accountSection(title: "Current Accounts", accounts: currentAccounts, iconName: "banknote.fill")
                }
                
                // Savings Accounts Section
                if !savingsAccounts.isEmpty {
                    accountSection(title: "Savings Accounts", accounts: savingsAccounts, iconName: "building.columns.fill")
                }
                
                // Credit Card Accounts Section
                // Credit Card Accounts Section
                                if !creditAccounts.isEmpty {
                                    accountSection(title: "Credit Cards", accounts: creditAccounts, iconName: "creditcard.fill")
                                    
                                    // Add Pay Credit Card button
                                    NavigationLink(destination: PayCreditCardView()) {
                                        HStack {
                                            Image(systemName: "creditcard.arrow.and.receipt")
                                                .font(.title2)
                                                .foregroundColor(viewModel.themeColor)
                                            
                                            Text("Pay Credit Card")
                                                .fontWeight(.semibold)
                                                .foregroundColor(viewModel.themeColor)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(viewModel.themeColor.opacity(0.1))
                                        .cornerRadius(15)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                                }
                
                // Add Account Button
                NavigationLink(destination: SettingsView()) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        
                        Text("Add New Account")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.themeColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.themeColor.opacity(0.1))
                    .cornerRadius(15)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .navigationTitle("Accounts")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // Helper function to create account sections
    private func accountSection(title: String, accounts: [Account], iconName: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(viewModel.themeColor)
                    .font(.headline)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(accounts.count)")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Account cards in this section
            ForEach(accounts) { account in
                HStack(spacing: 16) {
                    // Account type indicator
                    ZStack {
                        Circle()
                            .fill(getAccountColor(account.type).opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: getAccountIcon(account.type))
                            .font(.system(size: 24))
                            .foregroundColor(getAccountColor(account.type))
                    }
                    
                    // Account details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.name)
                            .font(.headline)
                        
                        Text("Initial: \(formatCurrency(account.initialBalance))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Balance with color indication
                    VStack(alignment: .trailing) {
                        Text(formatCurrency(account.balance))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(getBalanceColor(account))
                        
                        // Balance change indicator
                        if account.balance != account.initialBalance {
                            let difference = account.balance - account.initialBalance
                            HStack(spacing: 2) {
                                Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                                    .font(.system(size: 10))
                                
                                Text(formatCurrency(abs(difference)))
                                    .font(.caption)
                            }
                            .foregroundColor(difference >= 0 ? .green : .red)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
            }
        }
    }
    
    // Helper functions for account display
    private func getAccountIcon(_ type: AccountType) -> String {
        switch type {
        case .savings: return "building.columns.fill"
        case .current: return "banknote.fill"
        case .credit: return "creditcard.fill"
        }
    }
    
    private func getAccountColor(_ type: AccountType) -> Color {
        switch type {
        case .savings: return .blue
        case .current: return .green
        case .credit: return .purple
        }
    }
    
    private func getBalanceColor(_ account: Account) -> Color {
        if account.type == .credit {
            return account.balance > 0 ? .red : .green
        } else {
            return account.balance >= 0 ? .green : .red
        }
    }
}

struct AccountsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountsListView().environmentObject(FinanceViewModel())
        }
    }
}
