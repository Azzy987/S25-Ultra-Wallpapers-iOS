//
//  FilterLockManager.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import Foundation
import SwiftUI

class FilterLockManager: ObservableObject {
    static let shared = FilterLockManager()
    
    @Published var unlockedFilters: Set<String> = []
    
    private let userDefaults = UserDefaults.standard
    private let unlockedFiltersKey = "unlocked_wallpaper_filters"
    
    // First 5 filters are free by default (including noFilter which is always free)
    private let freeFilterIndexes = Set([0, 1, 2, 3, 4])
    
    private init() {
        loadUnlockedFilters()
    }
    
    // MARK: - Filter Management
    
    @MainActor 
    func isFilterUnlocked(_ filter: WallpaperFilter, for wallpaperId: String) -> Bool {
        // Premium users have all filters unlocked
        if UserManager.shared.isPremium {
            return true
        }
        
        // noFilter is always free
        if filter == .noFilter {
            return true
        }
        
        // Get filter index in the enum cases array
        let allFilters = WallpaperFilter.allCases
        guard let filterIndex = allFilters.firstIndex(of: filter) else {
            return false
        }
        
        // First 5 filters (indexes 0-4) are free by default
        if freeFilterIndexes.contains(filterIndex) {
            return true
        }
        
        // Check if filter is unlocked for this wallpaper via reward ads
        let wallpaperKey = "\(wallpaperId)_\(filter.rawValue)"
        return unlockedFilters.contains(wallpaperKey)
    }
    
    func unlockAllFiltersForWallpaper(_ wallpaperId: String) {
        let allFilters = WallpaperFilter.allCases
        for (index, filter) in allFilters.enumerated() {
            // Skip already free filters
            if !freeFilterIndexes.contains(index) && filter != .noFilter {
                let wallpaperKey = "\(wallpaperId)_\(filter.rawValue)"
                unlockedFilters.insert(wallpaperKey)
            }
        }
        saveUnlockedFilters()
        print("🔓 All filters unlocked for wallpaper: \(wallpaperId)")
    }
    
    @MainActor 
    func getLockedFilters(for wallpaperId: String) -> [WallpaperFilter] {
        return WallpaperFilter.allCases.filter { !isFilterUnlocked($0, for: wallpaperId) }
    }
    
    @MainActor 
    func getUnlockedFilters(for wallpaperId: String) -> [WallpaperFilter] {
        return WallpaperFilter.allCases.filter { isFilterUnlocked($0, for: wallpaperId) }
    }
    
    func getFilterIcon(_ filter: WallpaperFilter) -> String {
        switch filter {
        case .noFilter: return "photo"
        case .addictiveBlue: return "drop.fill"
        case .addictiveRed: return "flame.fill"
        case .aden: return "sun.max"
        case .brooklyn: return "building.2.fill"
        case .earlybird: return "bird.fill"
        case .gingham: return "grid"
        case .hudson: return "water.waves"
        case .inkwell: return "pencil.and.outline"
        case .lark: return "bird"
        case .lofi: return "waveform"
        case .maven: return "star.fill"
        case .mayfair: return "sparkles"
        case .moon: return "moon.fill"
        case .perpetua: return "infinity"
        case .reyes: return "crown.fill"
        case .rise: return "sunrise.fill"
        case .slumber: return "moon.stars.fill"
        case .stinson: return "mountain.2.fill"
        case .toaster: return "oven.fill"
        case .valencia: return "leaf.fill"
        case .walden: return "tree.fill"
        case .willow: return "wind"
        case .xpro2: return "camera.filters"
        case .crema: return "cup.and.saucer.fill"
        case .ludwig: return "paintbrush.fill"
        case .sierra: return "triangle.fill"
        case .skyline: return "building.columns.fill"
        case .dogpatch: return "pawprint.fill"
        case .vesper: return "star.circle.fill"
        case .amaro: return "heart.fill"
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadUnlockedFilters() {
        if let data = userDefaults.data(forKey: unlockedFiltersKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlockedFilters = decoded
        }
        print("🔓 Loaded \(unlockedFilters.count) unlocked filters")
    }
    
    private func saveUnlockedFilters() {
        if let encoded = try? JSONEncoder().encode(unlockedFilters) {
            userDefaults.set(encoded, forKey: unlockedFiltersKey)
        }
        print("🔓 Saved \(unlockedFilters.count) unlocked filters")
    }
    
    // MARK: - Stats and Debug
    
    @MainActor 
    func getFilterStats(for wallpaperId: String) -> String {
        let unlocked = getUnlockedFilters(for: wallpaperId).count
        let total = WallpaperFilter.allCases.count
        return "🔓 Filters: \(unlocked)/\(total) unlocked for wallpaper \(wallpaperId)"
    }
    
    func clearAllUnlockedFilters() {
        unlockedFilters.removeAll()
        userDefaults.removeObject(forKey: unlockedFiltersKey)
        print("🔓 Cleared all unlocked filters")
    }
}
