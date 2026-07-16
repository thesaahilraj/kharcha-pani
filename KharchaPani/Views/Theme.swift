import SwiftUI

/// Centralized Apple Human Interface Guidelines (HIG) Design System Theme
public struct AppleTheme {
    // Pure OLED Pitch Black Background
    public static let mainBackground = Color(hex: "#000000")
    
    // iOS Secondary System Grouped Card Background
    public static let secondaryCard = Color(hex: "#1C1C1E")
    
    // iOS Tertiary Control / Pill Background
    public static let tertiaryChip = Color(hex: "#2C2C2E")
    
    // iOS Specular Translucent Hairline Border
    public static let borderLine = Color.white.opacity(0.12)
    
    // Apple Dynamic Dark Typography Colors
    public static let textPrimary = Color.white
    public static let textMuted = Color(hex: "#8E8E93")
    public static let textSecondary = Color(hex: "#AEAEB2")
    
    // Vibrant Apple System Accent Palette
    public static let accentBlue = Color(hex: "#0A84FF")
    public static let accentRed = Color(hex: "#FF453A")
    public static let accentGreen = Color(hex: "#30D158")
    public static let accentPurple = Color(hex: "#BF5AF2")
    public static let accentOrange = Color(hex: "#FF9F0A")
}

// MARK: - View Modifiers for Apple Native UI Styling
public extension View {
    /// Applies native Apple card container styling with subtle specular border line
    func appleCardStyle(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(18)
            .background(AppleTheme.secondaryCard)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppleTheme.borderLine, lineWidth: 1)
            )
    }
    
    /// Applies WWDC 2025 Liquid Glass styling for floating cards and navigation overlays
    func glassCardStyle(cornerRadius: CGFloat = 24) -> some View {
        self
            .padding(18)
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.05), Color.white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
    }
    
    /// Applies native Apple SF Pro rounded font for monetary amounts & balances
    func sfProRounded(size: CGFloat, weight: Font.Weight = .bold) -> some View {
        self.font(.system(size: size, weight: weight, design: .rounded))
    }
}
