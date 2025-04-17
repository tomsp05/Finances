import SwiftUI

struct NavCardView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    
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
                
                // Base color with slight adjustment for dark mode
                backgroundColor.opacity(colorScheme == .dark ? 0.9 : 1.0)
                
                // Gradient overlay for more depth - adjusted for dark mode
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor.opacity(colorScheme == .dark ? 0.6 : 0.7),
                        backgroundColor.opacity(colorScheme == .dark ? 0.95 : 1.0)
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
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.07 : 0.1), lineWidth: 1)
                    }
                }
            }
        )
        .cornerRadius(20)
        .shadow(
            color: (cardColor ?? viewModel.themeColor).opacity(colorScheme == .dark ? 0.2 : 0.5),
            radius: isProminent ? (colorScheme == .dark ? 10 : 15) : (colorScheme == .dark ? 7 : 10),
            x: 0,
            y: isProminent ? (colorScheme == .dark ? 5 : 8) : (colorScheme == .dark ? 3 : 5)
        )
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
