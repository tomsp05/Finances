import SwiftUI

struct OnboardingAccountsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @State private var accounts: [AccountSetup] = [
        AccountSetup(name: "Current Account", type: .current, initialBalance: 0.0, isEnabled: true),
        AccountSetup(name: "Savings Account", type: .savings, initialBalance: 0.0, isEnabled: true),
        AccountSetup(name: "Credit Card", type: .credit, initialBalance: 0.0, isEnabled: false)
    ]
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 10) {
                    Text("Set Up Your Accounts")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeColor)
                        .padding(.top, 30)

                    Text("Add your bank accounts and set their initial balances")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .foregroundColor(.secondary)
                }
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)

                // Info card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(viewModel.themeColor)

                        Text("You can add multiple accounts to track your finances across different banks and account types.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )
                .padding(.horizontal)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.easeOut.delay(0.1), value: animateElements)

                // Accounts section
                VStack(spacing: 15) {
                    Text("Your Accounts")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut.delay(0.2), value: animateElements)

                    // Accounts stack
                    VStack(spacing: 15) {
                        ForEach(0..<accounts.count, id: \.self) { index in
                            ImprovedAccountRow(
                                account: $accounts[index],
                                viewModel: viewModel
                            )
                            .opacity(animateElements ? 1 : 0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut.delay(0.3 + Double(index) * 0.1), value: animateElements)
                        }
                    }
                    .padding(.horizontal)
                }

                // Add account button
                Button(action: {
                    withAnimation {
                        accounts.append(AccountSetup(name: "New Account", type: .savings, initialBalance: 0.0, isEnabled: true))
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)

                        Text("Add Another Account")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewModel.themeColor)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.themeColor.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.easeOut.delay(0.5), value: animateElements)

                // Extra padding at the bottom to avoid the navigation controls
                Spacer()
                    .frame(height: 150)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 100)
        }
        .onAppear {
            if !viewModel.accounts.isEmpty {
                accounts = []
                for account in viewModel.accounts {
                    accounts.append(AccountSetup(
                        name: account.name,
                        type: account.type,
                        initialBalance: account.initialBalance,
                        isEnabled: true
                    ))
                }
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateElements = true
            }
        }
        .onDisappear {
            saveAccounts()
        }
    }

    private func saveAccounts() {
        viewModel.accounts = []

        for accountSetup in accounts where accountSetup.isEnabled {
            let newAccount = Account(
                name: accountSetup.name,
                type: accountSetup.type,
                initialBalance: accountSetup.initialBalance,
                balance: accountSetup.initialBalance
            )
            viewModel.accounts.append(newAccount)
        }

        DataService.shared.saveAccounts(viewModel.accounts)
    }
}

// Helper struct for account setup
struct AccountSetup: Identifiable {
    var id = UUID()
    var name: String
    var type: AccountType
    var initialBalance: Double
    var isEnabled: Bool
}

// Improved account setup row for onboarding
struct ImprovedAccountRow: View {
    @Binding var account: AccountSetup
    let viewModel: FinanceViewModel
    @State private var isExpanded: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: viewModel.userPreferences.currency.locale)
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(getAccountColor().opacity(colorScheme == .dark ? 0.3 : 0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: getAccountIcon())
                            .font(.system(size: 18))
                            .foregroundColor(getAccountColor())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(account.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(account.type.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: $account.isEnabled)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: viewModel.themeColor))

                    Image(systemName: "chevron.\(isExpanded ? "up" : "down")")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                }
                .contentShape(Rectangle())
                .padding()
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded && account.isEnabled {
                VStack(spacing: 15) {
                    Divider()
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Account Name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        TextField("Account Name", text: $account.name)
                            .padding(12)
                            .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Account Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        HStack(spacing: 10) {
                            ForEach(AccountType.allCases, id: \.self) { type in
                                ImprovedAccountTypeButton(
                                    type: type,
                                    isSelected: account.type == type,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            account.type = type
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Initial Balance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Done") {
                                hideKeyboard()
                            }
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.themeColor)
                        }
                        .padding(.horizontal)

                        HStack {
                            Text(viewModel.userPreferences.currency.rawValue)
                                .foregroundColor(.secondary)
                                .font(.headline)
                                .padding(.leading, 12)

                            TextField("0.00", value: $account.initialBalance, formatter: currencyFormatter)
                                .keyboardType(.decimalPad)
                                .padding(12)
                        }
                        .background(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    if account.type == .credit {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(viewModel.themeColor)

                            Text("For credit cards, a positive balance means you owe money to the credit card company.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                    }
                }
                .padding(.bottom, 15)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func getAccountIcon() -> String { getTypeIcon(account.type) }
    private func getAccountColor() -> Color { getTypeColor(account.type) }

    private func getTypeIcon(_ type: AccountType) -> String {
        switch type {
        case .savings: return "building.columns.fill"
        case .current: return "banknote.fill"
        case .credit: return "creditcard.fill"
        }
    }

    private func getTypeColor(_ type: AccountType) -> Color {
        switch type {
        case .savings: return .blue
        case .current: return .green
        case .credit: return .purple
        }
    }
}

// Improved account type selection button
struct ImprovedAccountTypeButton: View {
    let type: AccountType
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ?
                              getTypeColor(type) :
                              colorScheme == .dark ?
                                Color(.systemGray5).opacity(0.5) :
                                Color(.systemGray5))
                        .frame(width: 52, height: 52)

                    Image(systemName: getTypeIcon(type))
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ?
                                         .white :
                                         colorScheme == .dark ?
                                            Color(.systemGray).opacity(0.8) :
                                            Color(.systemGray2))
                }

                Text(getTypeName(type))
                    .font(.footnote)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ?
                                     getTypeColor(type) :
                                     colorScheme == .dark ?
                                        .white.opacity(0.8) :
                                        .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          getTypeColor(type).opacity(colorScheme == .dark ? 0.3 : 0.1) :
                          colorScheme == .dark ?
                            Color(.systemGray6).opacity(0.2) :
                            Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ?
                                    getTypeColor(type) :
                                    colorScheme == .dark ?
                                        Color.gray.opacity(0.3) :
                                        Color.clear,
                                    lineWidth: isSelected ? 1.5 : colorScheme == .dark ? 0.5 : 0)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isSelected)
    }

    private func getTypeIcon(_ type: AccountType) -> String {
        switch type {
        case .savings: return "building.columns.fill"
        case .current: return "banknote.fill"
        case .credit: return "creditcard.fill"
        }
    }

    private func getTypeColor(_ type: AccountType) -> Color {
        switch type {
        case .savings: return .blue
        case .current: return .green
        case .credit: return .purple
        }
    }

    private func getTypeName(_ type: AccountType) -> String {
        switch type {
        case .savings: return "Savings"
        case .current: return "Current"
        case .credit: return "Credit"
        }
    }
}

struct OnboardingAccountsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingAccountsView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)

            OnboardingAccountsView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
