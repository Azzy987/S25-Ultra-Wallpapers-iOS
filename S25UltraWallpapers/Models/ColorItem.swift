import SwiftUI
struct ColorItem: Identifiable {
    let id: String
    let name: String
    var count: Int
    
    init(name: String, count: Int = 0) {
        self.id = UUID().uuidString
        self.name = name
        self.count = count
    }
} 
