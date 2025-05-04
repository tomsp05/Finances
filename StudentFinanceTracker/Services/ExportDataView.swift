//
//  ExportDataView.swift
//   
//
//  Created by Tom Speake on 5/4/25.
//


// Create a new file called ExportDataView.swift
import SwiftUI

struct ExportDataView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedFormat = "JSON"
    @State private var exportInProgress = false
    @State private var exportCompleted = false
    @State private var exportError = false
    @State private var exportedFileURL: URL?
    
    // Statistics for display
    private var accountCount: Int { viewModel.accounts.count }
    private var transactionCount: Int { viewModel.transactions.count }
    private var categoryCount: Int { viewModel.incomeCategories.count + viewModel.expenseCategories.count }
    private var budgetCount: Int { viewModel.budgets.count }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Export Your Financial Data")
                    .font(.headline)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top)
                
                // Data summary card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Data Summary")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        dataCountView(count: accountCount, label: "Accounts", icon: "creditcard.fill", color: .blue)
                        dataCountView(count: transactionCount, label: "Transactions", icon: "arrow.left.arrow.right", color: .green)
                    }
                    
                    HStack(spacing: 20) {
                        dataCountView(count: categoryCount, label: "Categories", icon: "tag.fill", color: .orange)
                        dataCountView(count: budgetCount, label: "Budgets", icon: "chart.pie.fill", color: .purple)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                
                // Export format selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Format")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        FormatSelectionButton(
                            title: "JSON",
                            description: "Best for backup and restoring data",
                            isSelected: selectedFormat == "JSON",
                            action: { selectedFormat = "JSON" }
                        )
                        
                        FormatSelectionButton(
                            title: "CSV",
                            description: "Compatible with spreadsheet applications",
                            isSelected: selectedFormat == "CSV",
                            action: { selectedFormat = "CSV" }
                        )
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                
                // Export button
                Button(action: performExport) {
                    HStack {
                        if exportInProgress {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.headline)
                        }
                        
                        Text(exportInProgress ? "Exporting..." : "Export Data")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.themeColor)
                    .cornerRadius(15)
                    .shadow(color: colorScheme == .dark ? Color.clear : viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .disabled(exportInProgress)
                
                // Success or error message
                if exportCompleted {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green)
                        
                        Text("Export completed successfully!")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        if let fileURL = exportedFileURL {
                            Button(action: {
                                shareFile(fileURL: fileURL)
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share File")
                                }
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.green)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(15)
                }
                
                if exportError {
                    VStack(spacing: 12) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        
                        Text("Error exporting data. Please try again.")
                            .font(.headline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(15)
                }
                
                // Information about export
                VStack(alignment: .leading, spacing: 10) {
                    Text("What's included in the export")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint(text: "All accounts and their balances")
                        bulletPoint(text: "Transaction history")
                        bulletPoint(text: "Categories and budgets")
                        bulletPoint(text: "Your app preferences")
                    }
                    .padding()
                    .background(viewModel.themeColor.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
            }
            .padding()
        }
        .background(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1).ignoresSafeArea())
        .navigationTitle("Export Data")
    }
    
    // Data count item view
    private func dataCountView(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Bullet point for info list
    private func bulletPoint(text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(viewModel.themeColor)
                .font(.system(size: 14))
                .padding(.top, 2)
            
            Text(text)
                .font(.subheadline)
        }
    }
    
    // Export function
    private func performExport() {
        exportInProgress = true
        exportCompleted = false
        exportError = false
        
        // Add a slight delay to show progress
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let fileURL = viewModel.exportData(format: selectedFormat.lowercased()) {
                exportedFileURL = fileURL
                exportCompleted = true
                exportInProgress = false
                
                // Automatically show share sheet after small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    shareFile(fileURL: fileURL)
                }
            } else {
                exportError = true
                exportInProgress = false
            }
        }
    }
    
    // Share the exported file
    private func shareFile(fileURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        // Present the activity view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            if let presenter = rootViewController.presentedViewController {
                presenter.present(activityVC, animated: true, completion: nil)
            } else {
                rootViewController.present(activityVC, animated: true, completion: nil)
            }
        }
    }
}

// Selection button for export format
struct FormatSelectionButton: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? viewModel.themeColor : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(viewModel.themeColor)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1) :
                          Color(UIColor.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? viewModel.themeColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}