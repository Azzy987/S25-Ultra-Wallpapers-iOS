import Foundation

struct CarouselCard: Identifiable, Equatable {
    let id: String
    let imageUrl: String
    var previousOffset: CGFloat = 0
    
    static func == (lhs: CarouselCard, rhs: CarouselCard) -> Bool {
        lhs.id == rhs.id
    }
    
    init(from banner: Banner) {
        self.id = banner.id
        self.imageUrl = banner.imageUrl
    }
} 