import SwiftUI

struct NavCardView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    
    /// The main text (e.g. for net balance, this is the £ sign and value).
    var title: String
    /// An optional subtitle.
    var subtitle: String
    /// The background colour for the card.
    var cardColor: Color?
    /// The horizontal alignment of the content.
    var textAlignment: Alignment = .leading
    /// Optional flag to indicate if this card should have enlarged styling.
    var isProminent: Bool = false
    /// Icon name to display (SF Symbols)
    var iconName: String? = nil

    var body: some View {
        HStack(spacing: 16) {
            // Optional icon
            if let icon = iconName {
                Image(systemName: icon)
                    .font(.system(size: isProminent ? 36 : 24))
                    .foregroundColor(.white)
                    .frame(width: isProminent ? 60 : 40, height: isProminent ? 60 : 40)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            
            VStack(alignment: horizontalAlignment(), spacing: 8) {
                Text(title)
                    .font(isProminent ? .system(size: 32, weight: .bold) : (subtitle.isEmpty ? .title2 : .headline))
                    .multilineTextAlignment(multilineAlignment())
                    .foregroundColor(.white)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(isProminent ? .title3 : .subheadline)
                        .multilineTextAlignment(multilineAlignment())
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: textAlignment)
        }
        .padding(isProminent ? 24 : 16)
        .background(
            ZStack {
                // Use theme color if no specific color is provided
                let backgroundColor = cardColor ?? viewModel.themeColor
                
                // Base color
                backgroundColor
                
                // Gradient overlay for more depth
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor.opacity(0.7),
                        backgroundColor
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Optional pattern overlay for texture
                if isProminent {
                    GeometryReader { geo in
                        Path { path in
                            for i in stride(from: 0, to: geo.size.width * 2, by: 20) {
                                path.move(to: CGPoint(x: i, y: 0))
                                path.addLine(to: CGPoint(x: 0, y: i))
                            }
                        }
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }
                }
            }
        )
        .cornerRadius(20)
        .shadow(color: (cardColor ?? viewModel.themeColor).opacity(0.5), radius: isProminent ? 15 : 10, x: 0, y: isProminent ? 8 : 5)
    }
    
    // Helper: convert Alignment into TextAlignment for multiline text.
    private func multilineAlignment() -> TextAlignment {
        switch textAlignment {
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            return .leading
        }
    }
    
    // Helper: for the VStack alignment, if centered, use .center.
    private func horizontalAlignment() -> HorizontalAlignment {
        switch textAlignment {
        case .center:
            return .center
        case .trailing:
            return .trailing
        default:
            return .leading
        }
    }
}

struct NavCardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavCardView(
                title: "£1,234.56",
                subtitle: "Current Balance",
                cardColor: Color.blue,
                textAlignment: .center,
                isProminent: true,
                iconName: "creditcard.fill"
            )
            .environmentObject(FinanceViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
            
            NavCardView(
                title: "Accounts",
                subtitle: "",
                cardColor: nil, // Using theme color
                iconName: "folder.fill"
            )
            .environmentObject(FinanceViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
        }
    }
}
