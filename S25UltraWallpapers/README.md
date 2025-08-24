# S25UltraWallpapers

A premium Android wallpaper application built with Jetpack Compose, featuring Samsung Galaxy wallpapers, trending collections, and advanced customization features.

## Features

### 🎨 Core Functionality

- **Samsung Wallpapers Collection**: Official Samsung Galaxy wallpapers organized by series and launch year
- **Trending Wallpapers**: Curated collection of popular wallpapers from various sources
- **Categories & Subcategories**: Organized wallpaper browsing with filterable subcategories
- **Favorites Management**: Local and cloud-synced favorites with premium synchronization
- **Advanced Wallpaper Editor**: Built-in editing tools with filters and customization options

### 🔐 User Experience

- **Freemium Model**: Free access with ads, premium subscription removes ads and unlocks exclusive content
- **Onboarding Flow**: Guided setup with storage and notification permissions
- **Premium Subscription**: Monthly, yearly, and lifetime subscription options
- **Google Sign-In Integration**: Seamless authentication with Google services
- **Offline Support**: Local database storage using Room for favorites
- **Auto-Update**: Mandatory and optional update mechanisms

### 📱 User Interface

- **Modern Material Design**: Built with Material 3 components and Jetpack Compose
- **Freemium Monetization**: Ad-supported free tier with premium upgrade options
- **Tabbed Navigation**: Home, Categories, Trending, and Favorites tabs
- **Banner Carousel**: Auto-scrolling promotional banners on home screen
- **Grid Layout**: Optimized wallpaper browsing with pagination
- **Detail View**: Full-screen preview with vertical swipe navigation
- **Bottom Sheet**: Collapsible info container with wallpaper actions

### 🛠️ Technical Features

- **Firebase Backend**: Firestore database with real-time synchronization
- **Image Optimization**: Thumbnail and high-resolution image loading with Coil
- **WallpaperCard Component**: Reusable grid card with shimmer loading effects
- **Billing Integration**: Google Play Billing for subscription management
- **Push Notifications**: Firebase Cloud Messaging for updates
- **Color Extraction**: Dynamic theming based on wallpaper colors using Palette API

## UI Components

### WallpaperCard

A reusable component used throughout the app for displaying wallpapers in grid layouts:

**Visual Design**

- Material Design card with rounded corners and elevation
- Aspect ratio optimized for wallpaper thumbnails
- Responsive sizing based on screen dimensions

**Loading States**

- Shimmer effect animation while wallpaper thumbnail loads
- Smooth transition from shimmer to loaded image
- Error state handling with placeholder imagery

**Content Display**

- Wallpaper thumbnail with proper scaling and cropping
- Optional overlay information (name, category, premium badge)
- Interactive touch feedback with ripple effect

**Badge System**

- **Premium Badge**: Displayed on exclusive/premium wallpapers
- **Depth Badge**: Shown on wallpapers with depth effect capability
- **Lock Icon**: Visual indicator for premium-only content
- No reward ad functionality in card (handled in DetailScreen)

**Usage Locations**

- HomeTabScreen Samsung wallpapers grid
- TrendingTabScreen wallpapers grid
- CategoryScreen filtered wallpapers
- FavoritesTabScreen saved wallpapers
- Search results display

## Architecture

### Tech Stack

- **Language**: Kotlin
- **UI Framework**: Jetpack Compose
- **Architecture**: MVVM with Hilt dependency injection
- **Database**: Room (local) + Firebase Firestore (cloud)
- **Image Loading**: Coil
- **Navigation**: Navigation Compose
- **State Management**: Compose State + ViewModel

### Firebase Collections

#### Samsung Collection

```
fields:
- downloads (number)
- imageUrl (string)
- launchYear (number)
- series (string)
- thumbnail (string)
- timestamp (timestamp)
- views (number)
- wallpaperName (string)
```

#### TrendingWallpapers Collection

```
fields:
- category (string)
- depthEffect (boolean)
- downloads (number)
- exclusive (boolean)
- imageUrl (string)
- source (string)
- subCategory (string)
- thumbnail (string)
- timestamp (timestamp)
- views (number)
- wallpaperName (string)
```

#### Categories Collection

```
fields:
- categoryType (string)
- name (string)
- subcategories (array)
- thumbnail (string)
```

#### Users Collection (S25UltraWallpapersUsers)

