import SwiftUI

struct ScrollToTopButton: View {
    let action: () -> Void
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.up")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.onPrimary)
                .frame(width: 44, height: 44)
                .background(theme.primary)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        }
    }
} 
