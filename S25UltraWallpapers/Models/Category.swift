import Foundation

struct Category: Identifiable {
    let id: String
    let categoryType: String
    let name: String
    let subcategories: [String]
    let thumbnail: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.categoryType = data["categoryType"] as? String ?? ""
        self.name = data["name"] as? String ?? ""
        self.subcategories = data["subcategories"] as? [String] ?? []
        self.thumbnail = data["thumbnail"] as? String ?? ""
    }
} 
