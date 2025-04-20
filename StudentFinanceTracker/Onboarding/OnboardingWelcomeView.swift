import SwiftUI
import Combine

struct OnboardingWelcomeView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var userName: String = ""
    @State private var animateTitle = false
    @State private var animateText = false
    @State private var animateImage = false
    @State private var keyboardHeight: CGFloat = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // Add dynamic top spacing when keyboard is visible to center content
                    if keyboardHeight > 0 {
                        Spacer()
                            .frame(height: (geometry.size.height - keyboardHeight - 350) / 2)
                            .frame(maxHeight: 100) // Limit max spacing
                    }
                    
                    ZStack {
                        Circle()
                            .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "sterlingsign.ring.dashed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(viewModel.themeColor)
                    }
                    .scaleEffect(animateImage ? 1.0 : 0.5)
                    .opacity(animateImage ? 1.0 : 0.0)
                    
                    // Welcome title - more compact spacing
                    Text("Welcome to Finances")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(viewModel.themeColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, keyboardHeight > 0 ? 0 : 5)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .offset(y: animateTitle ? 0 : 20)
                    
                    // Introduction text - only show when keyboard is hidden
                    if keyboardHeight == 0 {
                        Text("Let's set up your personal finance tracker to help you manage your money effectively.")
                            .font(.subheadline) // Smaller font
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, -5) // Negative padding to bring closer to title
                            .opacity(animateText ? 1.0 : 0.0)
                            .offset(y: animateText ? 0 : 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What should we call you?")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
                        
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(viewModel.themeColor)
                                .padding(.leading, 12)
                            
                            TextField("Your Name", text: $userName)
                                .padding(.vertical, 12)
                                .onChange(of: userName) { newValue in
                                    viewModel.userPreferences.userName = newValue
                                    viewModel.saveUserPreferences()
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ?
                                      Color(.systemGray6).opacity(0.2) :
                                      Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(viewModel.themeColor.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        if keyboardHeight > 0 {
                            HStack {
                                Spacer()
                                Button("Done") {
                                    hideKeyboard()
                                }
                                .foregroundColor(viewModel.themeColor)
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    if keyboardHeight == 0 {
                        // Additional welcome content - more compact
                        VStack(alignment: .leading, spacing: 12) {
                            Text("See what you can do:")
                                .font(.headline)
                                .padding(.bottom, 2)
                            
                            FeatureRow(
                                icon: "banknote.fill",
                                color: .green,
                                text: "Track all your accounts in one place"
                            )
                            
                            FeatureRow(
                                icon: "chart.pie.fill",
                                color: .blue,
                                text: "Visualise your spending habits"
                            )
                            
                            FeatureRow(
                                icon: "alarm.fill",
                                color: .orange,
                                text: "Set budgets and financial goals"
                            )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(colorScheme == .dark ?
                                      Color(.systemGray6).opacity(0.2) :
                                      Color(.systemBackground))
                                .shadow(color: colorScheme == .dark ?
                                        Color.clear :
                                        Color.black.opacity(0.05),
                                       radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal, 30)
                        .padding(.top, 5)
                        .opacity(animateText ? 1.0 : 0.0)
                        .offset(y: animateText ? 0 : 20)
                        .animation(.easeOut.delay(0.2), value: animateText)
                    }
                    
                    // Add bottom spacing when keyboard is visible to balance the layout
                    if keyboardHeight > 0 {
                        Spacer()
                            .frame(height: (geometry.size.height - keyboardHeight - 350) / 2)
                            .frame(maxHeight: 100) // Limit max spacing
                    } else {
                        // Extra padding at the bottom to avoid the navigation controls when keyboard is hidden
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: keyboardHeight)
                .frame(minHeight: geometry.size.height)
            }
        }
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
            
            // Start observing keyboard notifications
            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                withAnimation {
                    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                        keyboardHeight = keyboardSize.height
                    }
                }
            }
            
            notificationCenter.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation {
                    keyboardHeight = 0
                }
            }
        }
        .onDisappear {
            // Remove keyboard observers when view disappears
            NotificationCenter.default.removeObserver(self)
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Feature row component for welcome screen
struct FeatureRow: View {
    let icon: String
    let color: Color
    let text: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(colorScheme == .dark ? 0.3 : 0.2))
                    .frame(width: 32, height: 32) // Smaller icons
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            // Feature text
            Text(text)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .primary)
        }
    }
}

struct OnboardingWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingWelcomeView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)
            
            OnboardingWelcomeView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
