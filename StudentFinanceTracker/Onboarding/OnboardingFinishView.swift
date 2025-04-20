import SwiftUI

struct OnboardingFinishView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(showsIndicators: false) {
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
                
                // Personalised message
                Text("Thanks! Your finance tracker is ready to use.")
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
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Theme customisation applied")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemBackground))
                        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 40)
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 20)
                .animation(.easeOut.delay(0.4), value: animateElements)
                
                // Let's go text
                Text("Let's start managing your finances!")
                    .font(.headline)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 30)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.easeOut.delay(0.6), value: animateElements)
                
                // Extra padding at the bottom to avoid the navigation controls
                Spacer()
                    .frame(height: 150)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 100)
        }
        .onAppear {
            // Animate elements sequentially
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateElements = true
            }
        }
    }
}

struct OnboardingFinishView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingFinishView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)
            
            OnboardingFinishView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
