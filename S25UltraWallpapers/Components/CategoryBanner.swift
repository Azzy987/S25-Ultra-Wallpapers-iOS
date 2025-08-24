import SwiftUI

struct CategoryBanner: View {
    let category: Category
    
    var body: some View {
        ZStack(alignment: .center) {
            CachedAsyncImage(url: URL(string: category.thumbnail)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
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
                .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 5)
    }
} 
