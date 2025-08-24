import SwiftUI

struct ColorButton: View {
    let hexColor: String
    @Environment(\.appTheme) var theme
    
    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: hexColor))
                .frame(height: 70)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.surfaceVariant, lineWidth: 1)
                )
            
            Text(hexColor.uppercased())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.onSurface)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ColorButton(hexColor: "#FF5733")
        .padding()
} 