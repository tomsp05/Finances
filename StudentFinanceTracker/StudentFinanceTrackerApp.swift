import SwiftUI

@main
struct StudentFinanceTrackerApp: App {
    @StateObject private var viewModel = FinanceViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.userPreferences.hasCompletedOnboarding {
                ContentView()
                    .environmentObject(viewModel)
                    .accentColor(viewModel.themeColor) // Set the global accent color
            } else {
                OnboardingContainerView()
                    .environmentObject(viewModel)
                    .accentColor(viewModel.themeColor) // Set the global accent color
            }
        }
    }
}
