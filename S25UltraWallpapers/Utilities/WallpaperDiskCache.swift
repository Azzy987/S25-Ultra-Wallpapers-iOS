import Foundation

// MARK: - Codable Wallpaper for disk cache

struct CachedWallpaper: Codable {
    let id: String
    let wallpaperName: String
    let thumbnail: String
    let imageUrl: String
    let category: String
    let subCategory: String
    let tags: [String]
    let colors: [String]
    let series: String
    let launchYear: Int
    let exclusive: Bool
    let depthEffect: Bool
    let source: String
    let dimensions: String
    let size: String
    let downloads: Int
    let views: Int

    init(from wallpaper: Wallpaper) {
        id = wallpaper.id
        wallpaperName = wallpaper.wallpaperName
        thumbnail = wallpaper.thumbnail
        imageUrl = wallpaper.imageUrl
        category = wallpaper.category
        subCategory = wallpaper.subCategory
        tags = wallpaper.tags
        colors = wallpaper.colors
        series = wallpaper.series
        launchYear = wallpaper.launchYear
        exclusive = wallpaper.exclusive
        depthEffect = wallpaper.depthEffect
        source = wallpaper.source
        dimensions = wallpaper.dimensions
        size = wallpaper.size
        downloads = wallpaper.downloads
        views = wallpaper.views
    }

    func toWallpaper() -> Wallpaper {
        var data: [String: Any] = [
            "wallpaperName": wallpaperName,
            "thumbnail": thumbnail,
            "imageUrl": imageUrl,
            "category": category,
            "subCategory": subCategory,
            "tags": tags,
            "colors": colors,
            "series": series,
            "launchYear": launchYear,
            "exclusive": exclusive,
            "depthEffect": depthEffect,
            "source": source,
            "dimensions": dimensions,
            "size": size,
            "downloads": downloads,
            "views": views
        ]
        return Wallpaper(id: id, data: data)
    }
}

// MARK: - WallpaperDiskCache

final class WallpaperDiskCache {
    static let shared = WallpaperDiskCache()

    private let queue = DispatchQueue(label: "com.app.wallpaperdiskcache", qos: .utility)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    // MARK: - Public API

    func save(_ wallpapers: [Wallpaper], forKey key: String) {
        let cached = wallpapers.map { CachedWallpaper(from: $0) }
        queue.async { [weak self] in
            guard let self = self else { return }
            guard let url = self.fileURL(for: key) else { return }
            do {
                let data = try self.encoder.encode(cached)
                try data.write(to: url, options: .atomic)
            } catch {
                print("⚠️ WallpaperDiskCache: failed to save '\(key)': \(error)")
            }
        }
    }

    /// Load synchronously (call from background thread only).
    func load(forKey key: String) -> [Wallpaper]? {
        guard let url = fileURL(for: key) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let cached = try? decoder.decode([CachedWallpaper].self, from: data) else { return nil }
        return cached.map { $0.toWallpaper() }
    }

    /// Load asynchronously and deliver on main thread.
    func loadAsync(forKey key: String, completion: @escaping ([Wallpaper]?) -> Void) {
        queue.async { [weak self] in
            let result = self?.load(forKey: key)
            DispatchQueue.main.async { completion(result) }
        }
    }

    func clear(forKey key: String) {
        queue.async { [weak self] in
            guard let url = self?.fileURL(for: key) else { return }
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Private

    private func fileURL(for key: String) -> URL? {
        guard let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        // Sanitize key to a safe filename
        let safeName = key.replacingOccurrences(of: "/", with: "_")
        return caches.appendingPathComponent("wallpaper_cache_\(safeName).json")
    }
}

// MARK: - Cache Keys

extension WallpaperDiskCache {
    static let homeKey = "home_wallpapers"
    static let trendingKey = "trending_wallpapers"
    static let categoriesKey = "categories_wallpapers"
}
