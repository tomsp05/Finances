import SwiftUI

struct NavCardView: View {
    @EnvironmentObject var viewModel: FinanceViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var title: String
    var subtitle: String
    var cardColor: Color?
    var textAlignment: Alignment = .leading
    var isProminent: Bool = false
    var iconName: String? = nil

    var body: some View {
        HStack(spacing: adaptiveSpacing(16)) {
            if let icon = iconName {
                Image(systemName: icon)
                    .font(.system(size: adaptiveIconSize()))
                    .foregroundColor(.white)
                    .frame(width: adaptiveIconContainerSize(), height: adaptiveIconContainerSize())
                    .background(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.2))
                    .clipShape(Circle())
            }
            
            VStack(alignment: horizontalAlignment(), spacing: 8) {
                Text(title)
                    .font(adaptiveTitleFont())
                    .multilineTextAlignment(multilineAlignment())
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true) // Allow text to wrap if needed
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(adaptiveSubtitleFont())
                        .multilineTextAlignment(multilineAlignment())
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true) // Allow text to wrap if needed
                }
            }
            .frame(maxWidth: .infinity, alignment: textAlignment)
        }
        .padding(adaptivePadding())
        .background(
            ZStack {
                let backgroundColor = cardColor ?? viewModel.themeColor
                
                backgroundColor.opacity(colorScheme == .dark ? 0.95 : 1.0)
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        backgroundColor.opacity(colorScheme == .dark ? 0.7 : 0.8),
                        backgroundColor.opacity(colorScheme == .dark ? 1.0 : 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                if isProminent {
                    GeometryReader { geo in
                        Path { path in
                            for i in stride(from: 0, to: geo.size.width * 2, by: 20) {
                                path.move(to: CGPoint(x: i, y: 0))
                                path.addLine(to: CGPoint(x: 0, y: i))
                            }
                        }
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.1), lineWidth: 1)
                    }
                }
            }
        )
        .cornerRadius(20)
        .shadow(
            color: (cardColor ?? viewModel.themeColor).opacity(colorScheme == .dark ? 0.3 : 0.5),
            radius: isProminent ? (colorScheme == .dark ? 8 : 15) : (colorScheme == .dark ? 5 : 10),
            x: 0,
            y: colorScheme == .dark ? 2 : 4
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    (cardColor ?? viewModel.themeColor).opacity(colorScheme == .dark ? 0.4 : 0.0),
                    lineWidth: colorScheme == .dark ? 1 : 0
                )
        )
    }
    
    private func adaptiveSpacing(_ defaultSpacing: CGFloat) -> CGFloat {
        horizontalSizeClass == .compact ? defaultSpacing : defaultSpacing * 1.2
    }
    
    private func adaptiveIconSize() -> CGFloat {
        let baseSize = isProminent ? 36 : 24
        if horizontalSizeClass == .compact {
            return CGFloat(baseSize)
        } else {
            return CGFloat(baseSize) * 1.2
        }
    }
    
    private func adaptiveIconContainerSize() -> CGFloat {
        let baseSize = isProminent ? 60 : 40
        if horizontalSizeClass == .compact {
            return CGFloat(baseSize)
        } else {
            return CGFloat(baseSize) * 1.2
        }
    }
    
    private func adaptiveTitleFont() -> Font {
        if isProminent {
            return horizontalSizeClass == .compact ? .system(size: 28, weight: .bold) : .system(size: 32, weight: .bold)
        } else {
            return subtitle.isEmpty ?
                (horizontalSizeClass == .compact ? .title3 : .title2) :
                (horizontalSizeClass == .compact ? .subheadline : .headline)
        }
    }
    
    private func adaptiveSubtitleFont() -> Font {
        isProminent ?
            (horizontalSizeClass == .compact ? .headline : .title3) :
            (horizontalSizeClass == .compact ? .caption : .subheadline)
    }
    
    private func adaptivePadding() -> EdgeInsets {
        let basePadding = isProminent ? 24.0 : 16.0
        if horizontalSizeClass == .compact {
            if verticalSizeClass == .compact {
                // Landscape phone - reduce vertical padding
                return EdgeInsets(
                    top: basePadding * 0.7,
                    leading: basePadding,
                    bottom: basePadding * 0.7,
                    trailing: basePadding
                )
            } else {
                // Regular phone
                return EdgeInsets(
                    top: basePadding,
                    leading: basePadding,
                    bottom: basePadding,
                    trailing: basePadding
                )
            }
        } else {
            // iPad - more spacious
            return EdgeInsets(
                top: basePadding * 1.2,
                leading: basePadding * 1.2,
                bottom: basePadding * 1.2,
                trailing: basePadding * 1.2
            )
        }
    }
    
    private func horizontalAlignment() -> HorizontalAlignment {
        switch textAlignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }
    
    private func multilineAlignment() -> TextAlignment {
        switch textAlignment {
        case .leading:
            return .leading
        case .trailing:
            return .trailing
        default:
            return .center
        }
    }
}
