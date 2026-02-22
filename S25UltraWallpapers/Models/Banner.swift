import Foundation

struct Banner: Identifiable {
    let id: String
    let name: String
    let imageUrl: String
    let wallpaperId: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.name = data["bannerName"] as? String ?? ""
        self.imageUrl = data["bannerUrl"] as? String ?? ""
        self.wallpaperId = data["wallpaperId"] as? String ?? id
    }
}
