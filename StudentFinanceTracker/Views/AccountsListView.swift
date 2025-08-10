import SwiftUI

struct AccountsListView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isAppearing: Bool = false
    @State private var selectedFinancialInsight: Int = 0
    @State private var showingHealthScoreDetails: Bool = false
    
    private var netCurrentBalance: Double {
        let currentBalance = viewModel.accounts.first(where: { $0.type == .current })?.balance ?? 0.0
        let creditCards = viewModel.accounts.filter { $0.type == .credit }
        let creditTotal = creditCards.reduce(0.0) { $0 + $1.balance }
        return currentBalance - creditTotal
    }
    
    private var netWorth: Double {
        let savingsTotal = viewModel.accounts.filter { $0.type == .savings }
            .reduce(0.0) { $0 + $1.balance }
        let currentTotal = viewModel.accounts.filter { $0.type == .current }
            .reduce(0.0) { $0 + $1.balance }
        let creditTotal = viewModel.accounts.filter { $0.type == .credit }
            .reduce(0.0) { $0 + $1.balance }
        
        return savingsTotal + currentTotal - creditTotal
    }
    
    private var financialHealth: (score: Double, status: String, color: Color) {
        let savingsTotal = viewModel.accounts.filter { $0.type == .savings }.reduce(0.0) { $0 + $1.balance }
        let creditTotal = viewModel.accounts.filter { $0.type == .credit }.reduce(0.0) { $0 + $1.balance }
        let currentTotal = viewModel.accounts.filter { $0.type == .current }.reduce(0.0) { $0 + $1.balance }
        
        var score: Double = 50 // Base score
        
        // Positive factors
        if savingsTotal > currentTotal * 0.3 { score += 20 } // Good savings ratio
        if creditTotal < currentTotal * 0.2 { score += 15 } // Low credit utilization
        if netWorth > 0 { score += 10 } // Positive net worth
        
        // Negative factors
        if creditTotal > currentTotal * 0.5 { score -= 25 } // High credit debt
        if savingsTotal < currentTotal * 0.1 { score -= 15 } // Low savings
        if netWorth < 0 { score -= 20 } // Negative net worth
        
        score = max(0, min(100, score))
        
        let status: String
        let color: Color
        
        switch score {
        case 80...100:
            status = "Excellent"
            color = .green
        case 60...79:
            status = "Good"
            color = .blue
        case 40...59:
            status = "Fair"
            color = .orange
        default:
            status = "Needs Attention"
            color = .red
        }
        
        return (score, status, color)
    }
    
    private var savingsAccounts: [Account] {
        viewModel.accounts.filter { $0.type == .savings }
    }
    
    private var currentAccounts: [Account] {
        viewModel.accounts.filter { $0.type == .current }
    }
    
    private var creditAccounts: [Account] {
        viewModel.accounts.filter { $0.type == .credit }
    }
    
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
                // Financial Health Header
                financialHealthCard()
                
                // Net Worth and Balance Cards
                HStack(spacing: 12) {
                    netWorthCard()
                    netBalanceCard()
                }
                .padding(.horizontal)
                .offset(y: isAppearing ? 0 : 25)
                .opacity(isAppearing ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isAppearing)
                
                // Financial Insights Carousel
                financialInsightsCarousel()
                
                // Account Distribution
                VStack(alignment: .leading, spacing: 10) {
                    Text("Account Overview")
                        .font(.headline)
                        .padding(.horizontal)
                        .offset(y: isAppearing ? 0 : 15)
                        .opacity(isAppearing ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: isAppearing)
                    
                    if !viewModel.accounts.isEmpty {
                        enhancedAccountDistributionView()
                            .offset(y: isAppearing ? 0 : 25)
                            .opacity(isAppearing ? 1.0 : 0.0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5), value: isAppearing)
                    }
                }
                .padding(.top, 5)
                
                // Account Sections with enhanced design
                if !currentAccounts.isEmpty {
                    accountSection(title: "Current Accounts", accounts: currentAccounts, iconName: "banknote.fill", delay: 0.6)
                }
                
                if !savingsAccounts.isEmpty {
                    accountSection(title: "Savings Accounts", accounts: savingsAccounts, iconName: "building.columns.fill", delay: 0.7)
                }
                
                if !creditAccounts.isEmpty {
                    accountSection(title: "Credit Cards", accounts: creditAccounts, iconName: "creditcard.fill", delay: 0.8)
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
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9), value: isAppearing)
            }
        }
        .navigationTitle("Financial Overview")
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
    
    // MARK: - New Components
    
    private func financialHealthCard() -> some View {
        let health = financialHealth
        
        return Button(action: {
            showingHealthScoreDetails = true
        }) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("Financial Health")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text(health.status)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 6)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: health.score / 100)
                            .stroke(Color.white, lineWidth: 6)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.5).delay(0.5), value: isAppearing)
                        
                        Text("\(Int(health.score))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Quick tips based on health score
                if health.score < 60 {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                            .padding(.top, 1)
                        
                        Text(getFinancialTip())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [health.color, health.color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: health.color.opacity(0.5), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .offset(y: isAppearing ? 0 : 30)
        .opacity(isAppearing ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isAppearing)
        .sheet(isPresented: $showingHealthScoreDetails) {
            HealthScoreDetailsView(
                score: health.score,
                status: health.status,
                color: health.color,
                accounts: viewModel.accounts
            )
        }
    }
    
    private func netWorthCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: netWorth >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 22, weight: .bold))
                    .padding(.trailing, 2)

                Text("Net Worth")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()
            }

            Text(formatCurrency(netWorth))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.top, 4)
                .accessibilityLabel("Net worth: " + formatCurrency(netWorth))

            Text("Total assets minus debts")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    viewModel.themeColor.opacity(0.95),
                    viewModel.themeColor.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: viewModel.themeColor.opacity(0.45), radius: 10, x: 0, y: 5)
    }
    
    private func netBalanceCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "wallet.pass.fill")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 22, weight: .bold))
                    .padding(.trailing, 2)

                Text("Available")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()
            }

            Text(formatCurrency(netCurrentBalance))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.10), radius: 2, x: 0, y: 1)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .padding(.top, 4)
                .accessibilityLabel("Available to spend: " + formatCurrency(netCurrentBalance))

            Text("Ready to spend now")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.75))
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        .shadow(color: viewModel.themeColor.opacity(0.45), radius: 10, x: 0, y: 5)
    }
    
    private func financialInsightsCarousel() -> some View {
        let insights = getFinancialInsights()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Financial Insights")
                    .font(.headline)
                
                Spacer()
                
                Text("\(selectedFinancialInsight + 1) of \(insights.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            TabView(selection: $selectedFinancialInsight) {
                ForEach(Array(insights.enumerated()), id: \.0) { index, insight in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(insight.color.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: insight.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(insight.color)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(insight.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                
                                Text(insight.description)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(UIColor.secondarySystemBackground))
                            .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(insight.color.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 110)
        }
        .offset(y: isAppearing ? 0 : 20)
        .opacity(isAppearing ? 1.0 : 0.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: isAppearing)
    }
    
    private func enhancedAccountDistributionView() -> some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 20) {
                // Enhanced pie chart with animations
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 140, height: 140)
                    
                    if netWorth != 0 {
                        let savingsTotal = viewModel.accounts.filter { $0.type == .savings }.reduce(0.0) { $0 + $1.balance }
                        let creditTotal = viewModel.accounts.filter { $0.type == .credit }.reduce(0.0) { $0 + $1.balance }
                        let totalAbsolute = abs(savingsTotal) + abs(netCurrentBalance) + abs(creditTotal)
                        
                        let savingsPortion = abs(savingsTotal) / totalAbsolute
                        let currentPortion = abs(netCurrentBalance) / totalAbsolute
                        let creditPortion = abs(creditTotal) / totalAbsolute
                        
                        // Animated segments
                        Circle()
                            .trim(from: 0, to: isAppearing ? savingsPortion : 0)
                            .stroke(getAccountColor(.savings), lineWidth: 20)
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0).delay(0.5), value: isAppearing)
                        
                        Circle()
                            .trim(from: 0, to: isAppearing ? currentPortion : 0)
                            .stroke(getAccountColor(.current), lineWidth: 20)
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90 + 360 * savingsPortion))
                            .animation(.easeInOut(duration: 1.0).delay(0.7), value: isAppearing)
                        
                        Circle()
                            .trim(from: 0, to: isAppearing ? creditPortion : 0)
                            .stroke(getAccountColor(.credit), lineWidth: 20)
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90 + 360 * (savingsPortion + currentPortion)))
                            .animation(.easeInOut(duration: 1.0).delay(0.9), value: isAppearing)
                    }
                    
                    // Center total
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(formatCurrency(abs(netWorth)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                
                // Enhanced legend with percentages
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        let accounts = viewModel.accounts.filter { $0.type == type }
                        let total = accounts.reduce(0.0) { $0 + $1.balance }
                        let percentage = abs(total) / (abs(netWorth) > 0 ? abs(netWorth) : 1) * 100
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(getAccountColor(type))
                                .frame(width: 14, height: 14)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(accountTypeName(type))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(percentage))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(formatCurrency(total))
                                    .font(.caption)
                                    .foregroundColor(getBalanceColorForType(type, balance: total))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    
    private func getFinancialInsights() -> [(title: String, description: String, icon: String, color: Color)] {
        var insights: [(title: String, description: String, icon: String, color: Color)] = []
        
        let savingsTotal = savingsAccounts.reduce(0.0) { $0 + $1.balance }
        let creditTotal = creditAccounts.reduce(0.0) { $0 + $1.balance }
        let currentTotal = currentAccounts.reduce(0.0) { $0 + $1.balance }
        let totalAssets = savingsTotal + currentTotal
        
        // Emergency fund insights
        let emergencyFundTarget = currentTotal * 0.25
        if savingsTotal >= emergencyFundTarget && emergencyFundTarget > 0 {
            insights.append((
                title: "Emergency Fund Secured ✨",
                description: "You have enough savings to cover unexpected expenses. Consider investing excess funds for growth.",
                icon: "checkmark.shield.fill",
                color: .green
            ))
        } else if savingsTotal > 0 && savingsTotal < emergencyFundTarget {
            insights.append((
                title: "Building Emergency Fund 🏗️",
                description: "You're on track! Aim for \(formatCurrency(emergencyFundTarget)) to fully secure your emergency fund.",
                icon: "arrow.up.circle.fill",
                color: .blue
            ))
        } else if savingsTotal <= 0 {
            insights.append((
                title: "Start Your Emergency Fund 🚨",
                description: "Begin by saving £500-£1000 for unexpected expenses. Even small amounts add up over time!",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            ))
        }
        
        // Credit utilization insights
        if creditTotal > 0 {
            let utilizationRatio = creditTotal / max(totalAssets, 1)
            if utilizationRatio > 0.5 {
                insights.append((
                    title: "High Credit Usage 📊",
                    description: "Credit debt represents \(Int(utilizationRatio * 100))% of your assets. Focus on paying down high-interest debt first.",
                    icon: "creditcard.trianglebadge.exclamationmark",
                    color: .red
                ))
            } else if utilizationRatio > 0.3 {
                insights.append((
                    title: "Moderate Credit Usage ⚖️",
                    description: "Your credit usage is manageable at \(Int(utilizationRatio * 100))%. Consider reducing it below 30% for better financial health.",
                    icon: "scale.3d",
                    color: .orange
                ))
            } else {
                insights.append((
                    title: "Healthy Credit Usage 💚",
                    description: "Excellent! Your credit debt is only \(Int(utilizationRatio * 100))% of your assets. You're managing credit responsibly.",
                    icon: "checkmark.seal.fill",
                    color: .green
                ))
            }
        } else if !creditAccounts.isEmpty {
            insights.append((
                title: "Zero Credit Debt 🎉",
                description: "Outstanding! You have credit accounts but no outstanding debt. This is excellent for your credit score.",
                icon: "star.circle.fill",
                color: .green
            ))
        }
        
        // Savings rate insights
        if totalAssets > 0 {
            let savingsRate = savingsTotal / totalAssets
            if savingsRate > 0.6 {
                insights.append((
                    title: "High Savings Rate 📈",
                    description: "\(Int(savingsRate * 100))% of your money is in savings. Consider investing some for potentially higher returns.",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                ))
            } else if savingsRate < 0.2 && savingsTotal > 0 {
                insights.append((
                    title: "Boost Your Savings 💪",
                    description: "Only \(Int(savingsRate * 100))% is in savings. Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings.",
                    icon: "arrow.up.right.circle.fill",
                    color: .orange
                ))
            }
        }
        
        // Net worth insights
        if netWorth > 0 && savingsTotal > creditTotal {
            let monthsOfExpensesCovered = savingsTotal / max(abs(netCurrentBalance), 1000) // Assuming current balance reflects monthly expenses
            if monthsOfExpensesCovered >= 6 {
                insights.append((
                    title: "Financial Independence Progress 🎯",
                    description: "You have \(Int(monthsOfExpensesCovered)) months of expenses saved. You're on a great path to financial freedom!",
                    icon: "target",
                    color: .purple
                ))
            } else if monthsOfExpensesCovered >= 3 {
                insights.append((
                    title: "Good Financial Buffer 🛡️",
                    description: "You have \(Int(monthsOfExpensesCovered)) months of expenses covered. Aim for 6 months for complete security.",
                    icon: "shield.checkered",
                    color: .blue
                ))
            }
        }
        
        // Account diversification insights
        let accountTypes = Set(viewModel.accounts.map { $0.type })
        if accountTypes.count == 3 {
            insights.append((
                title: "Well-Balanced Portfolio 🎨",
                description: "You have current, savings, and credit accounts. This diversification helps with financial flexibility.",
                icon: "circle.hexagongrid.fill",
                color: .purple
            ))
        } else if accountTypes.count == 1 {
            insights.append((
                title: "Consider Account Diversity 🌈",
                description: "Adding different account types (current, savings, credit) can improve your financial flexibility and opportunities.",
                icon: "plus.circle.fill",
                color: .blue
            ))
        }
        
        // Debt-to-asset ratio insight
        if totalAssets > 0 && creditTotal > 0 {
            let debtRatio = creditTotal / totalAssets
            if debtRatio < 0.1 {
                insights.append((
                    title: "Low Debt Burden 🪶",
                    description: "Your debt is only \(Int(debtRatio * 100))% of your assets. You have excellent debt management!",
                    icon: "feather",
                    color: .green
                ))
            }
        }
        
        // Growth potential insight
        if netWorth > 1000 && savingsTotal > creditTotal * 2 {
            insights.append((
                title: "Investment Opportunity 📊",
                description: "With your strong financial foundation, consider exploring investment options to grow your wealth further.",
                icon: "chart.bar.fill",
                color: .mint
            ))
        }
        
        return insights.isEmpty ? [(
            title: "Welcome to Your Financial Journey 👋",
            description: "Add more accounts to unlock personalized insights and track your progress towards financial goals.",
            icon: "sparkles",
            color: .gray
        )] : Array(insights.prefix(5)) // Limit to 5 insights to keep carousel manageable
    }
    
    private func getFinancialTip() -> String {
        let health = financialHealth
        
        switch health.score {
        case 0...30:
            return "Focus on reducing credit debt and building an emergency fund."
        case 31...50:
            return "Try to save at least 10% of your income and pay down high-interest debt."
        case 51...70:
            return "Consider increasing your savings rate and diversifying your accounts."
        default:
            return "Great job! Focus on long-term wealth building strategies."
        }
    }
    
    private func getBalanceColorForType(_ type: AccountType, balance: Double) -> Color {
        if type == .credit {
            return balance > 0 ? .red : .green
        } else {
            return balance >= 0 ? .green : .red
        }
    }
    
    // MARK: - Existing Functions (Enhanced)
    
    private func accountSection(title: String, accounts: [Account], iconName: String, delay: Double = 0) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced section header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: iconName)
                        .foregroundColor(viewModel.themeColor)
                        .font(.headline)
                    
                    Text(title)
                        .font(.headline)
                }
                
                Spacer()
                
                // Summary stats for section
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(accounts.count) accounts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    let totalBalance = accounts.reduce(0.0) { $0 + $1.balance }
                    Text(formatCurrency(totalBalance))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(getBalanceColorForType(accounts.first?.type ?? .current, balance: totalBalance))
                }
            }
            .padding(.horizontal)
            .offset(y: isAppearing ? 0 : 15)
            .opacity(isAppearing ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay), value: isAppearing)
            
            ForEach(Array(accounts.enumerated()), id: \.1.id) { index, account in
                NavigationLink(destination: AccountPoolsView(account: account)) {
                    enhancedAccountCard(account: account, index: index, delay: delay)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
            }
        }
    }
    
    private func enhancedAccountCard(account: Account, index: Int, delay: Double) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 16) {
                // Enhanced account icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
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
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: getAccountIcon(account.type))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: getAccountColor(account.type).opacity(colorScheme == .dark ? 0.3 : 0.4), radius: 4, x: 0, y: 2)
                .scaleEffect(isAppearing ? 1.0 : 0.8)
                .opacity(isAppearing ? 1.0 : 0.0)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(account.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(accountTypeName(account.type))
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.25 : 0.15))
                            .foregroundColor(viewModel.themeColor)
                            .cornerRadius(6)
                        
                        if !account.pools.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 8))
                                Text("\(account.pools.count)")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(6)
                        }
                    }
                    
                    // Balance change indicator
                    if account.balance != account.initialBalance {
                        let difference = account.balance - account.initialBalance
                        let percentage = abs(difference) / abs(account.initialBalance) * 100
                        
                        HStack(spacing: 4) {
                            Image(systemName: difference >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            
                            Text("\(String(format: "%.1f", percentage))% since start")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((difference >= 0 ? Color.green : Color.red).opacity(0.15))
                        .foregroundColor(difference >= 0 ? .green : .red)
                        .cornerRadius(4)
                    }
                }
                .opacity(isAppearing ? 1.0 : 0.0)
                .offset(x: isAppearing ? 0 : -15)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(formatCurrency(account.balance))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(getBalanceColor(account))
                    
                    Text("from \(formatCurrency(account.initialBalance))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .scaleEffect(isAppearing ? 1.0 : 1.1)
                .opacity(isAppearing ? 1.0 : 0.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(getAccountColor(account.type).opacity(colorScheme == .dark ? 0.4 : 0.2), lineWidth: 1.5)
        )
        .offset(y: isAppearing ? 0 : 25)
        .opacity(isAppearing ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7)
            .delay(delay + 0.1 + Double(index) * 0.05),
            value: isAppearing
        )
    }
    
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

