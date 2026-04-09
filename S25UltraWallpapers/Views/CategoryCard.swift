import SwiftUI

struct CategoryCard: View {
    let category: Category
    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: URL(string: category.thumbnail)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "photo")
                            .foregroundColor(.white)
                            .font(.largeTitle)
                    }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 150)
            .clipped()

            Text(category.name.uppercased())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(theme.onSurface)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(theme.surface.opacity(0.85))
                .clipShape(NameStripShape(radius: 24))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
    }
}
