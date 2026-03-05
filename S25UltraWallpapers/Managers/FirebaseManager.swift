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
    @Published private(set) var isLoading = false
    @Published private(set) var isInitialized = false
    
    private init() {
        // Configure Firestore settings BEFORE accessing the instance
        // Use persistent disk cache so wallpapers load instantly on subsequent launches
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 50 * 1024 * 1024 as NSNumber) // 50MB disk cache
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
                    DispatchQueue.main.async { completion() }
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
                    DispatchQueue.main.async { completion() }
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
                    DispatchQueue.main.async { completion() }
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
    
    /// Fetches a specific wallpaper by ID from a given collection.
    /// Tries the local Firestore cache first for instant response, then falls back to server.
    func fetchWallpaperById(_ id: String, collection: String) async throws -> Wallpaper {
        let ref = db.collection(collection).document(id)

        // Try cache first — instant if the document was fetched before
        if let cached = try? await ref.getDocument(source: .cache),
           cached.exists,
           let data = cached.data() {
            return Wallpaper(id: cached.documentID, data: data)
        }

        // Cache miss — fetch from server
        let document = try await ref.getDocument(source: .server)

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
