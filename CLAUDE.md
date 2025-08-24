# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

S25UltraWallpapers is an iOS wallpaper application built with SwiftUI and Firebase. Despite the name "Android" in the README (legacy reference), this is a native iOS app featuring Samsung Galaxy wallpapers, trending collections, and wallpaper customization.

## Development Commands

### Building and Testing
```bash
# Open the project in Xcode
open S25UltraWallpapers.xcodeproj

# Build the project
xcodebuild -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -configuration Debug build

# Run tests
xcodebuild test -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Xcode Workspace
- Main project: `S25UltraWallpapers.xcodeproj`
- Package dependencies managed via Swift Package Manager (see `Package.resolved`)
- GoogleService-Info.plist required for Firebase integration

## Architecture Overview

### Tech Stack
- **Language**: Swift 5+
- **UI Framework**: SwiftUI (iOS 16+)
- **Architecture**: MVVM with ObservableObject patterns
- **Backend**: Firebase (Firestore, Analytics, Auth, Remote Config)
- **Database**: Core Data (local) + Firebase Firestore (cloud)
- **Dependency Injection**: Manual singleton pattern with shared instances
- **State Management**: SwiftUI @StateObject/@ObservableObject with shared managers

### Core Design Patterns

1. **Manager Pattern**: Centralized singletons for Firebase, CoreData, Favorites, and Theme management
2. **Shared State Objects**: TabManager, HomeScreenState, TrendingScreenState for cross-component communication
3. **Environment Objects**: Theme and managers injected via SwiftUI environment system
4. **Data Models**: Firestore document-based models with computed properties

### Key Managers

- **FirebaseManager**: Handles all Firebase operations, wallpaper fetching, and cloud data
- **CoreDataManager**: Local database management using NSPersistentContainer
- **FavoritesManager**: User favorites synchronization (local + cloud)
- **ThemeManager**: App-wide theming with light/dark/system mode support
- **TabManager**: Centralized tab navigation state management

## Project Structure

```
S25UltraWallpapers/
├── Components/           # Reusable UI components (CarouselCardView, FilterButton, etc.)
├── CoreData/            # Core Data model files (.xcdatamodeld)
├── Extensions/          # Swift extensions for Array, Color, Image, View
├── Managers/            # Singleton manager classes
├── Models/              # Data models (Wallpaper, Banner, Category, etc.)
├── Screens/             # Main screen views and tab screens
│   └── Tabs/           # Individual tab screen implementations
├── Theme/               # App theming system (Fonts, Theme)
├── Utilities/           # Helper utilities (image caching, filtering, etc.)
├── Views/               # Reusable view components
└── WallsApp.swift      # App entry point and configuration
```

### Firebase Collections Structure

- **Samsung**: Main wallpaper collection (series, launchYear, timestamp)
- **TrendingWallpapers**: Curated trending content (category, depthEffect, exclusive)
- **Categories**: Wallpaper categorization (name, subcategories, thumbnail)
- **Banners**: Home screen promotional banners
- **S25UltraWallpapersUsers**: User data and favorites sync

### Navigation Flow

1. **MainTabView**: Central tab navigation with 4 tabs (Home, Categories, Trending, Favorites)
2. **Tab Screens**: Individual content screens with dedicated state management
3. **Detail Screens**: WallpaperDetailScreen, EditWallpaperScreen, WallpaperPreviewScreen
4. **Settings**: Full-screen modal for user account and app settings

## Key Components

### WallpaperCard
Reusable grid component used throughout the app for displaying wallpapers with:
- Shimmer loading effects
- Material Design styling
- Premium/exclusive content badges
- Touch feedback and navigation

### Data Flow
1. **App Launch**: WallsApp.swift initializes Firebase and managers
2. **Firebase Init**: FirebaseManager.shared.initialize() loads home data
3. **State Management**: Shared managers provide @Published properties to views
4. **Tab Navigation**: TabManager coordinates active tab state across components

## Development Guidelines

### Firebase Integration
- All Firebase operations go through FirebaseManager.shared
- Firestore queries use proper error handling and completion callbacks
- Network-first caching enabled for better performance

### State Management
- Use shared manager instances for cross-component state
- Follow SwiftUI @StateObject/@ObservableObject patterns
- Environment objects for theme and manager injection

### UI/UX Patterns
- Material Design 3 components and theming
- Consistent spacing and typography via Theme system
- Loading states with shimmer effects
- Circular tab navigation with gesture support

### Data Models
- Firestore document-based with dictionary data access
- Computed properties for safe data extraction
- Proper timestamp and type conversion handling

## Testing

- Unit tests: `S25UltraWallpapersTests/`
- UI tests: `S25UltraWallpapersUITests/`
- Run tests through Xcode or xcodebuild command

## Dependencies

### Firebase
- FirebaseCore, FirebaseAuth, FirebaseFirestore
- FirebaseAnalytics, FirebaseRemoteConfig
- GoogleMobileAds for ad integration

### Apple Frameworks
- SwiftUI for UI
- CoreData for local storage
- Core Graphics/UIKit for image operations

All dependencies are managed via Swift Package Manager and configured in the Xcode project.