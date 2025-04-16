//
//  EditBalancesView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/14/25.
//


import SwiftUI

struct EditBalancesView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    /// A temporary dictionary of account IDs to their string representations of the preset balances.
    @State private var balances: [UUID: String] = [:]
    
    var body: some View {
        Form {
            Section(header: Text("Edit Preset Balances")) {
                ForEach(viewModel.accounts) { account in
                    HStack {
                        Text(account.name)
                        Spacer()
                        TextField("Preset", text: Binding(
                            get: { balances[account.id] ?? String(format: "%.2f", account.initialBalance) },
                            set: { balances[account.id] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                }
            }
            Button("Save Balances") {
                saveBalances()
            }
        }
        .navigationTitle("Preset Balances")
        .onAppear {
            // Populate the dictionary with the current initial balances
            for account in viewModel.accounts {
                balances[account.id] = String(format: "%.2f", account.initialBalance)
            }
        }
    }
    
    private func saveBalances() {
        // Update each account’s initial balance from the text field.
        for i in 0..<viewModel.accounts.count {
            let account = viewModel.accounts[i]
            if let newValue = balances[account.id], let newBalance = Double(newValue) {
                viewModel.accounts[i].initialBalance = newBalance
            }
        }
        // Recalculate account balances based on the new presets.
        viewModel.recalcAccounts()
    }
}

struct EditBalancesView_Previews: PreviewProvider {
    static var previews: some View {
        EditBalancesView().environmentObject(FinanceViewModel())
    }
}