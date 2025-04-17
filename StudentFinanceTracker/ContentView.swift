import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    /// State to track previous balance for animation
    @State private var previousBalance: Double = 0.0
    /// Animation trigger state
    @State private var isAnimating: Bool = false
    /// Animation scale value
    @State private var animationScale: CGFloat = 1.0
    /// Show change amount
    @State private var showChangeAmount: Bool = false
    /// Track when the view appears or becomes active
    @State private var viewDidAppear = false
    
    /// Computes the net current balance:
    /// (Current account balance) minus (sum of credit card balances)
    var netCurrentBalance: Double {
        let currentBalance = viewModel.accounts.first(where: { $0.type == .current })?.balance ?? 0.0
        let creditCards = viewModel.accounts.filter { $0.type == .credit }
        let creditTotal = creditCards.reduce(0.0) { $0 + $1.balance }
        return currentBalance - creditTotal
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
    
    // Compute the recent transactions (limit to the most recent 5) and group them by day (start of day)
    private var recentGroupedTransactions: [(date: Date, transactions: [Transaction])] {
        let recentTransactions = viewModel.transactions.sorted { $0.date > $1.date }.prefix(5)
        let groups = Dictionary(grouping: recentTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        let sortedGroups = groups.sorted { $0.key > $1.key }
        return sortedGroups.map { (date: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
    }
    
    // Helper to format a date header
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // e.g., "Apr 14, 2025"
        return formatter.string(from: date)
    }
    
    // Enhanced refreshBalanceDisplay method
    func refreshBalanceDisplay() {
        // Force view model to recalculate all accounts first
        viewModel.recalcAccounts()
        
        // Get the latest balance value after recalculation
        let currentBalance = netCurrentBalance
        
        // Compare with previous balance
        if previousBalance != currentBalance {
            // Trigger animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                animationScale = 1.1
                isAnimating = true
                showChangeAmount = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationScale = 1.0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    isAnimating = false
                    showChangeAmount = false
                }
                // Update previous balance for next comparison
                previousBalance = currentBalance
            }
        } else {
            // Even if the balance hasn't changed, update the display
            previousBalance = currentBalance
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with current balance
                    NavigationLink(destination: AccountsListView()) {
                        VStack(spacing: 8) {
                            Text("Current Balance")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            // Balance with animation wrapper
                            ZStack(alignment: .center) {
                                // Main balance with counting animation
                                CountingValueView(
                                    value: netCurrentBalance,
                                    fromValue: previousBalance,
                                    isAnimating: isAnimating,
                                    fontSize: 42,
                                    positiveColor: colorScheme == .dark ? .green : .green.opacity(0.8),
                                    negativeColor: colorScheme == .dark ? .red : .red.opacity(0.8)
                                )
                                .scaleEffect(animationScale)
                                .modifier(ShimmerEffect(
                                    isAnimating: isAnimating,
                                    isDarkMode: colorScheme == .dark
                                ))
                                
                                // Change amount badge
                                if showChangeAmount && previousBalance != netCurrentBalance {
                                    let difference = netCurrentBalance - previousBalance
                                    VStack {
                                        HStack(spacing: 4) {
                                            Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                                .foregroundColor(difference >= 0 ? .green : .red)
                                                .font(.system(size: 16))
                                            
                                            Text(formatCurrency(abs(difference)))
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(difference >= 0 ? .green : .red)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color(UIColor.secondarySystemBackground))
                                                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        )
                                        .offset(y: -50)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            
                            // Visual cue that this is tappable
                            HStack(spacing: 4) {
                                Text("View Accounts")
                                    .font(.caption)
                                    .foregroundColor(viewModel.themeColor)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(viewModel.themeColor)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(15)
                        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Navigation cards in a 2x2 grid using the theme color
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            NavigationLink(destination: PayCreditCardView()) {
                                NavCardView(
                                    title: "Pay",
                                    subtitle: "Credit Card",
                                    iconName: "arrow.right.circle.dotted"
                                )
                            }
                            
                            NavigationLink(destination: TransactionAnalyticsView()) {
                                NavCardView(
                                    title: "Analytics",
                                    subtitle: "View Spending",
                                    iconName: "chart.pie.fill"
                                )
                            }
                        }
                        
                        HStack(spacing: 16) {
                            NavigationLink(destination: AddTransactionView()) {
                                NavCardView(
                                    title: "Add",
                                    subtitle: "Transaction",
                                    iconName: "plus.circle.fill"
                                )
                            }
                            
                            NavigationLink(destination: SettingsView()) {
                                NavCardView(
                                    title: "Settings",
                                    subtitle: "Customise",
                                    iconName: "gear"
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Transactions Section
                    VStack(alignment: .leading, spacing: 12) {
                        
                        if viewModel.transactions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No transactions yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Tap 'Add Transaction' to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(recentGroupedTransactions, id: \.date) { group in
                                VStack(alignment: .leading, spacing: 4) {
                                    // Group header with date and divider
                                    Text(formattedDate(group.date))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 4)
                                    
                                    Divider()
                                    
                                    ForEach(group.transactions) { transaction in
                                        NavigationLink(destination: EditTransactionView(transaction: transaction)) {
                                            TransactionCardView(transaction: transaction)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.vertical, 2)
                                }
                                .padding(.vertical, 2)
                            }
                            
                            NavigationLink(destination: TransactionsListView()) {
                                Text("See All Transactions")
                                    .font(.headline)
                                    .foregroundColor(viewModel.themeColor)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                                    .cornerRadius(15)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Finance")
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                // Store initial balance value when view appears
                previousBalance = netCurrentBalance
                viewDidAppear = true // Mark view as appearing
                
                // Force refresh the balance
                DispatchQueue.main.async {
                    // Force a refresh after a short delay to ensure the view is fully loaded
                    self.refreshBalanceDisplay()
                }
            }
            // Add this onReceive modifier to ensure balance updates when returning from another view
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if viewDidAppear {
                    // Only refresh if the view has previously appeared (to avoid duplicate animations on first load)
                    DispatchQueue.main.async {
                        self.refreshBalanceDisplay()
                    }
                }
            }
            // Watch for balance changes through the ViewModel's trigger property
            .onChange(of: viewModel.balanceDidChange) { oldValue, newValue in
                // Get the updated value after the change
                let newBalanceValue = netCurrentBalance
                
                // Trigger animation when balance changes
                // Start the animations
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationScale = 1.1
                    isAnimating = true
                    showChangeAmount = true
                }
                
                // Scale back to normal after small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        animationScale = 1.0
                    }
                }
                
                // Remove the indicator after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isAnimating = false
                        showChangeAmount = false
                    }
                    // Update previous balance for next comparison
                    previousBalance = newBalanceValue
                }
            }
        }
    }
}

// Custom shimmer effect modifier for balance animation
struct ShimmerEffect: ViewModifier {
    var isAnimating: Bool
    var isDarkMode: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        if isAnimating {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.clear, location: 0),
                                .init(color: isDarkMode ? Color.white.opacity(0.3) : Color.white.opacity(0.5), location: 0.3),
                                .init(color: isDarkMode ? Color.white.opacity(0.3) : Color.white.opacity(0.5), location: 0.7),
                                .init(color: Color.clear, location: 1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .mask(content) // Apply the content as mask
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                    }
                    .mask(content) // Apply content as mask again
                )
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.0).repeatCount(2)) {
                        self.phase = 1.0
                    }
                }
        } else {
            content
        }
    }
}
