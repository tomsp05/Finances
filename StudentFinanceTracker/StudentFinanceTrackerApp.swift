import SwiftUI

@main
struct StudentFinanceTrackerApp: App {
    @StateObject private var viewModel = FinanceViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.userPreferences.hasCompletedOnboarding {
                ContentView()
                    .environmentObject(viewModel)
            } else {
                OnboardingContainerView()
                    .environmentObject(viewModel)
            }
        }
    }
}
