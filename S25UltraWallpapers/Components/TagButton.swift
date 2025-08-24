import SwiftUI

struct TagButton: View {
    let tag: String
    @Environment(\.appTheme) var theme
    
    var body: some View {
        Text(tag)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.primaryContainer)
            .foregroundColor(theme.onPrimaryContainer)
            .clipShape(Capsule())
            .lineLimit(1)
    }
}

#Preview {
    TagButton(tag: "Abstract")
        .padding()
} 