//
//  OnboardingAccountsView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/20/25.
//


import SwiftUI

struct OnboardingAccountsView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @State private var accounts: [AccountSetup] = [
        AccountSetup(name: "Current Account", type: .current, initialBalance: 0.0, isEnabled: true),
        AccountSetup(name: "Savings Account", type: .savings, initialBalance: 0.0, isEnabled: true),
        AccountSetup(name: "Credit Card", type: .credit, initialBalance: 0.0, isEnabled: false)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Section title
                Text("Set Up Your Accounts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 40)
                
                // Description text
                Text("Add your bank accounts and set their initial balances")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Accounts setup
                VStack(spacing: 20) {
                    ForEach(0..<accounts.count, id: \.self) { index in
                        OnboardingAccountRow(
                            account: $accounts[index]
                        )
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut.delay(0.2 + Double(index) * 0.1), value: animateElements)
                    }
                }
                .padding(.horizontal)
                
                // Add account button
                Button(action: {
                    withAnimation {
                        accounts.append(AccountSetup(name: "New Account", type: .savings, initialBalance: 0.0, isEnabled: true))
                    }
                }) {
                    Label("Add Another Account", systemImage: "plus.circle")
                        .font(.headline)
                        .foregroundColor(viewModel.themeColor)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.themeColor.opacity(0.1))
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .opacity(animateElements ? 1 : 0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.easeOut.delay(0.5), value: animateElements)
                
                Spacer()
            }
            .padding(.bottom, 80)
        }
        .onAppear {
            // Animate appearance
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                animateElements = true
            }
        }
        .onDisappear {
            // Save the accounts when navigating away
            saveAccounts()
        }
    }
    
    private func saveAccounts() {
        // Clear existing accounts
        viewModel.accounts = []
        
        // Add all enabled accounts with their initial balances
        for accountSetup in accounts where accountSetup.isEnabled {
            let newAccount = Account(
                name: accountSetup.name,
                type: accountSetup.type,
                initialBalance: accountSetup.initialBalance,
                balance: accountSetup.initialBalance
            )
            viewModel.accounts.append(newAccount)
        }
        
        // Save the accounts
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

// Account setup row for onboarding
struct OnboardingAccountRow: View {
    @Binding var account: AccountSetup
    @EnvironmentObject var viewModel: FinanceViewModel
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                // Account type icon
                ZStack {
                    Circle()
                        .fill(getAccountColor().opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: getAccountIcon())
                        .font(.system(size: 18))
                        .foregroundColor(getAccountColor())
                }
                
                // Account name and type picker
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Account Name", text: $account.name)
                        .font(.headline)
                    
                    Picker("Type", selection: $account.type) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Toggle to enable/disable
                Toggle("", isOn: $account.isEnabled)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: viewModel.themeColor))
            }
            
            // Balance input field (only if enabled)
            if account.isEnabled {
                HStack {
                    Text("Initial Balance")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack {
                        Text("£")
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", value: $account.initialBalance, formatter: NumberFormatter.currencyFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                .padding(.leading, 56) // Align with text after the icon
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    // Helper functions for icon and color
    private func getAccountIcon() -> String {
        switch account.type {
        case .savings:
            return "building.columns.fill"
        case .current:
            return "banknote.fill"
        case .credit:
            return "creditcard.fill"
        }
    }
    
    private func getAccountColor() -> Color {
        switch account.type {
        case .savings:
            return .blue
        case .current:
            return .green
        case .credit:
            return .red
        }
    }
}

// Number formatter for currency
extension NumberFormatter {
    static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
}