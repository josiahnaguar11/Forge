//
//  ForgeDesign.swift
//  Forge
//
//  Created by Josiah Naguar on 05/08/2025.
//

import SwiftUI

struct ForgeDesign {
    
    // MARK: - Colors
    struct Colors {
        // Primary Palette
        static let background = Color("Background")
        static let surface = Color("Surface")
        static let surfaceElevated = Color("SurfaceElevated")
        
        // Text
        static let textPrimary = Color("TextPrimary")
        static let textSecondary = Color("TextSecondary")
        static let textTertiary = Color("TextTertiary")
        
        // Accent
        static let accent = Color("Accent")
        static let accentSecondary = Color("AccentSecondary")
        
        // Semantic
        static let success = Color("Success")
        static let warning = Color("Warning")
        static let error = Color("Error")
        
        // Pillar Colors (using hex from Pillar enum)
        static let health = Color(hex: "FF6B6B")
        static let wealth = Color(hex: "4ECDC4")
        static let knowledge = Color(hex: "45B7D1")
        static let discipline = Color(hex: "FFA726")
        static let social = Color(hex: "AB47BC")
        
        // Gradient
        static let primaryGradient = LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let surfaceGradient = LinearGradient(
            colors: [surface, surfaceElevated],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    struct Typography {
        // Headers
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title1 = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        
        // Body
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        
        // Custom
        static let momentumScore = Font.system(size: 48, weight: .bold, design: .rounded)
        static let habitValue = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let streakNumber = Font.system(size: 20, weight: .bold, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.2)
        static let large = Color.black.opacity(0.3)
    }
    
    // MARK: - Animation
    struct Animation {
        static let fast = SwiftUI.Animation.easeInOut(duration: 0.15)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.75)
        static let bouncy = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.65)
        static let smooth = SwiftUI.Animation.interpolatingSpring(stiffness: 300, damping: 30)
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.1)
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
struct ForgeCardModifier: ViewModifier {
    let isElevated: Bool
    
    init(elevated: Bool = false) {
        self.isElevated = elevated
    }
    
    func body(content: Content) -> some View {
        content
            .padding(ForgeDesign.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .fill(isElevated ? ForgeDesign.Colors.surfaceElevated : ForgeDesign.Colors.surface)
                    .shadow(
                        color: ForgeDesign.Shadow.small,
                        radius: isElevated ? 8 : 4,
                        x: 0,
                        y: isElevated ? 4 : 2
                    )
            )
    }
}

struct ForgePressableModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(ForgeDesign.Animation.smooth, value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

struct ForgeGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
}

struct ForgeBackgroundBlurModifier: ViewModifier {
    let isActive: Bool
    let intensity: Double
    
    func body(content: Content) -> some View {
        content
            .background(
                Rectangle()
                    .fill(ForgeDesign.Colors.background.opacity(isActive ? intensity * 0.3 : 0))
                    .blur(radius: isActive ? intensity * 10 : 0)
                    .allowsHitTesting(false)
            )
    }
}

struct ForgeGlobalBlurModifier: ViewModifier {
    let isActive: Bool
    let intensity: Double
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isActive ? intensity * 8 : 0)
                .animation(ForgeDesign.Animation.smooth, value: isActive)
        }
    }
}

struct ForgeElevatedCardModifier: ViewModifier {
    let isPressed: Bool
    let pressProgress: Double
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: ForgeDesign.Shadow.medium,
                radius: isPressed ? 12 : 4,
                x: 0,
                y: isPressed ? 8 : 2
            )
            .overlay(
                RoundedRectangle(cornerRadius: ForgeDesign.CornerRadius.md)
                    .stroke(
                        ForgeDesign.Colors.accent.opacity(pressProgress * 0.8),
                        lineWidth: 2 + (pressProgress * 2)
                    )
                    .shadow(
                        color: ForgeDesign.Colors.accent.opacity(pressProgress * 0.6),
                        radius: 8 + (pressProgress * 4),
                        x: 0,
                        y: 0
                    )
            )
            .animation(ForgeDesign.Animation.smooth, value: isPressed)
            .animation(ForgeDesign.Animation.gentleSpring, value: pressProgress)
    }
}

// MARK: - View Extensions
extension View {
    func forgeCard(elevated: Bool = false) -> some View {
        modifier(ForgeCardModifier(elevated: elevated))
    }
    
    func forgePressable() -> some View {
        modifier(ForgePressableModifier())
    }
    
    func forgeGlow(color: Color = ForgeDesign.Colors.accent, radius: CGFloat = 4) -> some View {
        modifier(ForgeGlowModifier(color: color, radius: radius))
    }
    
    func forgeBackgroundBlur(isActive: Bool, intensity: Double = 1.0) -> some View {
        modifier(ForgeBackgroundBlurModifier(isActive: isActive, intensity: intensity))
    }
    
    func forgeGlobalBlur(isActive: Bool, intensity: Double = 1.0) -> some View {
        modifier(ForgeGlobalBlurModifier(isActive: isActive, intensity: intensity))
    }
    
    func forgeElevatedCard(isPressed: Bool, pressProgress: Double) -> some View {
        modifier(ForgeElevatedCardModifier(isPressed: isPressed, pressProgress: pressProgress))
    }
}