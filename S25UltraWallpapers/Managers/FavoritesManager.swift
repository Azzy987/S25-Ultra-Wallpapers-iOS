import Foundation
import CoreData
import SwiftUI

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    @Published private(set) var favorites: [Wallpaper] = []
    private let coreDataManager = CoreDataManager.shared
    private var favoriteEntities: [FavoriteWallpaper] = []
    
    var favoriteWallpapers: [Wallpaper] {
        favorites
    }
    
    private init() {
        fetchFavorites()
    }
    
    func fetchFavorites() {
        let request = FavoriteWallpaper.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteWallpaper.timestamp, ascending: false)]
        
        do {
            favoriteEntities = try coreDataManager.container.viewContext.fetch(request)
            favorites = favoriteEntities.map { favorite in
                let data: [String: Any] = [
                    "wallpaperName": favorite.wallpaperName ?? "",
                    "thumbnail": favorite.thumbnail ?? "",
                    "imageUrl": favorite.imageUrl ?? "",
                    "timestamp": favorite.timestamp ?? Date(),
                    "category": [],
                    "colors": [],
                    "tags": [],
                    "views": 0
                ]
                return Wallpaper(id: favorite.id ?? "", data: data)
            }
        } catch {
            print("Failed to fetch favorites: \(error)")
        }
    }
    
    func toggleFavorite(wallpaper: Wallpaper) -> Bool {
        if isFavorite(wallpaper.id) {
            removeFavorite(wallpaper.id)
            return false
        } else {
            addFavorite(wallpaper)
            return true
        }
    }
    
    private func addFavorite(_ wallpaper: Wallpaper) {
        let context = coreDataManager.container.viewContext
        let favorite = FavoriteWallpaper(context: context)
        
        favorite.id = wallpaper.id
        favorite.wallpaperName = wallpaper.wallpaperName
        favorite.thumbnail = wallpaper.thumbnail
        favorite.imageUrl = wallpaper.imageUrl
        favorite.timestamp = Date()
        
        do {
            try context.save()
            fetchFavorites()
        } catch {
            print("Failed to save favorite: \(error)")
        }
    }
    
    private func removeFavorite(_ id: String) {
        let context = coreDataManager.container.viewContext
        
        if let favorite = favoriteEntities.first(where: { $0.id == id }) {
            context.delete(favorite)
            
            do {
                try context.save()
                fetchFavorites()
            } catch {
                print("Failed to remove favorite: \(error)")
            }
        }
    }
    
    func isFavorite(_ id: String) -> Bool {
        favorites.contains { $0.id == id }
    }
} 
