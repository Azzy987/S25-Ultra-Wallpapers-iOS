import SwiftUI

struct CachedAsyncImage<Content>: View where Content: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncImagePhase) -> Content
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    var body: some View {
        if let cached = ImageCache.shared[url] {
            content(.success(cached))
        } else {
            AsyncImage(
                url: url,
                scale: scale,
                transaction: transaction
            ) { phase in
                cacheAndRender(phase: phase)
            }
        }
    }
    
    func cacheAndRender(phase: AsyncImagePhase) -> some View {
        if case .success(let image) = phase {
            ImageCache.shared[url] = image
        }
        return content(phase)
    }
}

// Improved ImageCache with memory management
class ImageCache {
    static let shared = ImageCache()
    
    private var cache: NSCache<NSURL, AnyObject> = NSCache()
    private let maxMemoryUsage: Int = 100 * 1024 * 1024 // 100MB for better caching
    private let maxItemCount: Int = 200 // More items for category thumbnails
    
    private init() {
        cache.totalCostLimit = maxMemoryUsage
        cache.countLimit = maxItemCount
        
        // Clear cache when receiving memory warning
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    subscript(url: URL?) -> Image? {
        get {
            guard let url = url else { return nil }
            return cache.object(forKey: url as NSURL) as? Image
        }
        set {
            guard let url = url else { return }
            if let image = newValue {
                // Estimate memory cost based on image size
                let cost = estimateImageMemoryCost(image)
                cache.setObject(image as AnyObject, forKey: url as NSURL, cost: cost)
            } else {
                cache.removeObject(forKey: url as NSURL)
            }
        }
    }
    
    @objc private func clearCache() {
        cache.removeAllObjects()
    }
    
    private func estimateImageMemoryCost(_ image: Image) -> Int {
        // Better estimation based on typical category thumbnail sizes
        // Category thumbnails are usually smaller, estimate ~100KB
        return 100 * 1024
    }
    
    func removeAll() {
        cache.removeAllObjects()
    }
    
    func remove(url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
} 