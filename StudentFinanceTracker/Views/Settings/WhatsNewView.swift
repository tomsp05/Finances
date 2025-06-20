//
//  WhatsNewView.swift
//   
//
//  Created by Tom Speake on 6/20/25.
//


import SwiftUI

struct WhatsNewView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var viewModel: FinanceViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What's New in Doughs")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(viewModel.themeColor)
                        
                        Text("Here's what's new and improved in the latest version of Doughs, along with any known issues.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // What's New Section
                    whatsNewSection
                    
                    // Known Issues Section
                    knownIssuesSection
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(viewModel.themeColor)
                }
            }
        }
    }
    
    private var whatsNewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Latest Updates")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 20) {
                FeatureBullet(
                    icon: "sterlingsign.circle.fill",
                    title: "Enhanced Budgeting",
                    description: "Budgets now automatically reset for new periods (weekly, monthly, yearly) and track spending more accurately based on your chosen timeframes.",
                    iconColor: .green
                )
                
                FeatureBullet(
                    icon: "chart.bar.fill",
                    title: "Advanced Analytics Filters",
                    description: "New time filters (e.g., Year to Date, Past Year) and improved category/type selection for more granular insights into your spending habits.",
                    iconColor: .blue
                )
                
                FeatureBullet(
                    icon: "square.and.arrow.up.fill",
                    title: "Data Import & Export",
                    description: "You can now easily export all your financial data to CSV or JSON formats for backup or external analysis, and import it back into the app.",
                    iconColor: .orange
                )
                
                FeatureBullet(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Recurring Transactions",
                    description: "Set up transactions to repeat daily, weekly, monthly, or yearly. Manage future instances with options to update or delete the entire series.",
                    iconColor: .purple
                )
                
                FeatureBullet(
                    icon: "creditcard.fill",
                    title: "Money Pools",
                    description: "Allocate portions of your account balances into 'pools' for specific savings goals, helping you visualize and manage funds more effectively.",
                    iconColor: .red
                )
                
                FeatureBullet(
                    icon: "person.2.fill",
                    title: "Split Payment Tracking",
                    description: "Track expenses split with friends, noting who paid what and where the friend's portion went (e.g., cash, another account).",
                    iconColor: .teal
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(viewModel.cardBackgroundColor(for: colorScheme))
                    .shadow(color: viewModel.shadowColor(for: colorScheme), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
    }
    
    private var knownIssuesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Known Issues")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 15) {
                IssueBullet(
                    icon: "square.split.diagonal.fill",
                    title: "Split Payments Not Exporting",
                    description: "Split payments experience issues while importing/exporting. Split transactions will not be imported correctily (if at all).",
                    iconColor: .red
                )
                
                IssueBullet(
                    icon: "exclamationmark.triangle.fill",
                    title: "Minor UI Glitches",
                    description: "Some minor visual inconsistencies may occur on certain device sizes or during rapid navigation transitions.",
                    iconColor: .orange
                )
                
                
                IssueBullet(
                    icon: "ant.fill",
                    title: "Occasional Performance Lags",
                    description: "Users with very large transaction histories might experience slight delays during data loading or recalculations.",
                    iconColor: .red
                )
                
                IssueBullet(
                    icon: "arrow.triangle.swap",
                    title: "Split Transaction Editing Limitations",
                    description: "When editing a split transaction, only description, date, and category can be modified. Split amounts or participants cannot be changed after creation.",
                    iconColor: .yellow
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(viewModel.cardBackgroundColor(for: colorScheme))
                    .shadow(color: viewModel.shadowColor(for: colorScheme), radius: 5, x: 0, y: 2)
            )
            .padding(.horizontal)
        }
    }
}

// Reusable bullet point view for features
struct FeatureBullet: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Reusable bullet point view for issues
struct IssueBullet: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WhatsNewView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)
            
            WhatsNewView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
