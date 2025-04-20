//
//  OnboardingContainerView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/20/25.
//


import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var currentPage = 0
    
    let pages = ["welcome", "categories", "accounts", "personalize", "finish"]
    
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
                    // Back button (hidden on first page)
                    if currentPage > 0 {
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
                    } else {
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Next/Finish button
                    Button(action: {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                viewModel.completeOnboarding()
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
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