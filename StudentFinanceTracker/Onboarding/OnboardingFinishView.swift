//
//  OnboardingFinishView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/20/25.
//


import SwiftUI

struct OnboardingFinishView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(viewModel.themeColor)
                .padding(.top, 50)
                .scaleEffect(animateElements ? 1.0 : 0.5)
                .opacity(animateElements ? 1.0 : 0.0)
            
            // Completion title
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(viewModel.themeColor)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 20)
            
            // Personalized message
            Text("Thanks \(viewModel.userPreferences.userName.isEmpty ? "there" : viewModel.userPreferences.userName)! Your finance tracker is ready to use.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.easeOut.delay(0.2), value: animateElements)
            
            // Summary of what's been set up
            VStack(alignment: .leading, spacing: 16) {
                Text("Summary:")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(viewModel.accounts.count) accounts configured")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(viewModel.incomeCategories.count) income categories")
                }
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("\(viewModel.expenseCategories.count) expense categories")
                }
                
                if !viewModel.budgets.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(viewModel.budgets.count) budgets created")
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal, 40)
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 20)
            .animation(.easeOut.delay(0.4), value: animateElements)
            
            Spacer()
            
            // Let's go text
            Text("Let's start managing your finances!")
                .font(.headline)
                .foregroundColor(viewModel.themeColor)
                .padding(.bottom, 30)
                .opacity(animateElements ? 1.0 : 0.0)
                .animation(.easeOut.delay(0.6), value: animateElements)
        }
        .padding(.bottom, 80)
        .onAppear {
            // Animate elements sequentially
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateElements = true
            }
        }
    }
}