import SwiftUI

struct CategoryCard: View {
    let category: Category
    
    var body: some View {
        ZStack {
                CachedAsyncImage(url: URL(string: category.thumbnail)) { phase in
                    switch phase {
                    case .empty:
                        // Optimized loading state
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
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(16)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 5)
    }
}
