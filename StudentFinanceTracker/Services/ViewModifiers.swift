//
//  ResponsiveText.swift
//  StudentFinanceTracker
//
//  Created by Tom Speake on 4/18/25.
//


import SwiftUI

struct ResponsiveText: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let smallSize: CGFloat
    let mediumSize: CGFloat
    let largeSize: CGFloat
    let weight: Font.Weight
    
    init(
        smallSize: CGFloat, 
        mediumSize: CGFloat? = nil, 
        largeSize: CGFloat? = nil,
        weight: Font.Weight = .regular
    ) {
        self.smallSize = smallSize
        self.mediumSize = mediumSize ?? (smallSize * 1.15)
        self.largeSize = largeSize ?? (smallSize * 1.3)
        self.weight = weight
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(
                size: horizontalSizeClass == .compact ? smallSize : 
                     (UIDevice.current.userInterfaceIdiom == .pad ? largeSize : mediumSize),
                weight: weight
            ))
    }
}

// Modifier to make padding responsive
struct ResponsivePadding: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let basePadding: CGFloat
    let scaleFactor: CGFloat
    
    init(basePadding: CGFloat, scaleFactor: CGFloat = 1.3) {
        self.basePadding = basePadding
        self.scaleFactor = scaleFactor
    }
    
    func body(content: Content) -> some View {
        content.padding(horizontalSizeClass == .compact ? basePadding : basePadding * scaleFactor)
    }
}

// Modifier for responsive spacing between views
struct ResponsiveSpacing: ViewModifier {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    let baseSpacing: CGFloat
    let scaleFactor: CGFloat
    
    init(baseSpacing: CGFloat, scaleFactor: CGFloat = 1.3) {
        self.baseSpacing = baseSpacing
        self.scaleFactor = scaleFactor
    }
    
    func body(content: Content) -> some View {
        content.padding(horizontalSizeClass == .compact ? baseSpacing : baseSpacing * scaleFactor)
    }
}

// Extension to make these modifiers easier to use
extension View {
    func responsiveText(smallSize: CGFloat, mediumSize: CGFloat? = nil, largeSize: CGFloat? = nil, weight: Font.Weight = .regular) -> some View {
        self.modifier(ResponsiveText(smallSize: smallSize, mediumSize: mediumSize, largeSize: largeSize, weight: weight))
    }
    
    func responsivePadding(_ padding: CGFloat, scaleFactor: CGFloat = 1.3) -> some View {
        self.modifier(ResponsivePadding(basePadding: padding, scaleFactor: scaleFactor))
    }
    
    func responsiveSpacing(_ spacing: CGFloat, scaleFactor: CGFloat = 1.3) -> some View {
        self.modifier(ResponsiveSpacing(baseSpacing: spacing, scaleFactor: scaleFactor))
    }
}

// Safe area adapting container for devices with notches/dynamic islands
struct SafeAreaAdaptingContainer<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, calculateTopPadding(geometry))
                .padding(.bottom, calculateBottomPadding(geometry))
        }
    }
    
    private func calculateTopPadding(_ geometry: GeometryProxy) -> CGFloat {
        // Add custom padding based on device top safe area
        let topSafeArea = geometry.safeAreaInsets.top
        return topSafeArea > 20 ? topSafeArea : 0
    }
    
    private func calculateBottomPadding(_ geometry: GeometryProxy) -> CGFloat {
        // Add custom padding based on device bottom safe area
        let bottomSafeArea = geometry.safeAreaInsets.bottom
        return bottomSafeArea > 0 ? bottomSafeArea : 0
    }
}