```
fields:
- displayName (string)
- email (string)
- favorites (array)
- photoUrl (string)
- premium (boolean)
- premiumExpiry (timestamp/null)
- premiumSince (timestamp/null)
- premiumType (string/null)
```

#### Banners Collection

```
fields:
- bannerName (string)
- bannerUrl (string)
```

#### AppUpdates Collection

```
Document: S25UltraWallpapers
fields:
- mandatoryUpdate (boolean)
- version (number)
```

## App Screens

### Main Navigation Screens

#### 1. HomeTabScreen

The main landing screen featuring a dual-section layout:

**Top Section - Banner Carousel**

- Horizontally scrollable promotional banners
- Auto-scroll functionality (changes every 6 seconds)
- Tappable banners that open DetailScreen
- Banner data fetched from Banners collection
- Uses same document ID as wallpaper for seamless detail navigation

**Bottom Section - Samsung Wallpapers Grid**

- Grid layout using WallpaperCard components
- Pagination support for smooth scrolling performance
- Shimmer loading effects until thumbnails load
- Wallpaper metadata (name, series, launch year)
- Tap to open DetailScreen with full preview

**UI Elements**

- Toolbar with profile icon (left), app title (center), sort icon (right)
- Tab bar navigation at bottom
- Pull-to-refresh functionality

#### 2. CategoriesTabScreen

Category browsing interface for organized wallpaper discovery:

**Layout & Design**

- Vertical scrolling card-based layout
- Each category card displays:
  - Category thumbnail image
  - Category name overlay
  - Subcategory count indicator
  - Material Design card styling with elevation

**Functionality**

- Tap on category card navigates to CategoryScreen
- Categories fetched from Categories collection
- Dynamic loading with loading states
- Search functionality (if implemented)

**Data Structure**

- Categories with main/sub classification
- Thumbnail URLs for visual representation
- Subcategories array for filtering options

#### 3. TrendingTabScreen

Displays popular and trending wallpapers from curated collection:

**Grid Layout**

- Masonry or uniform grid using WallpaperCard components
- Pagination for performance optimization
- Shimmer loading indicators during content fetch
- Sort options (views, downloads, newest)

**Content Features**

- Wallpapers from TrendingWallpapers collection
- Category tags and source attribution
- View and download counters
- Exclusive content badges for premium wallpapers
- Reward ad integration for premium wallpaper access

**UI Elements**

- Sort icon in toolbar (same as HomeTab)
- Filter options for categories
- Infinite scroll or load more functionality

#### 4. FavoritesTabScreen

Personal collection management for saved wallpapers:

**Local Storage (HIVE)**

- Locally stored favorites using HIVE database
- Instant access without network dependency
- Wallpaper metadata cached locally

**Cloud Sync (Premium Feature)**

- Firebase synchronization for premium users
- Cross-device favorites sync
- Backup and restore functionality

**Layout**

- Grid view using WallpaperCard components with shimmer effects
- Empty state with call-to-action when no favorites
- Sort options (recently added, alphabetical)
- Bulk selection and management options

### Secondary Screens

#### 5. CategoryScreen

Dedicated screen for category-specific wallpaper browsing:

**Toolbar**

- Back navigation arrow
- Category title display
- Search icon (optional)

**Subcategory Navigation**

- Horizontal scrollable subcategory chips
- Only displayed when subcategories are available
- Filters out "None" subcategories
- Active state highlighting for selected subcategory

**Wallpaper Grid**

- Filtered wallpapers displayed using WallpaperCard components
- Firebase query updates dynamically on subcategory selection
- Shimmer loading states during query execution
- Pagination for large collections

**Functionality**

- Real-time filtering without page refresh
- Breadcrumb navigation for deep categories
- Wallpaper count display per subcategory
- Premium wallpaper identification and reward ad integration

#### 6. DetailScreen

Full-screen wallpaper preview and interaction hub:

**Loading States**

- Initial blur thumbnail display with progress indicator
- High-resolution image loading with smooth transition
- Loading overlay with download progress

**Navigation & Controls**

- Back arrow (top-left)
- Preview eye icon for WallpaperPreviewScreen navigation (top-right)
- Vertical swipe gesture for wallpaper navigation
- Smooth transitions between wallpapers

**Bottom Info Container**

- **Collapsed State**: Wallpaper name + up arrow icon
- **Expanded State**: Full wallpaper details and action buttons

**Action Buttons**

