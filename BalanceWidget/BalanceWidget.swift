
import WidgetKit
import SwiftUI

struct WidgetData: Codable {
    let netBalance: Double
    let transactions: [Transaction]
    let themeColorData: Data?
    let categories: [Category]
}

struct Provider: AppIntentTimelineProvider {
    let appGroupID = "group.com.TomSpeake.StudentFinanceTracker"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            netBalance: 1234.56,
            transactions: [],
            themeColor: .blue,
            categories: []
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let data = readData()
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            netBalance: data?.netBalance ?? 0.0,
            transactions: data?.transactions ?? [],
            themeColor: extractThemeColor(from: data) ?? .blue,
            categories: data?.categories ?? []
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let data = readData()
        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            netBalance: data?.netBalance ?? 0.0,
            transactions: data?.transactions ?? [],
            themeColor: extractThemeColor(from: data) ?? .blue,
            categories: data?.categories ?? []
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func readData() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "widgetData") else {
            return nil
        }
        let decoder = JSONDecoder()
        return try? decoder.decode(WidgetData.self, from: data)
    }
    
    private func extractThemeColor(from data: WidgetData?) -> Color? {
        guard let data = data,
              let colorData = data.themeColorData else {
            return nil
        }
        
        if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
            return Color(uiColor)
        }
        return nil
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let netBalance: Double
    let transactions: [Transaction]
    let themeColor: Color
    let categories: [Category]
}

struct BalanceWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            case .systemLarge:
                largeWidgetView
            default:
                smallWidgetView
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: [entry.themeColor.opacity(0.7), entry.themeColor]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Subviews
    
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Net Balance")
                    .font(titleFontSize)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "sterlingsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCurrency(entry.netBalance))
                    .font(balanceFontSize)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                
                Text("Updated \(formattedTime)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(10)
    }
    
    private var mediumWidgetView: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Net Balance")
                    .font(titleFontSize)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatCurrency(entry.netBalance))
                        .font(balanceFontSize)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                    
                    Text("Updated \(formattedTime)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 6) {
                
                if recentTransactions.prefix(4).isEmpty {
                    Spacer()
                    Text("No transactions")
                        .font(transactionFontSize)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recentTransactions.prefix(4)) { transaction in
                            HStack(spacing: 6) {
                                Image(systemName: transactionIcon(for: transaction))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 12)
                                
//                                Text(transaction.description)
//                                    .font(transactionFontSize)
//                                    .foregroundColor(.white.opacity(0.9))
//                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(formatCurrency(transaction.amount))
                                    .font(transactionFontSize)
                                    .fontWeight(.medium)
                                    .foregroundColor(transactionAmountColor(for: transaction))
                                    .lineLimit(1)
                            }
                        }
                        if recentTransactions.count < 4 {
                           Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
    }

    private var largeWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Net Balance")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(formatCurrency(entry.netBalance))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Image(systemName: "sterlingsign.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("Updated \(formattedTime)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxHeight: 60)

            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(recentTransactions.prefix(5)) { transaction in
                            HStack(spacing: 6) {
                                Image(systemName: transactionIcon(for: transaction))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 14)
                                
//                                Text(transaction.description)
//                                    .font(.caption)
//                                    .foregroundColor(.white.opacity(0.9))
//                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(formatCurrency(transaction.amount))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(transactionAmountColor(for: transaction))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading) {
                    Text("Top Spending")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)

                    if categorySpending.isEmpty {
                         Text("No spending yet.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(categorySpending.prefix(5), id: \.0.id) { (category, total) in
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(category.name)
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(formatCurrency(total))
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                    }
                                    GeometryReader { geo in
                                        let totalSpending = categorySpending.first?.1 ?? 1
                                        let barWidth = geo.size.width * (total / totalSpending)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(.white.opacity(0.2))
                                            .frame(height: 5)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .fill(.white)
                                                    .frame(width: barWidth),
                                                alignment: .leading
                                            )
                                    }
                                    .frame(height: 5)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(10)
    }
    
    // MARK: - Helpers & Formatting
    
    private var recentTransactions: [Transaction] {
        entry.transactions.sorted { $0.date > $1.date }
    }
    
    private var categorySpending: [(Category, Double)] {
        let expenseTransactions = recentTransactions.filter { $0.type == .expense }
        
        let spendingByCategoryId = Dictionary(grouping: expenseTransactions, by: { $0.categoryId })
            .mapValues { transactions in
                transactions.reduce(0) { $0 + $1.amount }
            }
        
        let categorySpendingData = spendingByCategoryId.compactMap { (categoryId, total) -> (Category, Double)? in
            if let category = entry.categories.first(where: { $0.id == categoryId }) {
                return (category, total)
            }
            return nil
        }
        
        return categorySpendingData.sorted { $0.1 > $1.1 }
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
    
    private var titleFontSize: Font { .caption }
    private var balanceFontSize: Font { family == .systemSmall ? .title2 : .title }
    private var transactionFontSize: Font { .caption2 }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    private func transactionIcon(for transaction: Transaction) -> String {
        if let category = entry.categories.first(where: { $0.id == transaction.categoryId }) {
            return category.iconName
        }
        
        switch transaction.type {
        case .income:
            return "arrow.down.circle.fill"
        case .expense:
            return "arrow.up.circle.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        }
    }
    
    private func transactionAmountColor(for transaction: Transaction) -> Color {
        switch transaction.type {
        case .income: .white.opacity(0.9)
        case .expense: .white.opacity(0.7)
        case .transfer: .white.opacity(0.8)
        }
    }
}

struct BalanceWidget: Widget {
    let kind: String = "BalanceWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BalanceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Net Balance")
        .description("View your net balance and recent transactions at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
