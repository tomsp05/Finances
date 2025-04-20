//
//  OnboardingWelcomeView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/20/25.
//


import SwiftUI

struct OnboardingWelcomeView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var userName: String = ""
    @State private var animateTitle = false
    @State private var animateText = false
    @State private var animateImage = false
    
    var body: some View {
        VStack(spacing: 30) {
            // App logo or icon
            Image(systemName: "sterlingsign.ring.dashed")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(viewModel.themeColor)
                .padding(.top, 50)
                .scaleEffect(animateImage ? 1.0 : 0.5)
                .opacity(animateImage ? 1.0 : 0.0)
            
            // Welcome title
            Text("Welcome to Finances")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(viewModel.themeColor)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .opacity(animateTitle ? 1.0 : 0.0)
                .offset(y: animateTitle ? 0 : 20)
            
            // Introduction text
            Text("Let's set up your personal finance tracker to help you manage your money effectively.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .opacity(animateText ? 1.0 : 0.0)
                .offset(y: animateText ? 0 : 20)
            
            // User name input
            VStack(alignment: .leading, spacing: 8) {
                Text("What should we call you?")
                    .font(.headline)
                
                TextField("Your Name", text: $userName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .onChange(of: userName) { newValue in
                        viewModel.userPreferences.userName = newValue
                        viewModel.saveUserPreferences()
                    }
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.bottom, 80)
        .onAppear {
            // Load any existing user name
            userName = viewModel.userPreferences.userName
            
            // Animate elements sequentially
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateImage = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                animateTitle = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                animateText = true
            }
        }
    }
}