// MARK: - Health Score Details View

struct HealthScoreDetailsView: View {
    let score: Double
    let status: String
    let color: Color
    let accounts: [Account]
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    private var scoreBreakdown: [(category: String, points: Double, maxPoints: Double, description: String, icon: String)] {
        let savingsTotal = accounts.filter { $0.type == .savings }.reduce(0.0) { $0 + $1.balance }
        let creditTotal = accounts.filter { $0.type == .credit }.reduce(0.0) { $0 + $1.balance }
        let currentTotal = accounts.filter { $0.type == .current }.reduce(0.0) { $0 + $1.balance }
        let netWorth = savingsTotal + currentTotal - creditTotal
        
        var breakdown: [(category: String, points: Double, maxPoints: Double, description: String, icon: String)] = []
        
        // Savings Ratio (Max 20 points)
        let savingsPoints = savingsTotal > currentTotal * 0.3 ? 20.0 : max(0, (savingsTotal / max(currentTotal * 0.3, 1)) * 20)
        breakdown.append((
            category: "Emergency Fund",
            points: min(20, savingsPoints),
            maxPoints: 20,
            description: savingsTotal > currentTotal * 0.3 ? "You have a strong emergency fund" : "Build your emergency fund to 30% of current balance",
            icon: "shield.checkered"
        ))
        
        // Credit Utilization (Max 25 points)
        let creditUtilizationPoints: Double
        if creditTotal == 0 {
            creditUtilizationPoints = 25
        } else if creditTotal < currentTotal * 0.1 {
            creditUtilizationPoints = 25
        } else if creditTotal < currentTotal * 0.2 {
            creditUtilizationPoints = 15
        } else if creditTotal < currentTotal * 0.5 {
            creditUtilizationPoints = 5
        } else {
            creditUtilizationPoints = 0
        }
        
        breakdown.append((
            category: "Credit Management",
            points: creditUtilizationPoints,
            maxPoints: 25,
            description: creditTotal == 0 ? "Excellent! No outstanding credit debt" : creditTotal < currentTotal * 0.2 ? "Good credit utilization" : "Consider reducing credit debt",
            icon: "creditcard"
        ))
        
        // Net Worth (Max 15 points)
        let netWorthPoints = netWorth > 0 ? 15.0 : 0.0
        breakdown.append((
            category: "Net Worth",
            points: netWorthPoints,
            maxPoints: 15,
            description: netWorth > 0 ? "Your assets exceed your debts" : "Focus on building positive net worth",
            icon: "chart.line.uptrend.xyaxis"
        ))
        
        // Account Diversification (Max 10 points)
        let accountTypes = Set(accounts.map { $0.type }).count
        let diversificationPoints = Double(accountTypes) * 3.33 // Up to 10 points for 3 types
        breakdown.append((
            category: "Diversification",
            points: min(10, diversificationPoints),
            maxPoints: 10,
            description: accountTypes == 3 ? "Well-balanced account portfolio" : "Consider adding different account types",
            icon: "circle.hexagongrid"
        ))
        
        // Financial Stability (Max 15 points)
        let stabilityPoints: Double
        if savingsTotal > creditTotal && netWorth > 0 {
            stabilityPoints = 15
        } else if savingsTotal > 0 && netWorth >= 0 {
            stabilityPoints = 10
        } else if netWorth >= 0 {
            stabilityPoints = 5
        } else {
            stabilityPoints = 0
        }
        
        breakdown.append((
            category: "Financial Stability",
            points: stabilityPoints,
            maxPoints: 15,
            description: stabilityPoints >= 15 ? "Excellent financial stability" : stabilityPoints >= 10 ? "Good foundation" : stabilityPoints >= 5 ? "Building stability" : "Focus on debt reduction",
            icon: "house.fill"
        ))
        
        // Growth Potential (Max 15 points)
        let growthPoints: Double
        if savingsTotal > currentTotal && netWorth > savingsTotal {
            growthPoints = 15
        } else if savingsTotal > currentTotal * 0.5 && netWorth > 0 {
            growthPoints = 10
        } else if savingsTotal > 0 && netWorth >= 0 {
            growthPoints = 5
        } else {
            growthPoints = 0
        }
        
        breakdown.append((
            category: "Growth Potential",
            points: growthPoints,
            maxPoints: 15,
            description: growthPoints >= 15 ? "Ready for investment opportunities" : growthPoints >= 10 ? "Good savings for growth" : growthPoints >= 5 ? "Building foundation for growth" : "Focus on saving first",
            icon: "leaf.fill"
        ))
        
        return breakdown
    }
    
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
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with score
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(color.opacity(0.2), lineWidth: 12)
                                .frame(width: 120, height: 120)
                            
