import Foundation
import FirebaseFirestore

struct Wallpaper: Identifiable {
    let id: String
    let data: [String: Any]
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.data = data
    }
    
    var wallpaperName: String {
        data["wallpaperName"] as? String ?? ""
    }
    
    var thumbnail: String {
        data["thumbnail"] as? String ?? ""
    }
    
    var imageUrl: String {
        data["imageUrl"] as? String ?? ""
    }
    
    var category: String {
        data["category"] as? String ?? ""
    }
    
    var tags: [String] {
        data["tags"] as? [String] ?? []
    }
    
    var colors: [String] {
        data["colors"] as? [String] ?? []
    }
    
    var timestamp: Date {
        if let timestamp = data["timestamp"] as? Timestamp {
            return timestamp.dateValue()
        } else {
            return Date()
        }
    }
    
    var dimensions: String {
        data["dimensions"] as? String ?? ""
    }
    
    var size: String {
        data["size"] as? String ?? ""
    }
    
    var source: String {
        data["source"] as? String ?? ""
    }
    
    var downloads: Int {
        data["downloads"] as? Int ?? 0
    }
    
    var views: Int {
        data["views"] as? Int ?? 0
    }
    
    var exclusive: Bool {
        data["exclusive"] as? Bool ?? false
    }
    
    // Samsung Collection specific fields
    var launchYear: Int {
        data["launchYear"] as? Int ?? 0
    }
    
    var series: String {
        data["series"] as? String ?? ""
    }
    
    // TrendingWallpapers Collection specific fields
    var depthEffect: Bool {
        data["depthEffect"] as? Bool ?? false
    }
    
    var subCategory: String {
        data["subCategory"] as? String ?? ""
    }
    
    var documentReference: DocumentReference? {
        // Add DocumentReference
        nil
    }
}
