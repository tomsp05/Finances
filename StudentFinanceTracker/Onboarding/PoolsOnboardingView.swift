import SwiftUI

struct PoolsOnboardingView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isAnimating = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header image
                Image(systemName: "drop.fill")
                    .font(.system(size: 70))
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 40)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: isAnimating)
                
                // Title
                Text("Money Pools")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .offset(y: isAnimating ? 0 : 20)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: isAnimating)
                
                // Subtitle
                Text("Organize your money for different goals within the same account")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .offset(y: isAnimating ? 0 : 20)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: isAnimating)
                
                // Explanation cards
                VStack(spacing: 20) {
                    // What are pools card
                    explanationCard(
                        image: "drop.circle.fill",
                        title: "What are Money Pools?",
                        description: "Pools let you allocate portions of an account's balance for specific purposes, like saving for a holiday or a new car.",
                        delay: 0.4
                    )
                    
                    // Visualization card
                    explanationCard(
                        image: "chart.pie.fill",
                        title: "Visualize Your Allocations",
                        description: "See a clear breakdown of how your money is allocated across different goals without needing separate accounts.",
                        delay: 0.5
                    )
                    
                    // Flexibility card
                    explanationCard(
                        image: "arrow.left.arrow.right",
                        title: "Flexible Money Management",
                        description: "Easily move money between pools as your priorities change, while keeping track of your progress towards each goal.",
                        delay: 0.6
                    )
                }
                
                // Example visualization
                VStack(spacing: 20) {
                    Text("How Pools Work")
                        .font(.headline)
                        .foregroundColor(viewModel.themeColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    poolExampleView()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(UIColor.secondarySystemBackground))
                        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                .offset(y: isAnimating ? 0 : 30)
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7), value: isAnimating)
                
                Spacer()
                    .frame(height: 20)
            }
            .padding(.horizontal)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isAnimating = true
                }
            }
        }
    }
    
    private func explanationCard(image: String, title: String, description: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: image)
                .font(.system(size: 28))
                .foregroundColor(viewModel.themeColor)
                .frame(width: 40)
                .padding(.top, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .offset(y: isAnimating ? 0 : 30)
        .opacity(isAnimating ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: isAnimating)
    }
    
    private func poolExampleView() -> some View {
        VStack(spacing: 16) {
            // Example balance
            HStack {
                Text("Account Balance:")
                    .font(.headline)
                Spacer()
                Text("£1,000")
                    .font(.headline)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 8)
            
            // Pool distribution circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                    .frame(width: 150, height: 150)
                
                // Holiday pool (30%)
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(Color.blue, lineWidth: 20)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                // Car fund pool (20%)
                Circle()
                    .trim(from: 0.3, to: 0.5)
                    .stroke(Color.purple, lineWidth: 20)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                
                // Unallocated (50%)
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 20)
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Pool legend
            VStack(spacing: 12) {
                legendRow(color: .blue, name: "Holiday Fund", amount: "£300")
                legendRow(color: .purple, name: "Car Savings", amount: "£200")
                legendRow(color: .gray.opacity(0.5), name: "Unallocated", amount: "£500")
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func legendRow(color: Color, name: String, amount: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 14, height: 14)
            
            Text(name)
                .font(.subheadline)
            
            Spacer()
            
            Text(amount)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
        }
    }
}

struct PoolsOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        PoolsOnboardingView()
            .environmentObject(FinanceViewModel())
    }
}
