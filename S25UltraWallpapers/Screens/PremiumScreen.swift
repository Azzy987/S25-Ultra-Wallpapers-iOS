import SwiftUI

struct PremiumScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        PaywallContentView(
            showCloseButton: true,
            onDismiss: { dismiss() }
        )
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 { dragOffset = value.translation.height }
                }
                .onEnded { value in
                    if value.translation.height > 150 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { dragOffset = 0 }
                    }
                }
        )
    }
}


enum PremiumPlan: CaseIterable {
    case monthly, yearly, lifetime

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Billed monthly"
        case .yearly: return "Billed annually"
        case .lifetime: return "One-time payment"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "month"
        case .yearly: return "year"
        case .lifetime: return "lifetime"
        }
    }

    var rawValue: String {
        switch self {
        case .monthly: return "monthly"
        case .yearly: return "yearly"
        case .lifetime: return "lifetime"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "monthly": self = .monthly
        case "yearly": self = .yearly
        case "lifetime": self = .lifetime
        default: return nil
        }
    }
}

#Preview {
    PremiumScreen()
        .environmentObject(ThemeManager.shared)
}
