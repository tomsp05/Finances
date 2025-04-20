import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var currentPage = 0
    @Environment(\.presentationMode) var presentationMode
    
    // This flag determines if the onboarding is opened from settings
    // or if it's the initial app onboarding
    var isFromSettings: Bool = false
    
    let pages = ["welcome", "categories", "accounts", "personalise", "finish"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                OnboardingWelcomeView()
                    .tag(0)
                
                OnboardingCategoriesView()
                    .tag(1)
                
                OnboardingAccountsView()
                    .tag(2)
                
                OnboardingPersonalizeView()
                    .tag(3)
                
                OnboardingFinishView()
                    .tag(4)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)
            
            // Page control and navigation buttons
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
            .padding(.bottom, 30)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// Preview for SwiftUI canvas
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContainerView()
            .environmentObject(FinanceViewModel())
    }
}
