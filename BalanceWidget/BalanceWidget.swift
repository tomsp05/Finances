// BalanceWidget/BalanceWidget.swift

import WidgetKit
import SwiftUI

// You may need to create this as a new file `WidgetData.swift` and
// ensure it also has Target Membership for both the app and the widget.
struct WidgetData: Codable {
    let netBalance: Double
    let transactions: [Transaction]
}

struct Provider: AppIntentTimelineProvider {
    let appGroupID = "group.com.TomSpeake.StudentFinanceTracker"

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), netBalance: 1234.56, transactions: [])
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let data = readData()
        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            netBalance: data?.netBalance ?? 0.0,
            transactions: data?.transactions ?? []
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let data = readData()
        let entry = SimpleEntry(
            date: Date(),
            configuration: configuration,
            netBalance: data?.netBalance ?? 0.0,
            transactions: data?.transactions ?? []
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
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let netBalance: Double
    let transactions: [Transaction]
}

struct BalanceWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Net Balance")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(entry.netBalance, format: .currency(code: "GBP"))
                .font(.title2)
                .fontWeight(.bold)
                .id(entry.netBalance) // Add an ID to help SwiftUI notice changes
            
            Divider()
                    }
                    .padding()
        }
    }
    
    struct BalanceWidget: Widget {
        let kind: String = "BalanceWidget"
        
        var body: some WidgetConfiguration {
            AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
                BalanceWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            }
            .configurationDisplayName("Net Balance")
            .description("View your net balance and recent transactions.")
            .supportedFamilies([.systemSmall, .systemMedium]) // Allow medium size for more space
        }
    }
