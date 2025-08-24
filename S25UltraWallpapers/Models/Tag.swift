import Foundation

struct Tag: Identifiable {
    let id: String
    let name: String
    var count: Int // Number of wallpapers with this tag
    
    init(name: String, count: Int = 0) {
        self.id = UUID().uuidString
        self.name = name
        self.count = count
    }
} 