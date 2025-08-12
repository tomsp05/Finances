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
            // Responsive scaling constants based on screen width
            let width = geometry.size.width
            let logoSize = min(max(width * 0.3, 80), 180) // Circle diameter scales with width, bounded min/max
            let imageSize = logoSize * 0.67                  // Image inside circle scales proportionally
            let hPadding = min(max(width * 0.10, 20), 60)  // Horizontal padding scales responsively
            let contentSpacing: CGFloat = min(max(width * 0.06, 18), 40) // Vertical spacing scales responsively
            let featureCornerRadius: CGFloat = min(max(width * 0.06, 10), 24) // Feature card corner radius scales
            let bottomInset: CGFloat = min(max(width * 0.13, 40), 100) // Bottom safe area inset scales
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: contentSpacing) {
                    // Add dynamic top spacing when keyboard is visible to center content
                    if keyboardHeight > 0 {
                        // Use proportional spacing based on available height and keyboard height
                        Spacer()
                            .frame(height: (geometry.size.height - keyboardHeight - 350) / 2)
                            .frame(maxHeight: 100) // Limit max spacing
                    }
                    
                    ZStack {
                        Circle()
                            .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                            .frame(width: logoSize, height: logoSize) // Responsive circle size
                        
                        Image(systemName: "sterlingsign.ring.dashed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: imageSize, height: imageSize) // Responsive image size
                            .foregroundColor(viewModel.themeColor)
                    }
                    .scaleEffect(animateImage ? 1.0 : 0.5)
                    .opacity(animateImage ? 1.0 : 0.0)
                    
                    // Welcome title - scaled font size and adjusted spacing
                    Text("Welcome to Doughs")
                        .font(.system(size: min(max(width * 0.073, 23), 36), weight: .bold)) // Responsive font size
                        .foregroundColor(viewModel.themeColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, hPadding) // Responsive horizontal padding
                        .padding(.top, keyboardHeight > 0 ? 0 : 5)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .offset(y: animateTitle ? 0 : 20)
                    
                    // Introduction text - only show when keyboard is hidden, scaled font size
                    if keyboardHeight == 0 {
                        Text("Let's set up your personal finance tracker to help you manage your money effectively.")
                            .font(.headline)
                            .font(.system(size: min(max(width * 0.045, 15), 22), weight: .semibold)) // Responsive font size
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, hPadding) // Responsive horizontal padding
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
                            Spacer()
                            Spacer()
                            Spacer()

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
                    }
                    .padding(.horizontal, hPadding) // Responsive horizontal padding
                    .padding(.bottom, hPadding * 0.9) // Responsive bottom padding
                    
                    
                    if keyboardHeight == 0 {
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
                            RoundedRectangle(cornerRadius: featureCornerRadius) // Responsive corner radius
                                .fill(colorScheme == .dark ?
                                      Color(.systemGray6).opacity(0.2) :
                                      Color(.systemBackground))
                                .shadow(color: colorScheme == .dark ?
                                        Color.clear :
                                        Color.black.opacity(0.05),
                                       radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal, hPadding * 0.75) // Responsive horizontal padding
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
                        // Use safe area inset for bottom padding
                    }
                }
                .animation(.easeOut(duration: 0.2), value: keyboardHeight)
                .frame(minHeight: geometry.size.height)
                // Add safe area inset at bottom instead of fixed spacer
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: bottomInset)
                }
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

