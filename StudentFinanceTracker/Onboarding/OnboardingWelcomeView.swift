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
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            // Responsive scaling constants based on screen width and keyboard state
            let width = geometry.size.width
            let availableHeight = geometry.size.height - keyboardHeight
            let isKeyboardVisible = keyboardHeight > 0
            
            // Adaptive sizing based on keyboard visibility
            let logoSize = isKeyboardVisible ? 
                min(max(width * 0.2, 60), 120) : // Smaller when keyboard is visible
                min(max(width * 0.3, 80), 180)   // Original size when keyboard hidden
            let imageSize = logoSize * 0.67
            let hPadding = min(max(width * 0.10, 20), 60)
            let contentSpacing: CGFloat = isKeyboardVisible ? 
                min(max(width * 0.03, 10), 20) : // Tighter spacing when keyboard visible
                min(max(width * 0.06, 18), 40)   // Original spacing
            let featureCornerRadius: CGFloat = min(max(width * 0.06, 10), 24)
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: contentSpacing) {
                        // Dynamic top spacing for better keyboard layout
                        if isKeyboardVisible {
                            Spacer()
                                .frame(height: max(20, (availableHeight - 400) / 4))
                                .frame(maxHeight: 60)
                        } else {
                            Spacer()
                                .frame(height: 40)
                        }
                        
                        // Logo with adaptive sizing
                        ZStack {
                            Circle()
                                .fill(viewModel.themeColor.opacity(colorScheme == .dark ? 0.2 : 0.1))
                                .frame(width: logoSize, height: logoSize)
                            
                            Image(systemName: "sterlingsign.ring.dashed")
                                .resizable()
                                .scaledToFit()
                                .frame(width: imageSize, height: imageSize)
                                .foregroundColor(viewModel.themeColor)
                        }
                        .scaleEffect(animateImage ? 1.0 : 0.5)
                        .opacity(animateImage ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.3), value: isKeyboardVisible)
                        
                        // Welcome title with adaptive font sizing
                        Text("Welcome to Doughs")
                            .font(.system(size: isKeyboardVisible ? 
                                         min(max(width * 0.055, 18), 28) : // Smaller when keyboard visible
                                         min(max(width * 0.073, 23), 36),  // Original size
                                         weight: .bold))
                            .foregroundColor(viewModel.themeColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, hPadding)
                            .padding(.top, isKeyboardVisible ? 0 : 5)
                            .opacity(animateTitle ? 1.0 : 0.0)
                            .offset(y: animateTitle ? 0 : 20)
                            .animation(.easeOut(duration: 0.3), value: isKeyboardVisible)
                        
                        // Introduction text - hide when keyboard is visible
                        if !isKeyboardVisible {
                            Text("Let's set up your personal finance tracker to help you manage your money effectively.")
                                .font(.system(size: min(max(width * 0.045, 15), 22), weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, hPadding)
                                .padding(.top, -5)
                                .opacity(animateText ? 1.0 : 0.0)
                                .offset(y: animateText ? 0 : 20)
                        }
                        
                        // Name input section with improved keyboard handling
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What should we call you?")
                                .font(isKeyboardVisible ? .subheadline : .headline)
                                .foregroundColor(colorScheme == .dark ? .white : .primary)
                                .animation(.easeOut(duration: 0.3), value: isKeyboardVisible)
                            
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(viewModel.themeColor)
                                    .padding(.leading, 12)
                                
                                TextField("Your Name", text: $userName)
                                    .focused($isTextFieldFocused)
                                    .padding(.vertical, isKeyboardVisible ? 10 : 12)
                                    .onChange(of: userName) { _, newValue in
                                        viewModel.userPreferences.userName = newValue
                                        viewModel.saveUserPreferences()
                                    }
                                    .onSubmit {
                                        hideKeyboard()
                                    }
                                
                                if isKeyboardVisible {
                                    Button("Done") {
                                        hideKeyboard()
                                    }
                                    .foregroundColor(viewModel.themeColor)
                                    .padding(.trailing, 12)
                                } else {
                                    Spacer()
                                    Spacer()
                                    Spacer()
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ?
                                          Color(.systemGray6).opacity(0.2) :
                                          Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isTextFieldFocused ? viewModel.themeColor : viewModel.themeColor.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
                                    )
                            )
                            .animation(.easeOut(duration: 0.2), value: isTextFieldFocused)
                        }
                        .padding(.horizontal, hPadding)
                        .padding(.bottom, isKeyboardVisible ? hPadding * 0.5 : hPadding * 0.9)
                        .id("nameInput") // Add ID for scroll targeting
                        
                        // Features section - only show when keyboard is hidden
                        if !isKeyboardVisible {
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
                                RoundedRectangle(cornerRadius: featureCornerRadius)
                                    .fill(colorScheme == .dark ?
                                          Color(.systemGray6).opacity(0.2) :
                                          Color(.systemBackground))
                                    .shadow(color: colorScheme == .dark ?
                                            Color.clear :
                                            Color.black.opacity(0.05),
                                           radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal, hPadding * 0.75)
                            .padding(.top, 5)
                            .opacity(animateText ? 1.0 : 0.0)
                            .offset(y: animateText ? 0 : 20)
                            .animation(.easeOut.delay(0.2), value: animateText)
                        }
                        
                        // Dynamic bottom spacing
                        Spacer()
                            .frame(height: isKeyboardVisible ? 20 : 60)
                    }
                    .animation(.easeOut(duration: 0.3), value: isKeyboardVisible)
                    .frame(minHeight: availableHeight)
                }
                .onChange(of: isTextFieldFocused) { _, focused in
                    if focused {
                        // Scroll to the name input when focused
                        withAnimation(.easeOut(duration: 0.5)) {
                            proxy.scrollTo("nameInput", anchor: .center)
                        }
                    }
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
