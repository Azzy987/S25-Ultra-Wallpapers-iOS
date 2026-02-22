import SwiftUI

// MARK: - Liquid Glass Extensions with iOS Version Compatibility

// MARK: - View Extensions

extension View {
    /// Applies Liquid Glass effect with iOS 26 compatibility
    /// Falls back to blur effect on older iOS versions
    @ViewBuilder
    func applyLiquidGlass(
        tintColor: Color? = nil,
        isInteractive: Bool = false
    ) -> some View {
        if #available(iOS 26.0, *) {
            // Use native iOS 26 Liquid Glass
            if let tintColor = tintColor {
                if isInteractive {
                    self.glassEffect(.regular.tint(tintColor).interactive())
                } else {
                    self.glassEffect(.regular.tint(tintColor))
                }
            } else {
                if isInteractive {
                    self.glassEffect(.regular.interactive())
                } else {
                    self.glassEffect(.regular)
                }
            }
        } else {
            // Fallback for iOS < 26.0
            self.background {
                ZStack {
                    VisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                    if let tintColor = tintColor {
                        tintColor.opacity(0.3)
                    }
                }
            }
            .opacity(isInteractive ? 0.9 : 0.8)
        }
    }
}

// MARK: - Visual Effect View for Fallback

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

// MARK: - Button Styles with Liquid Glass

struct LiquidGlassButtonStyle: ButtonStyle {
    let tintColor: Color?
    let cornerRadius: CGFloat

    init(tintColor: Color? = nil, cornerRadius: CGFloat = 12) {
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .applyLiquidGlass(tintColor: tintColor, isInteractive: true)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == LiquidGlassButtonStyle {
    static var liquidGlass: LiquidGlassButtonStyle {
        LiquidGlassButtonStyle()
    }

    static func liquidGlass(tintColor: Color?, cornerRadius: CGFloat = 12) -> LiquidGlassButtonStyle {
        LiquidGlassButtonStyle(tintColor: tintColor, cornerRadius: cornerRadius)
    }
}