- **Download**: Save wallpaper to device storage (triggers interstitial ad)
- **Favorite**: Add/remove from favorites (local + cloud)
- **Apply**: Set as device wallpaper (triggers interstitial ad)
- **Share**: Share wallpaper via system share sheet
- **Edit**: Open EditWallpaperScreen for customization

**Premium Content Handling**

- Premium wallpapers show unlock dialog overlay on DetailScreen
- Dialog offers reward ad option to temporarily unlock wallpaper
- Unlocked state persists until app restart
- Premium subscribers bypass unlock requirement

**Ad Integration**

- Interstitial ad after 5 DetailScreen opens from grid taps
- Interstitial ad after every 5 vertical swipes between wallpapers

**Wallpaper Information**

- Wallpaper name and dimensions
- File size and format details
- Source attribution and category tags
- View and download statistics
- Upload date and series information

#### 7. WallpaperPreviewScreen

Device mockup preview screen for wallpaper visualization:

**Purpose**

- Opened by tapping the preview (eye) icon in DetailScreen
- Shows realistic device preview of how wallpaper will appear on user's device

**Layout Components**

- **Lock Screen Preview**: Wallpaper display with lock screen UI elements

  - Status bar with time, battery, signal indicators
  - Lock screen notifications overlay
  - Bottom unlock affordance
  - Proper aspect ratio for device screen

- **Home Screen Preview**: Wallpaper with home screen interface
  - App icons grid overlay
  - Dock with common apps
  - Status bar elements
  - Navigation gestures area
  - Widget placements (if applicable)

**Preview Features**

- Side-by-side or tabbed view of both screen types
- Toggle between lock screen and home screen previews
- Realistic device bezels and screen proportions
- Dynamic status bar content
- Interactive switching between preview modes

**Navigation**

- Back button to return to DetailScreen
- Share preview functionality
- Direct apply options from preview
- Wallpaper information overlay

#### 8. EditWallpaperScreen

Built-in wallpaper customization and editing interface:

**Toolbar**

- Back navigation button
- "Edit Wallpaper" title
- Save/Download action icon

**Preview Section**

- Wallpaper display with rounded corners
- Proper spacing and aspect ratio
- Real-time filter preview
- Zoom and pan capabilities

**Filter Options**

- **Free Filters (5 unlocked by default)**:

  - Basic brightness adjustment
  - Simple contrast enhancement
  - Basic color filters
  - Light blur effects
  - Standard presets

- **Premium Filters (Ad-unlock required)**:
  - Advanced saturation controls
  - Professional color grading
  - Complex blur and artistic effects
  - Image flip and rotation tools
  - Advanced brightness/contrast curves
  - Vintage and specialty filters

**Unlock Mechanism**

- Watch reward ad to unlock all premium editing features
- Unlocked state persists until app restart
- Premium subscribers get permanent access to all tools

**Action Buttons**

- **Apply**: Apply current filter settings
- **Cancel**: Discard changes and return
- Reset to original functionality

#### 9. SettingsScreen

User account management and app configuration:

**Toolbar**

- Back navigation button
- "Settings" title

**User Sign-In Card**

- Google profile information display
- Sign-in/Sign-out functionality
- Profile picture and display name
- Account status indicator

**Premium Upgrade Card**

- Current subscription status
- Premium features highlight
- "Upgrade Now" call-to-action button
- Subscription expiry information

**Settings Categories**

- **Account Settings**: Profile management, data sync
- **Download Settings**: Quality preferences, storage location
- **Notification Settings**: Push notification preferences
- **Privacy Settings**: Data usage, analytics opt-out
- **App Settings**: Theme selection, language preferences
- **About**: Version info, privacy policy, terms of service

#### 10. OnboardingScreen

First-time user setup and permission flow:

**Screen Flow**

1. **Welcome Screen**: App introduction and features overview
2. **Storage Permission**: Request storage access with explanation
3. **Notification Permission**: Request notification access for updates

**Permission Handling**

- Clear explanation of why permissions are needed
- Allow/Deny options with appropriate responses
- Fallback functionality for denied permissions
- Option to enable permissions later via settings

**Navigation**

- Next/Skip buttons for progression
- Progress indicators showing current step
- Automatic progression to MainScreen after completion

#### 11. PremiumScreen

Subscription management and purchase interface:

**Hero Section**

- Premium features showcase image
- Value proposition highlighting
- Feature comparison table

**Subscription Options**

