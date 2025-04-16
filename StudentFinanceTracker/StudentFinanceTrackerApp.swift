import SwiftUI

@main
struct StudentFinanceTrackerApp: App {
    @StateObject private var viewModel = FinanceViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
