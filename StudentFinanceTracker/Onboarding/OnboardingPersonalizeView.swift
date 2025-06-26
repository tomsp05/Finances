import SwiftUI

struct OnboardingPersonalizeView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @State private var animateElements = false
    @State private var selectedThemeColor: String
    @Environment(\.colorScheme) var colorScheme
    
    // Available theme colours with their visual representations
    let themeOptions = [
            "Blue": Color(red: 0.20, green: 0.40, blue: 0.70),
            "Green": Color(red: 0.20, green: 0.55, blue: 0.30),
            "Orange": Color(red: 0.80, green: 0.40, blue: 0.20),
            "Purple": Color(red: 0.50, green: 0.25, blue: 0.70),
            "Red": Color(red: 0.70, green: 0.20, blue: 0.20),
            "Teal": Color(red: 0.20, green: 0.50, blue: 0.60),
            "Pink": Color(red: 0.90, green: 0.40, blue: 0.60)
        ]
    
    init() {
        // Get the current theme colour from the view model
        let viewModel = FinanceViewModel()
        _selectedThemeColor = State(initialValue: viewModel.themeColorName)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // Section title
                Text("Personalise Your App")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.themeColor)
                    .padding(.top, 30)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                
                // Description text
                Text("Choose your preferred theme colour to customise your experience")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(animateElements ? 1 : 0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut.delay(0.1), value: animateElements)
                
                // Theme colour selection
                VStack(alignment: .leading, spacing: 15) {
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
                    
                    // Preview card with selected theme
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        RoundedRectangle(cornerRadius: 15)
                            .fill(getThemeColor(name: selectedThemeColor))
                            .frame(height: 60)
                            .overlay(
                                HStack {
                                    Image(systemName: "creditcard.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(.leading)
                                    
                                    Text("Theme Preview")
                                        .foregroundColor(.white)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                }
                            )
                    }
                    .padding(.horizontal)
                    .opacity(animateElements ? 1 : 0)
                    .animation(.easeOut.delay(0.4), value: animateElements)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(colorScheme == .dark ? Color(.systemGray6).opacity(0.2) : Color(.systemBackground))
                        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Extra padding at the bottom to avoid the navigation controls
                Spacer()
                    .frame(height: 150)
            }
            .frame(minHeight: UIScreen.main.bounds.height - 100)
        }
        .onAppear {
            // Set initial theme colour from view model
            selectedThemeColor = viewModel.themeColorName
            
            // Animate appearance
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateElements = true
            }
        }
    }
    
    // Helper function to get theme colour
    private func getThemeColor(name: String) -> Color {
            // Match the same colour calculation as in the ViewModel
            switch name {
            case "Blue":
                return Color(red: 0.20, green: 0.40, blue: 0.70)
            case "Green":
                return Color(red: 0.20, green: 0.55, blue: 0.30)
            case "Orange":
                return Color(red: 0.80, green: 0.40, blue: 0.20)
            case "Purple":
                return Color(red: 0.50, green: 0.25, blue: 0.70)
            case "Red":
                return Color(red: 0.70, green: 0.20, blue: 0.20)
            case "Teal":
                return Color(red: 0.20, green: 0.50, blue: 0.60)
            case "Pink":
                return Color(red: 0.90, green: 0.40, blue: 0.60)
            default:
                return Color(red: 0.20, green: 0.40, blue: 0.70)
            }
        }

}

// Theme colour selection button
struct ThemeColorButton: View {
    let colorName: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(colorScheme == .dark ? Color.white : Color.white, lineWidth: isSelected ? 3 : 0)
                            .padding(2)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: color.opacity(0.6), radius: isSelected ? 5 : 0)
                
                Text(colorName)
                    .font(.caption)
                    .foregroundColor(isSelected ? color : (colorScheme == .dark ? .white : .primary))
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct OnboardingPersonalizeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            OnboardingPersonalizeView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.light)
            
            OnboardingPersonalizeView()
                .environmentObject(FinanceViewModel())
                .preferredColorScheme(.dark)
        }
    }
}
