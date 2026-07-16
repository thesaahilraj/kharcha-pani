import SwiftUI

public struct KharchaPaniLogoView: View {
    var size: CGFloat = 64
    
    public init(size: CGFloat = 64) {
        self.size = size
    }
    
    public var body: some View {
        ZStack {
            // Apple Titanium Dark Surface Container
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppleTheme.tertiaryChip, AppleTheme.secondaryCard],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(AppleTheme.borderLine, lineWidth: 1.5)
                )
                .frame(width: size, height: size)
                .shadow(color: Color.black.opacity(0.5), radius: size * 0.15, x: 0, y: size * 0.08)
            
            // Reticle Outer Tick Marks & Monoline Shapes
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = canvasSize.width * 0.35
                
                // Outer Subtle Radar Circle
                var circlePath = Path()
                circlePath.addEllipse(in: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.stroke(circlePath, with: .color(AppleTheme.textMuted.opacity(0.3)), lineWidth: 1.5)
                
                // Crosshair Reticle Tick Marks (N, E, S, W)
                let tickLength: CGFloat = canvasSize.width * 0.08
                
                var ticks = Path()
                // Top tick
                ticks.move(to: CGPoint(x: center.x, y: center.y - radius))
                ticks.addLine(to: CGPoint(x: center.x, y: center.y - radius + tickLength))
                
                // Bottom tick
                ticks.move(to: CGPoint(x: center.x, y: center.y + radius))
                ticks.addLine(to: CGPoint(x: center.x, y: center.y + radius - tickLength))
                
                // Left tick
                ticks.move(to: CGPoint(x: center.x - radius, y: center.y))
                ticks.addLine(to: CGPoint(x: center.x - radius + tickLength, y: center.y))
                
                // Right tick
                ticks.move(to: CGPoint(x: center.x + radius, y: center.y))
                ticks.addLine(to: CGPoint(x: center.x + radius - tickLength, y: center.y))
                
                context.stroke(ticks, with: .color(AppleTheme.textMuted.opacity(0.6)), lineWidth: 1.5)
            }
            .frame(width: size, height: size)
            
            // Primary Glyph: Crisp Titanium Rupee (₹) in Apple Blue Accent
            Text("₹")
                .font(.system(size: size * 0.44, weight: .bold, design: .rounded))
                .foregroundColor(AppleTheme.accentBlue)
        }
    }
}

#Preview {
    KharchaPaniLogoView(size: 80)
        .padding()
        .background(AppleTheme.mainBackground)
}