- **Monthly Plan**: Recurring monthly billing
- **Yearly Plan**: Annual billing with discount display
- **Lifetime Plan**: One-time purchase option

**Pricing Display**

- Original prices from Play Console
- Discount percentages and savings
- Lifetime plan: ₹799 app price vs. discounted Play Store price

**Action Buttons**

- **Continue**: Proceed to purchase flow
- **Restore Purchases**: Restore previous subscriptions
- **Privacy Policy**: Link to privacy policy

**Purchase Flow Integration**

- Google Play Billing integration
- Subscription status verification
- Error handling for failed purchases
- Success confirmation and feature activation

## Monetization Model

### Freemium Structure

The app operates on a freemium model with ad-supported free tier and premium subscription options.

### Advertisement Integration

#### Interstitial Ads

Displayed at strategic user interaction points:

- **After Wallpaper Setting**: Shown when user applies wallpaper to device
- **After Wallpaper Download**: Displayed upon successful wallpaper download
- **DetailScreen Vertical Swipe**: Triggered after every 5 wallpaper swipes in detail view
- **DetailScreen Access**: Shown after user opens DetailScreen 5 times by tapping wallpapers in grid

#### Reward Ads

Used for premium content and feature access:

- **Premium Wallpaper Unlock**: Dialog overlay in DetailScreen allows ad-watching to unlock premium wallpapers temporarily
- **Premium Editing Tools**: Unlock advanced filters and editing features in EditWallpaperScreen
- **Session-Based Access**: Unlocked content/features remain available until app restart
- **Premium Bypass**: Subscribers get permanent access without ads

### Premium Benefits

- **Ad-Free Experience**: Complete removal of all advertisements
- **Exclusive Content**: Access to premium wallpapers and depth effect collections
- **Cloud Sync**: Favorites synchronization across devices
- **Advanced Editing**: Permanent access to all filters and editing tools without ad-unlock requirement

## Subscription Plans

### Google Play Console Product IDs

- `s25ultrawallpapers_monthly`: Monthly subscription with Play Store discount
- `s25ultrawallpapers_yearly`: Yearly subscription with Play Store discount
- `s25ultrawallpapers_lifetime`: One-time purchase (₹799 app price + Play Store discount)

## Requirements

- **Minimum SDK**: 28 (Android 9.0)
- **Target SDK**: Latest
- **Compile SDK**: Latest
- **Java Version**: 17

## Key Dependencies

### Firebase & Google Services

- Firebase Analytics, Firestore, Storage, Auth, Messaging
- Google Sign-In
- Google Play Billing Library
- Google Play Services Ads

### Jetpack Compose & UI

- Compose BOM
- Material 3
- Navigation Compose
- Accompanist (Pager, System UI Controller, Swipe Refresh)
- Material Icons Extended

### Data & Storage

- Room Database
- DataStore Preferences
- Hilt Dependency Injection

### Image & Media

- Coil Image Loading
- Palette API for color extraction

### Background Processing

- WorkManager with Hilt integration
- Coroutines with Play Services

## Permissions

### Required Permissions

- `INTERNET`: Network access for image loading and Firebase
- `ACCESS_NETWORK_STATE`: Network state monitoring
- `WRITE_EXTERNAL_STORAGE`: Wallpaper downloads (API < 29)
- `SET_WALLPAPER`: Apply wallpapers to device
- `RECEIVE_BOOT_COMPLETED`: WorkManager background tasks

### Runtime Permissions

- **Storage Permission**: Requested during onboarding (2nd screen)
- **Notification Permission**: Requested during onboarding (3rd screen)

## Privacy & Security

- Privacy policy dialog shown on first app launch
- User data encrypted and stored securely
- Firebase Authentication for secure user sessions
- Local favorites stored using Room database
- Premium users sync favorites with Firebase

## App Flow

1. **First Launch**: Onboarding → Storage Permission → Notification Permission → Privacy Policy → Main Screen
2. **Normal Launch**: Direct to Main Screen with tab navigation
3. **Premium Features**: Enhanced sync, exclusive content, ad-free experience
4. **Wallpaper Actions**: Download → Favorite → Apply → Share → Edit

## Update Mechanism

The app includes automatic update checking through the AppUpdates collection:

- **Mandatory Updates**: Non-dismissible dialog, app closes if cancelled
- **Optional Updates**: User can dismiss and continue using the app
- Version comparison with Play Store using Play Core Library

---

_Built with ❤️ using Jetpack Compose and Firebase_
