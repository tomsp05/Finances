// BalanceWidget/BalanceWidget.swift

import WidgetKit
import SwiftUI

// You may need to create this as a new file `WidgetData.swift` and
// ensure it also has Target Membership for both the app and the widget.
struct WidgetData: Codable {
    let netBalance: Double
    let transactions: [Transaction]
    let themeColorData: Data? // Store theme color as Data
}

struct Provider: AppIntentTimelineProvider {
    let appGroupID = "group.com.TomSpeake.StudentFinanceTracker"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            netBalance: 1234.56,
            transactions: [],
            themeColor: .blue
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let data = readData()
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            netBalance: data?.netBalance ?? 0.0,
            transactions: data?.transactions ?? [],
            themeColor: extractThemeColor(from: data) ?? .blue
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let data = readData()
        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            netBalance: data?.netBalance ?? 0.0,
            transactions: data?.transactions ?? [],
            themeColor: extractThemeColor(from: data) ?? .blue
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
        
        // Try to decode the color from Data
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
}

struct BalanceWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£"
        formatter.locale = Locale(identifier: "en_GB")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "£0.00"
    }
    
    // Get recent transactions for medium widget
    private var recentTransactions: [Transaction] {
        Array(entry.transactions.sorted { $0.date > $1.date }.prefix(3))
    }
    
    // Dynamic font sizes based on widget family
    private var titleFontSize: Font {
        switch family {
        case .systemSmall:
            return .caption
        case .systemMedium:
            return .caption
        default:
            return .caption
        }
    }
    
    private var balanceFontSize: Font {
        switch family {
        case .systemSmall:
            return .title2
        case .systemMedium:
            return .title
        default:
            return .largeTitle
        }
    }
    
    private var transactionFontSize: Font {
        switch family {
        case .systemMedium:
            return .caption2
        default:
            return .caption2
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            switch family {
            case .systemSmall:
                smallWidgetView
            case .systemMedium:
                mediumWidgetView
            default:
                smallWidgetView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
    }
    
    // Small widget view
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Net Balance")
                    .font(titleFontSize)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // App icon or indicator
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
                    .foregroundColor(.white)
            }
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(
            // Subtle pattern overlay
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        center: .topTrailing,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
        )
    }
    
    // Medium widget view
    private var mediumWidgetView: some View {
        HStack(spacing: 24) {
            // Left side - Balance
            VStack(alignment: .leading, spacing: 8) {
                Text("Net Balance")
                    .font(titleFontSize)
                    .fontWeight(.medium)
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
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 8)
            
            // Right side - Recent Transactions
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Recent")
                        .font(titleFontSize)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if recentTransactions.isEmpty {
                    Spacer()
                    Text("No transactions")
                        .font(transactionFontSize)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(recentTransactions.prefix(3), id: \.id) { transaction in
                            HStack(spacing: 6) {
                                // Transaction type icon
                                Image(systemName: transactionIcon(for: transaction))
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 12)
                                
                                // Transaction description
                                Text(transaction.description)
                                    .font(transactionFontSize)
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                Spacer()
                                
                                // Amount
                                Text(formatCurrency(transaction.amount))
                                    .font(transactionFontSize)
                                    .fontWeight(.medium)
                                    .foregroundColor(transactionAmountColor(for: transaction))
                                    .lineLimit(1)
                            }
                        }
                        
                        if recentTransactions.count < 3 {
                            Spacer()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(
            // Subtle pattern overlay
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        center: .topTrailing,
                        startRadius: 30,
                        endRadius: 120
                    )
                )
        )
    }
    
    // Helper functions
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
    
    private func transactionIcon(for transaction: Transaction) -> String {
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
        case .income:
            return .white.opacity(0.9)
        case .expense:
            return .white.opacity(0.7)
        case .transfer:
            return .white.opacity(0.8)
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

