import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    private var isAccessibilitySize: Bool { dynamicTypeSize.isAccessibility }

    @State private var previousBalance: Double = 0.0
    @State private var isAnimating: Bool = false
    @State private var animationScale: CGFloat = 1.0
    @State private var showChangeAmount: Bool = false
    @State private var viewDidAppear = false

    var netCurrentBalance: Double {
        let currentBalance = viewModel.accounts.first(where: { $0.type == .current })?.balance ?? 0.0
        let creditCards = viewModel.accounts.filter { $0.type == .credit }
        let creditTotal = creditCards.reduce(0.0) { $0 + $1.balance }
        return currentBalance - creditTotal
    }

    private var recentGroupedTransactions: [(date: Date, transactions: [Transaction])] {
        let recentTransactions = viewModel.transactions.sorted { $0.date > $1.date }.prefix(10)
        let groups = Dictionary(grouping: recentTransactions) { transaction in
            Calendar.current.startOfDay(for: transaction.date)
        }
        let sortedGroups = groups.sorted { $0.key > $1.key }
        return sortedGroups.map { (date: $0.key, transactions: $0.value.sorted { $0.date > $1.date }) }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var balanceFontSize: CGFloat {
        if horizontalSizeClass == .compact {
            return verticalSizeClass == .compact ? 32 : 42
        } else {
            return 50
        }
    }

    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .compact ? 16 : 24
    }
    
    private var budgetsIconName: String {
        switch viewModel.userPreferences.currency {
        case .gbp:
            return "sterlingsign.circle.fill"
        case .usd:
            return "dollarsign.circle.fill"
        case .eur:
            return "eurosign.circle.fill"
        }
    }
    
    private var showNavIcon: Bool {
        !(horizontalSizeClass == .compact && verticalSizeClass == .compact) && !isAccessibilitySize
    }

    func refreshBalanceDisplay() {
        viewModel.recalcAccounts()
        
        let currentBalance = netCurrentBalance
        
        if previousBalance != currentBalance {
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
                previousBalance = currentBalance
            }
        } else {
            previousBalance = currentBalance
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: adaptiveSpacing(24)) {
                    NavigationLink(destination: AccountsListView()) {
                        VStack(spacing: 8) {
                            Text("Net Balance")
                                .font(.headline)
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            
                            ZStack(alignment: .center) {
                                balanceDisplay
                                balanceChangeIndicator
                            }
                            
                            HStack(spacing: 4) {
                                Text("View Accounts")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 4)
                            
                        }
                        .padding(.vertical, adaptiveSpacing(24))
                        .padding(.horizontal, adaptiveSpacing(20))
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
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top)
                    }
                    
                    adaptiveNavCardsView()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.transactions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No transactions yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                                
                                Text("Tap 'Add Transaction' to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(recentGroupedTransactions, id: \.date) { group in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formattedDate(group.date))
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 4)
                                        .minimumScaleFactor(0.7)
                                        .lineLimit(1)
                                    
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
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .dynamicTypeSize(.xSmall ... .accessibility3)
                }
                .padding(.bottom, 20)
                .dynamicTypeSize(.xSmall ... .accessibility3)
            }
            .navigationTitle("Doughs")
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
            .onAppear {
                previousBalance = netCurrentBalance
                viewDidAppear = true
                
                DispatchQueue.main.async {
                    self.refreshBalanceDisplay()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if viewDidAppear {
                    DispatchQueue.main.async {
                        self.refreshBalanceDisplay()
                    }
                }
            }
            .onChange(of: viewModel.balanceDidChange) {
                let newBalanceValue = netCurrentBalance
                
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
                    previousBalance = newBalanceValue
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .dynamicTypeSize(.xSmall ... .accessibility3)
    }

    // MARK: - Refactored Helper Views
    
    @ViewBuilder
    private var balanceDisplay: some View {
        CountingValueView(
            value: netCurrentBalance,
            fromValue: previousBalance,
            isAnimating: isAnimating,
            fontSize: balanceFontSize,
            currency: viewModel.userPreferences.currency,
            positiveColor: .white,
            negativeColor: .white
        )
        .scaleEffect(animationScale)
        .minimumScaleFactor(0.7)
        .lineLimit(1)
        .modifier(ShimmerEffect(
            isAnimating: isAnimating,
            isDarkMode: colorScheme == .dark
        ))
    }
    
    @ViewBuilder
    private var balanceChangeIndicator: some View {
        if showChangeAmount && previousBalance != netCurrentBalance {
            let difference = netCurrentBalance - previousBalance
            VStack {
                HStack(spacing: 4) {
                    Image(systemName: difference >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(difference >= 0 ? .green : .red)
                        .font(.system(size: 16))
                    
                    Text(viewModel.formatCurrency(abs(difference)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(difference >= 0 ? .green : .red)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
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
    
    private func adaptiveSpacing(_ defaultSpacing: CGFloat) -> CGFloat {
        horizontalSizeClass == .compact ? defaultSpacing : defaultSpacing * 1.3
    }
    
    @ViewBuilder
    private func adaptiveNavCardsView() -> some View {
        if horizontalSizeClass == .compact && verticalSizeClass == .regular {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    navCardBudgets
                    navCardAnalytics
                }
                
                HStack(spacing: 16) {
                    navCardAddTransaction
                    navCardSettings
                }
            }
            .padding(.horizontal, horizontalPadding)
            .dynamicTypeSize(.xSmall ... .accessibility3)
        } else if horizontalSizeClass == .compact && verticalSizeClass == .compact {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    navCardBudgets
                        .frame(width: 180)
                    navCardAnalytics
                        .frame(width: 180)
                    navCardAddTransaction
                        .frame(width: 180)
                    navCardSettings
                        .frame(width: 180)
                }
                .padding(.horizontal, horizontalPadding)
            }
            .dynamicTypeSize(.xSmall ... .accessibility3)
        } else {
            let columns = [
                GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
            ]
            
            LazyVGrid(columns: columns, spacing: 16) {
                navCardBudgets
                navCardAnalytics
                navCardAddTransaction
                navCardSettings
            }
            .padding(.horizontal, horizontalPadding)
            .dynamicTypeSize(.xSmall ... .accessibility3)
        }
    }
    
    // MARK: - Navigation Cards Updated without showText flag
    private var navCardBudgets: some View {
        NavigationLink(destination: BudgetListView()) {
            NavCardView(
                title: "Budgets",
                subtitle: isAccessibilitySize ? "" : "Keep Track",
                iconName: showNavIcon ? budgetsIconName : nil
            )
        }
        .dynamicTypeSize(.xSmall ... .large)
    }
    
    private var navCardAnalytics: some View {
        NavigationLink(destination: TransactionAnalyticsView()) {
            NavCardView(
                title: "Analytics",
                subtitle: isAccessibilitySize ? "" : "Insights",
                iconName: showNavIcon ? "chart.pie.fill" : nil
            )
        }
        .dynamicTypeSize(.xSmall ... .large)
    }
    
    private var navCardAddTransaction: some View {
        NavigationLink(destination: AddTransactionView()) {
            NavCardView(
                title: "Add",
                subtitle: isAccessibilitySize ? "" : "Transaction",
                iconName: showNavIcon ? "plus.circle.fill" : nil
            )
        }
        .dynamicTypeSize(.xSmall ... .large)
    }
    
    private var navCardSettings: some View {
        NavigationLink(destination: SettingsView()) {
            NavCardView(
                title: "Settings",
                subtitle: isAccessibilitySize ? "" : "Customise",
                iconName: showNavIcon ? "gear" : nil
            )
        }
        .dynamicTypeSize(.xSmall ... .large)
    }
}

extension DynamicTypeSize {
    var isAccessibility: Bool {
        self >= .accessibility1
    }
}

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
                        .mask(content)
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (geo.size.width * 2) * phase)
                    }
                    .mask(content)
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

