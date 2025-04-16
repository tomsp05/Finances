//
//  PayCreditCardView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/15/25.
//


import SwiftUI

struct PayCreditCardView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var selectedFromAccount: AccountType = .current
    @State private var selectedCreditCard: AccountType = .credit
    @State private var selectedCreditCardId: UUID? = nil
    @State private var description: String = "Credit Card Payment"
    
    // Filtered accounts for the from picker - only non-credit accounts
    private var fromAccounts: [Account] {
        viewModel.accounts.filter { $0.type != .credit }
    }
    
    // Filtered accounts for the credit card picker - only credit accounts
    private var creditCards: [Account] {
        viewModel.accounts.filter { $0.type == .credit }
    }
    
    // Helper properties
    private var formattedAmount: String {
        guard let amountValue = Double(amount) else { return "£0.00" }
        return formatCurrency(amountValue)
    }
    
    // Get a default category for transfers
    private var defaultCategoryId: UUID {
        viewModel.expenseCategories.first(where: { $0.name == "Bills" })?.id ?? 
        viewModel.expenseCategories.first?.id ?? UUID()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 48))
                        .foregroundColor(viewModel.themeColor)
                    
                    Text("Pay Credit Card")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Transfer money from an account to pay off credit card debt")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 16)
                
                // Credit card selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Select Credit Card")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if creditCards.isEmpty {
                        Text("No credit cards found")
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(15)
                    } else {
                        ForEach(creditCards) { card in
                            Button(action: {
                                selectedCreditCardId = card.id
                            }) {
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(viewModel.themeColor)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(card.name)
                                            .font(.headline)
                                        
                                        Text("Current balance: \(formatCurrency(card.balance))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedCreditCardId == card.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(viewModel.themeColor)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(selectedCreditCardId == card.id ? 
                                              viewModel.themeColor.opacity(0.1) : Color(.systemBackground))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(selectedCreditCardId == card.id ? 
                                                viewModel.themeColor : Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal)
                
                // From account selection
                VStack(alignment: .leading, spacing: 10) {
                    Text("Pay From")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        HStack {
                            Text("From")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Picker("", selection: $selectedFromAccount) {
                                ForEach(fromAccounts, id: \.id) { account in
                                    Text(account.name).tag(account.type)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        .padding()
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                
                // Amount entry with preview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Payment Amount")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        HStack {
                            TextField("0.00", text: $amount)
                                .font(.system(size: 24, weight: .bold))
                                .keyboardType(.decimalPad)
                                .padding()
                            
                            Spacer()
                            
                            Text(formattedAmount)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.trailing)
                        }
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                
                // Date picker
                VStack(alignment: .leading, spacing: 10) {
                    Text("Payment Date")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .padding()
                    }
                    .frame(height: 60)
                }
                .padding(.horizontal)
                
                // Payment button
                Button(action: makePayment) {
                    Text("Make Payment")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedCreditCardId != nil ? viewModel.themeColor : Color.gray
                        )
                        .cornerRadius(15)
                        .shadow(color: (selectedCreditCardId != nil ? viewModel.themeColor : Color.gray).opacity(0.5), radius: 8, x: 0, y: 4)
                }
                .disabled(selectedCreditCardId == nil)
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.vertical, 20)
        }
        .navigationTitle("Pay Credit Card")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // Updated makePayment method for PayCreditCardView.swift

    private func makePayment() {
        guard let amountDouble = Double(amount),
              let creditCardId = selectedCreditCardId,
              let creditCard = viewModel.accounts.first(where: { $0.id == creditCardId })
        else { return }
        
        // Create a transfer transaction
        let paymentDescription = "Payment to \(creditCard.name)"
        
        let transaction = Transaction(
            date: date,
            amount: amountDouble,
            description: paymentDescription,
            fromAccount: selectedFromAccount,
            toAccount: .credit,
            type: .transfer,
            categoryId: defaultCategoryId
        )
        
        // Add transaction (triggers balance update animation in ContentView)
        viewModel.addTransaction(transaction)
        
        // Add haptic feedback for successful payment
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show a brief confirmation animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            // You would need to add a @State var isPaymentSuccessful = false at the top of your view
            // isPaymentSuccessful = true
        }
        
        // After a short delay, dismiss the view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            presentationMode.wrappedValue.dismiss()
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

struct PayCreditCardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PayCreditCardView().environmentObject(FinanceViewModel())
        }
    }
}
