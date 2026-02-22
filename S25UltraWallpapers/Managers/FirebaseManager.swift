import SwiftUI
import Firebase
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    
    @Published var wallpapers: [Wallpaper] = []
    @Published var banners: [Banner] = []
    @Published var categories: [Category] = []
    @Published var trendingWallpapers: [Wallpaper] = []
    @Published private(set) var tags: [Tag] = []
    @Published private(set) var colors: [ColorItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isInitialized = false
    
    private init() {
        // Configure Firestore settings BEFORE accessing the instance
        let settings = FirestoreSettings()
        settings.cacheSettings = MemoryCacheSettings(garbageCollectorSettings: MemoryLRUGCSettings())
        settings.isSSLEnabled = true
        Firestore.firestore().settings = settings

        // Enable network first for faster loading
        Firestore.firestore().enableNetwork { error in
            if let error = error {
                print("❌ Firebase network error: \(error)")
            } else {
            }
        }
    }
    
    func initialize() {
        fetchHomeData()
    }
    
    func fetchHomeData() {
        guard wallpapers.isEmpty else { return }
        isLoading = true
        
        let group = DispatchGroup()
        
        group.enter()
        fetchWallpapers {
            group.leave()
        }
        
        group.enter()
        fetchBanners {
            group.leave()
        }
        
        group.enter()
        fetchTrendingWallpapers {
            group.leave()
        }
        
        group.enter()
        fetchTags {
            group.leave()
        }
        
        group.enter()
        fetchColors {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
            self.isInitialized = true
        }
    }
    
    private func fetchWallpapers(completion: @escaping () -> Void = {}) {
        db.collection("Samsung")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching wallpapers: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.wallpapers = snapshot?.documents.map { doc in
                        Wallpaper(id: doc.documentID, data: doc.data())
                    } ?? []
                    
                    completion()
                }
            }
    }
    
    func fetchBanners(completion: @escaping () -> Void = {}) {
        db.collection("Banners")
            .document("SamsungWallpapers")
            .collection("S25UltraWallpapersBanners")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error fetching banners: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.banners = snapshot?.documents.map { doc in
                        return Banner(id: doc.documentID, data: doc.data())
                    } ?? []
                    
                    completion()
                }
            }
    }
    
    func fetchCategories() {
        db.collection("Categories").getDocuments { snapshot, error in
            if let error = error {
                print("❌ Error fetching categories: \(error)")
                return
            }
            
            DispatchQueue.main.async {
                self.categories = snapshot?.documents.map { doc in
                    Category(id: doc.documentID, data: doc.data())
                } ?? []
            }
        }
    }
    
    func fetchTrendingWallpapers(limit: Int = 20, completion: @escaping () -> Void = {}) {
        db.collection("TrendingWallpapers")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching trending wallpapers: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.trendingWallpapers = snapshot?.documents.map { doc in
                        Wallpaper(id: doc.documentID, data: doc.data())
                    } ?? []
                    completion()
                }
            }
    }
    
    func fetchTags(completion: @escaping () -> Void = {}) {
        let db = Firestore.firestore()
        db.collection("Samsung").getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            var tagCount: [String: Int] = [:]
            
            // Count occurrences of each tag
            for document in documents {
                if let tags = document.data()["tags"] as? [String] {
                    for tag in tags {
                        tagCount[tag, default: 0] += 1
                    }
                }
            }
            
            // Convert to Tag objects and sort by count
            let sortedTags = tagCount.map { Tag(name: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
            
            DispatchQueue.main.async {
                self?.tags = sortedTags
                completion()
            }
        }
    }
    
    // Add this function to cache colors
    private var cachedColors: [String] = []
    
    func getAllColors() -> [String] {
        if cachedColors.isEmpty {
            cachedColors = Array(Set(wallpapers.flatMap { $0.colors })).sorted()
        }
        return cachedColors
    }
    
    func fetchColors(completion: @escaping () -> Void = {}) {
        db.collection("Samsung").getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            var colorCount: [String: Int] = [:]
            
            // Count occurrences of each color
            for document in documents {
                if let colors = document.data()["colors"] as? [String] {
                    for color in colors {
                        colorCount[color, default: 0] += 1
                    }
                }
            }
            
            // Convert to ColorItem objects and sort by count
            let sortedColors = colorCount.map { ColorItem(name: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
            
            DispatchQueue.main.async {
                self?.colors = sortedColors
                completion()
            }
        }
    }
    
    /// Fetches a specific wallpaper by ID from a given collection
    /// Used for instant navigation from banner taps
    func fetchWallpaperById(_ id: String, collection: String) async throws -> Wallpaper {
        let document = try await db.collection(collection).document(id).getDocument()
        
        guard document.exists, let data = document.data() else {
            throw NSError(
                domain: "FirebaseManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Wallpaper not found in \(collection)"]
            )
        }
        
        return Wallpaper(id: document.documentID, data: data)
    }

}
