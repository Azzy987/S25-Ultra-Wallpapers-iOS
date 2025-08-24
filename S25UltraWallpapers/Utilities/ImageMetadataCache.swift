import UIKit
import Foundation

struct ImageMetadata {
    let dimensions: String
    let size: String
    let width: Int
    let height: Int
    let fileSize: Int64
    
    init(width: Int, height: Int, fileSize: Int64) {
        self.width = width
        self.height = height
        self.fileSize = fileSize
        self.dimensions = "\(width) × \(height)"
        self.size = ImageMetadata.formatFileSize(fileSize)
    }
    
    private static func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

class ImageMetadataCache {
    static let shared = ImageMetadataCache()
    
    private var cache: [String: ImageMetadata] = [:]
    private let queue = DispatchQueue(label: "ImageMetadataCache", qos: .utility)
    private var activeRequests: Set<String> = []
    
    private init() {}
    
    func getMetadata(for url: String, completion: @escaping (ImageMetadata?) -> Void) {
        queue.async {
            // Check if already cached
            if let cached = self.cache[url] {
                DispatchQueue.main.async {
                    completion(cached)
                }
                return
            }
            
            // Check if request is already in progress
            if self.activeRequests.contains(url) {
                // Wait a bit and try again
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.getMetadata(for: url, completion: completion)
                }
                return
            }
            
            // Start new request
            self.activeRequests.insert(url)
            
            self.calculateImageMetadata(url: url) { metadata in
                self.queue.async {
                    self.activeRequests.remove(url)
                    
                    if let metadata = metadata {
                        self.cache[url] = metadata
                    }
                    
                    DispatchQueue.main.async {
                        completion(metadata)
                    }
                }
            }
        }
    }
    
    private func calculateImageMetadata(url: String, completion: @escaping (ImageMetadata?) -> Void) {
        guard let imageURL = URL(string: url) else {
            completion(nil)
            return
        }
        
        // First try to get file size from HTTP HEAD request
        var request = URLRequest(url: imageURL)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            let fileSize = (response as? HTTPURLResponse)?.expectedContentLength ?? -1
            
            // Now get image dimensions by downloading image data
            self.downloadAndAnalyzeImage(url: imageURL, expectedSize: fileSize) { metadata in
                completion(metadata)
            }
        }.resume()
    }
    
    private func downloadAndAnalyzeImage(url: URL, expectedSize: Int64, completion: @escaping (ImageMetadata?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            // Get actual file size
            let actualSize = expectedSize > 0 ? expectedSize : Int64(data.count)
            
            // Create image source to get dimensions without loading full image
            guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
                completion(nil)
                return
            }
            
            guard let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
                  let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
                completion(nil)
                return
            }
            
            let metadata = ImageMetadata(width: width, height: height, fileSize: actualSize)
            completion(metadata)
            
        }.resume()
    }
    
    // Clear cache when app goes to background or terminates
    func clearCache() {
        queue.async {
            self.cache.removeAll()
            self.activeRequests.removeAll()
        }
    }
    
    // Get cached metadata synchronously (returns nil if not cached)
    func getCachedMetadata(for url: String) -> ImageMetadata? {
        return queue.sync {
            return cache[url]
        }
    }
}

// Extension to register for app lifecycle notifications
extension ImageMetadataCache {
    func registerForAppLifecycleNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.clearCache()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.clearCache()
        }
    }
}