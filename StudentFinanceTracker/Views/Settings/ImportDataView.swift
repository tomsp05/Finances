//
//  ImportDataView.swift
//   
//
//  Created by Tom Speake on 5/4/25.
//


// Create a new file called ImportDataView.swift
import SwiftUI
import UniformTypeIdentifiers

struct ImportDataView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showFilePicker = false
    @State private var isImporting = false
    @State private var importMessage = ""
    @State private var importSuccess = false
    @State private var importError = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                Text("Import Financial Data")
                    .font(.headline)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top)
                
                // Import instructions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Instructions")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        instructionStep(number: "1", text: "Select a file previously exported from this app")
                        instructionStep(number: "2", text: "Both JSON and CSV formats are supported")
                        instructionStep(number: "3", text: "New accounts and transactions will be added")
                        instructionStep(number: "4", text: "Duplicate entries will be skipped automatically")
                    }
                    .padding()
                    .background(viewModel.themeColor.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                
                // File formats section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Supported Formats")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        formatCard(format: "JSON", icon: "doc.text.fill", color: .blue)
                        formatCard(format: "CSV", icon: "tablecells.fill", color: .green)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(15)
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.06), radius: 5, x: 0, y: 2)
                
                // Import button
                Button(action: {
                    showFilePicker = true
                }) {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 8)
                        } else {
                            Image(systemName: "square.and.arrow.down.fill")
                                .font(.headline)
                        }
                        
                        Text(isImporting ? "Importing..." : "Select File to Import")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.themeColor)
                    .cornerRadius(15)
                    .shadow(color: colorScheme == .dark ? Color.clear : viewModel.themeColor.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .disabled(isImporting)
                
                // Import result message
                if importSuccess || importError {
                    VStack(spacing: 12) {
                        Image(systemName: importSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(importSuccess ? .green : .red)
                        
                        Text(importMessage)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(importSuccess ? .primary : .red)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(importSuccess ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    )
                    .padding(.horizontal)
                }
                
                // Warning section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Important Notes")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text("Importing data will add to your existing accounts and transactions. Duplicate entries will be skipped, but similar transactions may be imported multiple times.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
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
        .navigationTitle("Import Data")
        .sheet(isPresented: $showFilePicker) {
            DocumentPicker(
                supportedTypes: [UTType.json, UTType.commaSeparatedText],
                onDocumentPicked: { url in
                    processImportedFile(url: url)
                }
            )
        }
    }
    
    // Instruction step view
    private func instructionStep(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(viewModel.themeColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
        }
    }
    
    // Format card view
    private func formatCard(format: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(format)
                .font(.headline)
            
            Text(format == "JSON" ? "Complete Backup" : "Spreadsheet Compatible")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    // Process the imported file
    private func processImportedFile(url: URL) {
        isImporting = true
        importSuccess = false
        importError = false
        
        // Add small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // The file is already in our app's document directory, so we don't need
            // to worry about security-scoped resource access anymore
            let result = viewModel.importData(from: url)
            
            self.importMessage = result.message
            self.importSuccess = result.success
            self.importError = !result.success
            self.isImporting = false
            
            // Clean up the temporary file if desired
            if result.success {
                // Optional: Delete the file after successful import
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

// Document picker for file selection
struct DocumentPicker: UIViewControllerRepresentable {
    let supportedTypes: [UTType]
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        controller.delegate = context.coordinator
        controller.allowsMultipleSelection = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        
        init(_ parent: DocumentPicker) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Create a local copy of the file in the app's document directory
            let fileManager = FileManager.default
            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let uniqueFilename = "import_\(UUID().uuidString)_\(url.lastPathComponent)"
            let localURL = documentsDirectory.appendingPathComponent(uniqueFilename)
            
            do {
                // First check if we can access the original file
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    // Copy the file to our local storage where we have full access
                    try fileManager.copyItem(at: url, to: localURL)
                    
                    // Now we can safely work with the local copy
                    parent.onDocumentPicked(localURL)
                } else {
                    // Handle the case where we couldn't access the file
                    print("Failed to access the selected file")
                }
            } catch {
                print("Error copying file: \(error)")
            }
        }
    }
}
