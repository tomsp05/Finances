//
//  OnboardingPersonalizeView.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/20/25.
//


import SwiftUI

struct OnboardingPersonalizeView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @State private var selectedThemeColor: String
    @State private var addBudgets = false
    
    // Available theme colors with their visual representations
    let themeOptions = [
        "Blue": Color(red: 0.20, green: 0.40, blue: 0.70),
        "Green": Color(red: 0.20, green: 0.55, blue: 0.30),
        "Orange": Color(red: 0.80, green: 0.40, blue: 0.20),
        "Purple": Color(red: 0.50, green: 0.25, blue: 0.70),
        "Red": Color(red: 0.70, green: 0.20, blue: 0.20),
        "Teal": Color(red: 0.20, green: 0.50, blue: 0.60)
    ]
    
    init() {
        // Get the current theme color from the view model
        let viewModel = FinanceViewModel()
        _selectedThemeColor = State(initialValue: viewModel.themeColorName)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Section title
                Text("Personalize Your App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 40)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                
                // Description text
                Text("Choose your preferred theme color and set up optional features")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut.delay(0.1), value: animateElements)
                
                // Theme color selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("App Theme")
                        .font(.headline)
                        .padding(.horizontal)
                        .opacity(animateElements ? 1 : 0)
                        .animation(.easeOut.delay(0.2), value: animateElements)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 20) {
                        ForEach(themeOptions.sorted(by: { $0.key < $1.key }), id: \.key) { colorName, colorValue in
                            ThemeColorButton(
                                colorName: colorName,
                                color: colorValue,
                                isSelected: selectedThemeColor == colorName,
                                onTap: {
                                    selectedThemeColor = colorName
                                    viewModel.themeColorName = colorName
                                }
                            )
                            .opacity(animateElements ? 1 : 0)
                            .animation(.easeOut.delay(0.3), value: animateElements)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Optional budget setup
                VStack(alignment: .leading, spacing: 20) {
                    Toggle(isOn: $addBudgets) {
                        Text("Set up budgets")
                            .font(.headline)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut.delay(0.4), value: animateElements)
                    
                    if addBudgets {
                        // Simple budget setup form appears when toggled
                        OnboardingBudgetSetup()
                            .opacity(animateElements ? 1 : 0)
                            .animation(.easeOut.delay(0.5), value: animateElements)
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, 80)
        }
        .onAppear {
            // Set initial theme color from view model
            selectedThemeColor = viewModel.themeColorName
            
            // Animate appearance
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateElements = true
            }
        }
    }
}

// Theme color selection button
struct ThemeColorButton: View {
    let colorName: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                            .padding(2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.6), radius: isSelected ? 5 : 0)
                
                Text(colorName)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : .primary)
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// Simple budget setup form
struct OnboardingBudgetSetup: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var overallBudget: String = ""
    @State private var timePeriod: TimePeriod = .monthly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Budget Setup")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Overall budget amount
                HStack {
                    Text("Monthly Budget Amount")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    HStack {
                        Text("£")
                            .foregroundColor(.secondary)
                        
                        TextField("0.00", text: $overallBudget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Budget period
                HStack {
                    Text("Budget Period")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Picker("Period", selection: $timePeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.displayName()).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .onDisappear {
            // Create budget when leaving this view if amount is entered
            createBudget()
        }
    }
    
    private func createBudget() {
        guard let amount = Double(overallBudget), amount > 0 else { return }
        
        // Create an overall budget
        let newBudget = Budget(
            name: "Overall \(timePeriod.displayName()) Budget",
            amount: amount,
            type: .overall,
            timePeriod: timePeriod,
            startDate: Date()
        )
        
        viewModel.addBudget(newBudget)
    }
}