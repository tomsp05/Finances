import SwiftUI

struct SplitPaymentView: View {
    @Binding var isSplit: Bool
    @Binding var friendName: String
    @Binding var friendAmount: String
    @Binding var userAmount: String
    @Binding var totalAmount: String
    @Binding var friendPaymentDestination: String
    @Binding var friendPaymentAccountId: UUID?
    @Binding var friendPaymentIsAccount: Bool
    
    @EnvironmentObject var viewModel: FinanceViewModel
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    private var formattedFriendAmount: String {
        guard let amountValue = Double(friendAmount) else { return "£0.00" }
        return formatCurrency(amountValue)
    }
    
    private var formattedUserAmount: String {
        guard let amountValue = Double(userAmount) else { return "£0.00" }
        return formatCurrency(amountValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Split Payment")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Toggle("Split with a friend", isOn: $isSplit)
                .padding(.vertical, 5)
            
            if isSplit {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    TextField("Friend's name", text: $friendName)
                        .padding()
                }
                .frame(height: 60)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        Text("Friend paid:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        TextField("0.00", text: $friendAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        
                        Text(formattedFriendAmount)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                    .padding()
                }
                .frame(height: 60)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    HStack {
                        Text("You paid:")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        TextField("0.00", text: $userAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        
                        Text(formattedUserAmount)
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                    }
                    .padding()
                }
                .frame(height: 60)
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Friend's payment went to:")
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Toggle("To my account", isOn: $friendPaymentIsAccount)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        if friendPaymentIsAccount {
                            HStack {
                                Spacer()
                                
                                Picker("Select Account", selection: $friendPaymentAccountId) {
                                    ForEach(viewModel.accounts, id: \.id) { account in
                                        Text(account.name).tag(account.id as UUID?)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 200, alignment: .trailing)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        } else {
                            TextField("Enter destination (Cash, etc)", text: $friendPaymentDestination)
                                .padding(.horizontal)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .frame(height: 110)
                
                HStack {
                    Text("Total amount:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let userAmountDouble = Double(userAmount),
                       let friendAmountDouble = Double(friendAmount) {
                        Text(formatCurrency(userAmountDouble + friendAmountDouble))
                            .font(.headline)
                    } else {
                        Text("£0.00")
                            .font(.headline)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
        .onChange(of: isSplit) { newValue in
            if newValue {
                if let totalAmountDouble = Double(totalAmount) {
                    let halfAmount = totalAmountDouble / 2
                    userAmount = String(format: "%.2f", halfAmount)
                    friendAmount = String(format: "%.2f", halfAmount)
                }
            } else {
                friendName = ""
                friendAmount = "0.00"
                userAmount = totalAmount
                friendPaymentDestination = ""
                friendPaymentAccountId = nil
                friendPaymentIsAccount = false
            }
        }
        .onChange(of: totalAmount) { newValue in
            if isSplit {
                if let totalAmountDouble = Double(newValue) {
                    let userAmountDouble = Double(userAmount) ?? 0
                    let friendAmountDouble = Double(friendAmount) ?? 0
                    let currentTotal = userAmountDouble + friendAmountDouble
                    
                    if currentTotal > 0 {
                        let userRatio = userAmountDouble / currentTotal
                        let friendRatio = friendAmountDouble / currentTotal
                        
                        userAmount = String(format: "%.2f", totalAmountDouble * userRatio)
                        friendAmount = String(format: "%.2f", totalAmountDouble * friendRatio)
                    } else {
                        let halfAmount = totalAmountDouble / 2
                        userAmount = String(format: "%.2f", halfAmount)
                        friendAmount = String(format: "%.2f", halfAmount)
                    }
                }
            } else {
                userAmount = newValue
            }
        }
        .onChange(of: friendPaymentIsAccount) { newValue in
            if newValue {
                if friendPaymentAccountId == nil && !viewModel.accounts.isEmpty {
                    friendPaymentAccountId = viewModel.accounts.first?.id
                }
                friendPaymentDestination = ""
            } else {
                friendPaymentAccountId = nil
            }
        }
    }
}
