# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

S25UltraWallpapers is an iOS wallpaper application built with SwiftUI and Firebase. This is a native iOS app featuring Samsung Galaxy wallpapers, trending collections, and wallpaper customization with a freemium monetization model.

## Development Commands

### Building and Testing

```bash
# Open the project in Xcode
open S25UltraWallpapers.xcodeproj

# Build the project from command line
xcodebuild -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -configuration Debug build

# Build for Release
xcodebuild -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -configuration Release build

# Run unit tests
xcodebuild test -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test target
xcodebuild test -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:S25UltraWallpapersTests

# Run UI tests
xcodebuild test -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:S25UltraWallpapersUITests

# Clean build folder
xcodebuild clean -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers

# Archive for distribution
xcodebuild archive -project S25UltraWallpapers.xcodeproj -scheme S25UltraWallpapers -archivePath ./build/S25UltraWallpapers.xcarchive
```

### Development Workflow

```bash
# Check current git status
git status

# View recent commits
git --no-pager log --oneline -10

# Create feature branch
git checkout -b feature/new-feature

# Check Xcode project file changes (be careful with these)
git diff S25UltraWallpapers.xcodeproj/project.pbxproj

# View Swift Package dependencies
cat S25UltraWallpapers.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

## Architecture Overview

### Technology Stack
- **Language**: Swift 5+
- **UI Framework**: SwiftUI (iOS 16+)
- **Architecture Pattern**: MVVM with ObservableObject
- **Backend**: Firebase (Firestore, Analytics, Auth, Remote Config)
- **Database**: Core Data (local) + Firebase Firestore (cloud)
- **Dependency Management**: Swift Package Manager
- **Authentication**: Google Sign-In
- **Ads**: Google Mobile Ads

### Core Architecture Patterns

**Manager Pattern**: Centralized singleton managers handle business logic and state management:
- `FirebaseManager.shared`: All Firebase operations, wallpaper fetching, cloud data
- `CoreDataManager.shared`: Local database management using NSPersistentContainer
- `FavoritesManager.shared`: User favorites synchronization (local + cloud)
- `ThemeManager.shared`: App-wide theming with light/dark mode support
- `TabManager.shared`: Centralized tab navigation state management
- `UserManager.shared`: User authentication and profile management

**State Management**: SwiftUI-native approach with shared ObservableObject instances injected via environment, enabling cross-component communication through @Published properties.

**Navigation Architecture**: Custom circular tab navigation with gesture support, implemented through MainTabView with horizontal scrolling between 4 main tabs (Home, Categories, Trending, Favorites).

### Key Components

**WallpaperCard**: Reusable grid component used throughout the app for displaying wallpapers with shimmer loading effects, Material Design styling, premium/exclusive content badges, and touch feedback.

**Firebase Collections Structure**:
- `Samsung`: Main wallpaper collection (series, launchYear, timestamp)
- `TrendingWallpapers`: Curated trending content (category, depthEffect, exclusive)
- `Categories`: Wallpaper categorization (name, subcategories, thumbnail)
- `Banners`: Home screen promotional banners
- `S25UltraWallpapersUsers`: User data and favorites sync

### Data Flow

1. **App Launch**: `WallsApp.swift` initializes Firebase and managers
2. **Firebase Initialization**: `FirebaseManager.shared.initialize()` loads home data
3. **State Management**: Shared managers provide @Published properties to views
4. **Tab Navigation**: `TabManager` coordinates active tab state across components
5. **User Authentication**: Google Sign-In integration with `UserManager`
6. **Favorites Sync**: Local Core Data + cloud Firebase for premium users

## Project Structure

```
S25UltraWallpapers/
├── Components/           # Reusable UI components (CarouselCardView, FilterButton, etc.)
├── CoreData/            # Core Data model files (.xcdatamodeld)
├── Extensions/          # Swift extensions for Array, Color, Image, View
├── Managers/            # Business logic singleton managers
├── Models/              # Data models (Wallpaper, Banner, Category, etc.)
├── Screens/             # Main screen views and tab screens
│   └── Tabs/           # Individual tab screen implementations
├── Theme/               # App theming system (Fonts, Theme definitions)
├── Utilities/           # Helper utilities (image caching, filtering, etc.)
├── Views/               # Reusable view components and MainTabView
└── WallsApp.swift      # App entry point and configuration
```

### Screen Flow
- **MainTabView**: Central 4-tab navigation (Home, Categories, Trending, Favorites)
- **Screen Hierarchy**: Tab Screens → Detail Screens → Modal Screens (Settings, Premium)
- **Navigation States**: Each tab maintains its own state through dedicated managers/ViewModels

## Development Guidelines

### Firebase Integration
- All Firebase operations go through `FirebaseManager.shared`
- Firestore queries use proper error handling and completion callbacks
- Network-first caching enabled with optimized memory cache settings
- Authentication state handled through `UserManager.shared`

### State Management Best Practices
- Use shared manager instances for cross-component state
- Follow SwiftUI @StateObject/@ObservableObject patterns
- Environment objects for theme and manager injection
- Avoid direct Core Data access outside of `CoreDataManager`

### UI/UX Implementation
- Material Design 3 principles with custom theming
- Consistent spacing and typography via Theme system
- Loading states with shimmer effects throughout the app
- Circular tab navigation with gesture support
- Custom drag gesture handling that respects vertical vs horizontal scrolling

### Data Models
- Firestore document-based models with dictionary data access
- Computed properties for safe data extraction from Firebase documents
- Proper timestamp and type conversion handling
- Core Data models for local favorites storage

### Premium/Monetization Features
- Freemium model with ad-supported free tier
- Premium subscription removes ads and unlocks exclusive content
- Google Mobile Ads integration for interstitial and reward ads
- Cloud sync for premium users' favorites

## Common Development Tasks

### Adding New Wallpaper Features
1. Update Firestore collection structure if needed
2. Modify corresponding data model in `Models/`
3. Update `FirebaseManager` fetch methods
4. Implement UI changes in appropriate screen/component
5. Test with both free and premium user states

### Modifying Tab Navigation
- Core navigation logic is in `Views/MainTabView.swift`
- Tab state managed by `TabManager.shared`
- Circular navigation implemented with extra tabs at indices -1 and 4
- Gesture handling differentiates between horizontal tab swipes and vertical content scrolls

### Working with Firebase Data
- All queries go through `FirebaseManager.shared`
- Use completion callbacks for async operations
- Implement proper loading states with `isLoading` @Published property
- Handle offline scenarios gracefully

### Theme and Styling
- App-wide theming through `ThemeManager.shared`
- Custom environment key `\.appTheme` for consistent theming
- Material Design 3 color system implementation
- Support for light/dark modes (system theme was intentionally removed)