                            Circle()
                                .trim(from: 0, to: score / 100)
                                .stroke(color, lineWidth: 12)
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 4) {
                                Text("\(Int(score))")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(color)
                                
                                Text("out of 100")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text("Financial Health Score")
                                .font(.headline)
                            
                            Text(status)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(color)
                        }
                        
                        Text("Your score is calculated based on six key financial factors. Improve any category below to boost your overall health score.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Score breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Score Breakdown")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        ForEach(Array(scoreBreakdown.enumerated()), id: \.0) { index, item in
                            VStack(spacing: 12) {
                                HStack(alignment: .center, spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(color.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: item.icon)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(color)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(item.category)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(item.points))/\(Int(item.maxPoints))")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(color)
                                        }
                                        
                                        Text(item.description)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    Spacer()
                                }
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(UIColor.systemGray5))
                                            .frame(height: 8)
                                        
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(color)
                                            .frame(width: geometry.size.width * (item.points / item.maxPoints), height: 8)
                                            .animation(.easeInOut(duration: 0.8).delay(Double(index) * 0.1), value: item.points)
                                    }
                                }
                                .frame(height: 8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }
                    }
                    
                    // Tips for improvement
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ways to Improve Your Score")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        let improvementTips = getImprovementTips()
                        ForEach(Array(improvementTips.enumerated()), id: \.0) { index, tip in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(tip.color.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: tip.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(tip.color)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tip.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text(tip.description)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(tip.color.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(tip.color.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Footer note
                    Text("💡 Your score updates automatically as you manage your accounts. Small improvements in each category can significantly boost your overall financial health!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.systemGray6))
                        )
                        .padding(.horizontal)
                        .padding(.bottom)
                }
            }
            .navigationTitle("Health Score Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func getImprovementTips() -> [(title: String, description: String, icon: String, color: Color)] {
        var tips: [(title: String, description: String, icon: String, color: Color)] = []
        
        let breakdown = scoreBreakdown
        
        // Find areas with lowest scores for improvement suggestions
        let sortedCategories = breakdown.sorted { $0.points / $0.maxPoints < $1.points / $1.maxPoints }
        
        for category in sortedCategories.prefix(3) {
            switch category.category {
            case "Emergency Fund":
                if category.points < category.maxPoints {
                    tips.append((
                        title: "Build Emergency Savings",
                        description: "Aim to save 3-6 months of expenses. Start with just £50-£100 per month - consistency matters more than amount.",
                        icon: "shield.lefthalf.fill",
                        color: .blue
                    ))
                }
            case "Credit Management":
                if category.points < category.maxPoints {
                    tips.append((
                        title: "Reduce Credit Debt",
                        description: "Pay more than minimum payments. Focus on highest interest rate cards first, or consider the snowball method for motivation.",
                        icon: "minus.circle.fill",
                        color: .red
                    ))
                }
            case "Net Worth":
                if category.points < category.maxPoints {
                    tips.append((
                        title: "Increase Assets",
                        description: "Focus on growing savings and reducing debt. Even small monthly contributions compound over time.",
                        icon: "plus.circle.fill",
                        color: .green
                    ))
                }
            case "Diversification":
                if category.points < category.maxPoints {
                    tips.append((
                        title: "Diversify Accounts",
                        description: "Consider adding different account types for better financial flexibility - savings for goals, current for daily use.",
                        icon: "square.grid.3x3.fill",
                        color: .purple
                    ))
                }
            case "Financial Stability":
                if category.points < category.maxPoints {
                    tips.append((
                        title: "Create Financial Buffer",
                        description: "Build a cushion by keeping savings higher than debt. This provides security during unexpected events.",
                        icon: "checkmark.shield.fill",
                        color: .mint
                    ))
                }
            case "Growth Potential":
                if category.points < category.maxPoints {
                    tips.append((
                        title: "Plan for Growth",
                        description: "Once you have emergency savings, consider investment accounts or higher-yield savings for wealth building.",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .orange
                    ))
                }
            default:
                break
            }
        }
        
        // Add general tips if score is low
        if score < 60 {
            tips.append((
                title: "Start with Small Steps",
                description: "Financial health improves gradually. Focus on one area at a time - whether it's saving £20 weekly or paying £50 extra on credit cards.",
                icon: "figure.walk",
                color: .gray
            ))
        }
        
        return tips
    }
}

struct AccountsListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AccountsListView().environmentObject(FinanceViewModel())
        }
    }
}
