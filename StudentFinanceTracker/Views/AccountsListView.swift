import SwiftUI

struct AccountsListView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    // Animation state
    @State private var isAppearing: Bool = false
    
    /// Computes the net current balance:
    /// (Current account balance) minus (sum of credit card balances)
    private var netCurrentBalance: Double {
        let currentBalance = viewModel.accounts.first(where: { $0.type == .current })?.balance ?? 0.0
        let creditCards = viewModel.accounts.filter { $0.type == .credit }
        let creditTotal = creditCards.reduce(0.0) { $0 + $1.balance }
        return currentBalance - creditTotal
    }
    
    /// Computes the total net worth:
    /// Sum of all savings and current accounts, minus credit card debt
    private var netWorth: Double {
        let savingsTotal = viewModel.accounts.filter { $0.type == .savings }
            .reduce(0.0) { $0 + $1.balance }
        let currentTotal = viewModel.accounts.filter { $0.type == .current }
            .reduce(0.0) { $0 + $1.balance }
        let creditTotal = viewModel.accounts.filter { $0.type == .credit }
            .reduce(0.0) { $0 + $1.balance }
        
        return savingsTotal + currentTotal - creditTotal
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
                // Financial summary section with net worth and net balance side by side
                HStack(spacing: 12) {
                    // Net Worth card - using the app's theme color
                    VStack(spacing: 8) {
                        Text("Net Worth")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(formatCurrency(netWorth))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        
                        Text("Total assets")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                viewModel.themeColor.opacity(0.9),
                                viewModel.themeColor.opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .shadow(color: viewModel.themeColor.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Net Balance card - using a slightly darker variant of the theme color
                    VStack(spacing: 8) {
                        Text("Net Balance")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(formatCurrency(netCurrentBalance))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                        
                        Text("Spending")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 20)
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
                }
                .padding(.horizontal)
                .padding(.top)
                .offset(y: isAppearing ? 0 : 25)
                .opacity(isAppearing ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isAppearing)
                
                // Account breakdown section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account Breakdown")
                        .font(.headline)
                        .padding(.horizontal)
                        .offset(y: isAppearing ? 0 : 15)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: isAppearing)
                    
                    // Pie chart representation of accounts
                    if !viewModel.accounts.isEmpty {
                        accountDistributionView()
                            .frame(height: 150)
                            .padding(.bottom, 10)
                            .offset(y: isAppearing ? 0 : 25)
                            .opacity(isAppearing ? 1.0 : 0.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: isAppearing)
                    }
                }
                .padding(.top, 5)
                
                // Current Accounts Section
                if !currentAccounts.isEmpty {
                    accountSection(title: "Current Accounts", accounts: currentAccounts, iconName: "banknote.fill", delay: 0.5)
                }
                
                // Savings Accounts Section
                if !savingsAccounts.isEmpty {
                    accountSection(title: "Savings Accounts", accounts: savingsAccounts, iconName: "building.columns.fill", delay: 0.6)
                }
                
                // Credit Card Accounts Section
                if !creditAccounts.isEmpty {
                    accountSection(title: "Credit Cards", accounts: creditAccounts, iconName: "creditcard.fill", delay: 0.7)
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
                .offset(y: isAppearing ? 0 : 20)
                .opacity(isAppearing ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8), value: isAppearing)
            }
        }
        .navigationTitle("Accounts")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
    
    // Account distribution visualization
    private func accountDistributionView() -> some View {
        HStack(alignment: .center, spacing: 20) {
            // Simplified pie chart visualization
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 120, height: 120)
                
                // Savings segment
                if netWorth != 0 {
                    let savingsTotal = viewModel.accounts.filter { $0.type == .savings }.reduce(0.0) { $0 + $1.balance }
                    let savingsPortion = abs(savingsTotal) / (abs(savingsTotal) + abs(netCurrentBalance) + abs(viewModel.accounts.filter { $0.type == .credit }.reduce(0.0) { $0 + $1.balance }))
                    Circle()
                        .trim(from: 0, to: savingsPortion)
                        .stroke(getAccountColor(.savings), lineWidth: 15)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                
                    // Current account segment
                    let currentPortion = abs(netCurrentBalance) / (abs(savingsTotal) + abs(netCurrentBalance) + abs(viewModel.accounts.filter { $0.type == .credit }.reduce(0.0) { $0 + $1.balance }))
                    Circle()
                        .trim(from: 0, to: currentPortion)
                        .stroke(getAccountColor(.current), lineWidth: 15)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90 + 360 * savingsPortion))
                
                    // Credit segment
                    let creditTotal = viewModel.accounts.filter { $0.type == .credit }.reduce(0.0) { $0 + $1.balance }
                    let creditPortion = abs(creditTotal) / (abs(savingsTotal) + abs(netCurrentBalance) + abs(creditTotal))
                    Circle()
                        .trim(from: 0, to: creditPortion)
                        .stroke(getAccountColor(.credit), lineWidth: 15)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90 + 360 * (savingsPortion + currentPortion)))
                }
            }
            
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                // Savings indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(getAccountColor(.savings))
                        .frame(width: 12, height: 12)
                    
                    Text("Savings")
                        .font(.caption)
                    
                    Spacer()
                    
                    let savingsTotal = savingsAccounts.reduce(0.0) { $0 + $1.balance }
                    Text(formatCurrency(savingsTotal))
                        .font(.caption)
                        .foregroundColor(savingsTotal >= 0 ? .primary : .red)
                }
                
                // Current indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(getAccountColor(.current))
                        .frame(width: 12, height: 12)
                    
                    Text("Current")
                        .font(.caption)
                    
                    Spacer()
                    
                    let currentTotal = currentAccounts.reduce(0.0) { $0 + $1.balance }
                    Text(formatCurrency(currentTotal))
                        .font(.caption)
                        .foregroundColor(currentTotal >= 0 ? .primary : .red)
                }
                
                // Credit indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(getAccountColor(.credit))
                        .frame(width: 12, height: 12)
                    
                    Text("Credit")
                        .font(.caption)
                    
                    Spacer()
                    
                    let creditTotal = creditAccounts.reduce(0.0) { $0 + $1.balance }
                    Text(formatCurrency(creditTotal))
                        .font(.caption)
                        .foregroundColor(creditTotal > 0 ? .red : .primary)
                }
            }
            .padding(.leading, 5)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    // Helper function to create account sections with delay parameter
    private func accountSection(title: String, accounts: [Account], iconName: String, delay: Double = 0) -> some View {
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
            .offset(y: isAppearing ? 0 : 15)
            .opacity(isAppearing ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: isAppearing)
            
            // Account cards in this section - now styled like transaction cards
            ForEach(Array(accounts.enumerated()), id: \.1.id) { index, account in
                VStack(spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        // Icon with colored background - matching transaction card style
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            getAccountColor(account.type).opacity(colorScheme == .dark ? 0.8 : 0.7),
                                            getAccountColor(account.type).opacity(colorScheme == .dark ? 0.6 : 0.5)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 42, height: 42)
                        
                            Image(systemName: getAccountIcon(account.type))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .shadow(color: getAccountColor(account.type).opacity(colorScheme == .dark ? 0.2 : 0.3), radius: 3, x: 0, y: 2)
                        .scaleEffect(isAppearing ? 1.0 : 0.8)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        
                        // Account details
                        VStack(alignment: .leading, spacing: 4) {
                            Text(account.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            // Account type pill
                            Text(accountTypeName(account.type))
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.15))
                                .foregroundColor(viewModel.themeColor)
                                .cornerRadius(4)
                        }
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .offset(x: isAppearing ? 0 : -10)
                        
                        Spacer()
                        
                        // Balance with styling matching transaction cards
                        VStack(alignment: .trailing, spacing: 4) {
                            // Initial balance as pill
                            Text("Initial: \(formatCurrency(account.initialBalance))")
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color(UIColor.tertiarySystemFill))
                                .cornerRadius(4)
                                .foregroundColor(.secondary)
                            
                            // Current balance with better styling
                            Text(formatCurrency(account.balance))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(getBalanceColor(account))
                            
                            // Balance change indicator
                            if account.balance != account.initialBalance {
                                let difference = account.balance - account.initialBalance
                                HStack(spacing: 4) {
                                    Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .font(.system(size: 10))
                                    
                                    Text(formatCurrency(abs(difference)))
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(difference >= 0 ? .green : .red)
                            }
                        }
                        .scaleEffect(isAppearing ? 1.0 : 1.1)
                        .opacity(isAppearing ? 1.0 : 0.0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
                )
                .overlay(
                    // Add a subtle accent border based on account type
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(getAccountColor(account.type).opacity(colorScheme == .dark ? 0.3 : 0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                .offset(y: isAppearing ? 0 : 20)
                .opacity(isAppearing ? 1.0 : 0.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7)
                    .delay(delay + 0.1 + Double(index) * 0.05),
                    value: isAppearing
                )
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
    
    private func accountTypeName(_ type: AccountType) -> String {
        switch type {
        case .savings: return "Savings"
        case .current: return "Current"
        case .credit: return "Credit"
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
