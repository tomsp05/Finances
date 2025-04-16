import SwiftUI

struct TransactionsListView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var showFutureTransactions = false
    @State private var showRecurringOnly = false
    
    // Group transactions by day and sort by date (most recent first)
    private var groupedTransactions: [(date: Date, transactions: [Transaction])] {
        // Filter transactions based on toggles
        let filteredTransactions: [Transaction]
        
        if showFutureTransactions && !showRecurringOnly {
            // Show all future transactions
            let currentDate = Calendar.current.startOfDay(for: Date())
            filteredTransactions = viewModel.transactions.filter {
                Calendar.current.startOfDay(for: $0.date) >= currentDate
            }
        } else if !showFutureTransactions && showRecurringOnly {
            // Show only recurring transactions
            filteredTransactions = viewModel.transactions.filter { $0.isRecurring }
        } else if showFutureTransactions && showRecurringOnly {
            // Show future recurring transactions
            let currentDate = Calendar.current.startOfDay(for: Date())
            filteredTransactions = viewModel.transactions.filter {
                $0.isRecurring && Calendar.current.startOfDay(for: $0.date) >= currentDate
            }
        } else {
            // Show past and current transactions (default)
            let currentDate = Calendar.current.startOfDay(for: Date())
            filteredTransactions = viewModel.transactions.filter {
                Calendar.current.startOfDay(for: $0.date) <= currentDate
            }
        }
        
        // Group by the start of day for each transaction date.
        let groups = Dictionary(grouping: filteredTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        // Sort the groups by key (date) descending.
        let sortedGroups = groups.sorted { $0.key > $1.key }
        // Sort transactions within each group by date descending.
        return sortedGroups.map { (date: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
    }
    
    var body: some View {
        VStack {
            // Filter options
            HStack {
                Toggle("Future", isOn: $showFutureTransactions)
                    .toggleStyle(SwitchToggleStyle(tint: viewModel.themeColor))
                    .padding(.horizontal)
                
                Toggle("Recurring", isOn: $showRecurringOnly)
                    .toggleStyle(SwitchToggleStyle(tint: viewModel.themeColor))
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            // Transactions list
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Iterate over grouped transactions
                    ForEach(groupedTransactions, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 4) {
                            // Date header for the group
                            Text(formattedDate(group.date))
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                            
                            Divider()
                            
                            // List out each transaction for this day.
                            ForEach(group.transactions) { transaction in
                                NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                                    TransactionCardView(transaction: transaction)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }.padding(.vertical, 2)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Transactions")
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // Helper to format the grouped date header.
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Apr 14, 2025"
        return formatter.string(from: date)
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TransactionsListView().environmentObject(FinanceViewModel())
        }
    }
}
