import Foundation

struct CarouselCard: Identifiable, Equatable {
    let id: String
    let imageUrl: String
    let name: String
    let wallpaperId: String
    var previousOffset: CGFloat = 0
    
    static func == (lhs: CarouselCard, rhs: CarouselCard) -> Bool {
        lhs.id == rhs.id
    }
    
    init(from banner: Banner) {
        self.id = banner.id
        self.imageUrl = banner.imageUrl
        self.name = banner.name
        self.wallpaperId = banner.wallpaperId
    }
}
