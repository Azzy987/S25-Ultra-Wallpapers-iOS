import SwiftUI

struct ScrollToTopButton: View {
    let action: () -> Void
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 52, height: 52)
                .background {
                    if #available(iOS 26.0, *) {
                        Circle()
                            .fill(Color.clear)
                            .glassEffect(.regular, in: Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.18)
                                      : Color.black.opacity(0.06))
                            Circle()
                                .fill(.ultraThinMaterial)
                        }
                        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 4)
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
