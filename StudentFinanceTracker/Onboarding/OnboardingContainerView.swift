import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var currentPage = 0
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // This flag determines if the onboarding is opened from settings
    // or if it's the initial app onboarding
    var isFromSettings: Bool = false
    
    let pages = ["welcome", "categories", "accounts", "personalise", "finish"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingWelcomeView()
                    .tag(0)
                    .padding(.bottom, 100) // Add bottom padding to all content
                
                OnboardingCategoriesView()
                    .tag(1)
                    .padding(.bottom, 100)
                
                OnboardingAccountsView()
                    .tag(2)
                    .padding(.bottom, 100)
                
                OnboardingPersonalizeView()
                    .tag(3)
                    .padding(.bottom, 100)
                
                OnboardingFinishView()
                    .tag(4)
                    .padding(.bottom, 100)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Navigation controls with dedicated space
            VStack(spacing: 20) {
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? viewModel.themeColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Navigation buttons
                HStack {
                    // Cancel button (only shown when opened from settings)
                    if isFromSettings {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Cancel")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    
                    // Back button (hidden on first page)
                    if currentPage > 0 && !isFromSettings {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(viewModel.themeColor)
                            .padding()
                        }
                    } else if !isFromSettings {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Next/Finish button
                    Button(action: {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                if isFromSettings {
                                    // Just dismiss if opened from settings
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    // Complete onboarding if it's initial setup
                                    viewModel.completeOnboarding()
                                }
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : (isFromSettings ? "Done" : "Get Started"))
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(viewModel.themeColor)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .background(
                // Semi-transparent background that works in both light and dark mode
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ?
                            Color.black.opacity(0.7) :
                            Color(.systemBackground).opacity(0.8),
                        colorScheme == .dark ?
                            Color.black.opacity(0.9) :
                            Color(.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .padding(.bottom, 30)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// Preview for SwiftUI canvas
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingContainerView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)
            
            OnboardingContainerView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
