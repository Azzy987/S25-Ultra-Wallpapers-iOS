import SwiftUI
import PhotosUI

enum SwipeDirection {
    case up, down
}

struct WallpaperDetailScreen: View {
    let wallpaper: Wallpaper
    @Binding var isPresented: Bool
    
    // Optional wallpaper list for swipe navigation
    let wallpapers: [Wallpaper]?
    let currentIndex: Int?
    
    @State private var currentWallpaper: Wallpaper
    @State private var currentWallpaperIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var adManager = AdManager.shared
    @StateObject private var viewCountManager = ViewCountManager.shared
    @StateObject private var toastManager = ToastManager.shared
    @State private var showEditScreen = false
    @State private var isDownloading = false
    @State private var isSharing = false
    @State private var isPreparing = false
    @State private var originalImage: UIImage?
    @State private var showPhotoAlert = false
    @State private var showPermissionAlert = false
    @State private var showDownloadSuccess = false
    @State private var isMainImageLoaded = false
    @State private var safeAreaTop: CGFloat = 0
    @State private var showPreview = false

    @State private var mainImage: UIImage?
    @State private var isMainImageLoading = true
    @State private var isInfoExpanded = false // Start collapsed
    @State private var calculatedMetadata: ImageMetadata?
    
    // YouTube Shorts-style swipe states
    @State private var dragOffset: CGFloat = 0
    @State private var nextWallpaper: Wallpaper?
    @State private var previousWallpaper: Wallpaper?
    @State private var nextWallpaperImage: UIImage?
    @State private var previousWallpaperImage: UIImage?
    @State private var isLoadingNextPreview = false
    @State private var isLoadingPreviousPreview = false
    @State private var showControls = true // Controls visibility state
    
    // Initializer
    init(wallpaper: Wallpaper, isPresented: Binding<Bool>, wallpapers: [Wallpaper]? = nil, currentIndex: Int? = nil) {
        self.wallpaper = wallpaper
        self._isPresented = isPresented
        self.wallpapers = wallpapers
        self.currentIndex = currentIndex
        self._currentWallpaper = State(initialValue: wallpaper)
        self._currentWallpaperIndex = State(initialValue: currentIndex ?? 0)
        
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                // YouTube Shorts-style layered wallpapers
                ZStack {
                    // Previous wallpaper (visible when swiping down)
                    if dragOffset > 0, let previousImage = previousWallpaperImage {
                        Image(uiImage: previousImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(y: -geometry.size.height + dragOffset)
                            .clipped()
                    }
                    
                    // Current wallpaper
                    ZStack {
                        // Thumbnail layer with hero animation
                        CachedAsyncImage(url: URL(string: currentWallpaper.thumbnail)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.black)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                                    )
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(isMainImageLoaded ? 0 : 1)
                                    .animation(.easeOut(duration: 0.4), value: isMainImageLoaded)
                            case .failure:
                                Rectangle()
                                    .fill(Color.black)
                                    .overlay(
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(.white)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        
                        // Main high-quality image with fade in
                        if let mainImage = mainImage {
                            Image(uiImage: mainImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .opacity(isMainImageLoaded ? 1 : 0)
                                .animation(.easeIn(duration: 0.4), value: isMainImageLoaded)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(y: dragOffset)
                    .clipped()
                    
                    // Next wallpaper (visible when swiping up)
                    if dragOffset < 0, let nextImage = nextWallpaperImage {
                        Image(uiImage: nextImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .offset(y: geometry.size.height + dragOffset)
                            .clipped()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                
                // Loading indicator for main image
                if isMainImageLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        
                }
                
                // Overlay content
                VStack {
                    // Back button at top - hide/show with animation
                    if showControls {
                        VStack {
                        HStack {
                            Button {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    isPresented = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Button {
                                showPreview = true
                            } label: {
                                Image(systemName: "eye")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, safeAreaTop + 16)
                        Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Collapsible Bottom container - show when controls are visible (even while image loads)
                    if showControls {
                        // Swipe instruction text when collapsed and wallpapers available
                        if !isInfoExpanded && wallpapers?.count ?? 0 > 1 {
                            Text("Swipe up or down to change wallpapers")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 24)
                                .padding(.bottom, 8)
                                .transition(.opacity)
                        }
                        
                        CollapsibleInfoContainer(
                            wallpaper: currentWallpaper,
                            calculatedMetadata: calculatedMetadata,
                            isExpanded: $isInfoExpanded,
                            showControls: $showControls,
                            isDownloading: isDownloading,
                            isSharing: isSharing,
                            isPreparing: isPreparing,
                            isFavorited: favoritesManager.isFavorite(currentWallpaper.id),
                            downloadAction: downloadWallpaper,
                            favoriteAction: toggleFavorite,
                            shareAction: shareWallpaper,
                            editAction: editWallpaper,
                            reportAction: reportWallpaper
                        )
                        .frame(maxWidth: max(0, geometry.size.width - 48))
                        .padding(.bottom, 36)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .ignoresSafeArea()
            .onTapGesture {
                if isInfoExpanded {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isInfoExpanded = false
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showControls.toggle()
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let verticalMovement = value.translation.height
                        let horizontalMovement = value.translation.width

                        // Check if it's a horizontal swipe from left edge (back gesture)
                        if value.startLocation.x < 50 && horizontalMovement > abs(verticalMovement) {
                            // This is a back gesture from left edge - don't process
                            return
                        }

                        // Only process vertical swipes (not horizontal)
                        if abs(verticalMovement) > abs(horizontalMovement) && wallpapers?.count ?? 0 > 1 {
                            // YouTube Shorts style: Allow dragging up to 80% of screen height for smooth interaction
                            let maxOffset = geometry.size.height * 0.8
                            let dampingFactor: CGFloat = 0.7 // Increased responsiveness
                            let dampedMovement = verticalMovement * dampingFactor
                            let newDragOffset = max(-maxOffset, min(maxOffset, dampedMovement))

                            // Update dragOffset with smoother response
                            dragOffset = newDragOffset

                            // Load preview images immediately when starting to drag (prevent multiple calls)
                            if dragOffset > 20 && previousWallpaperImage == nil && !isLoadingPreviousPreview {
                                isLoadingPreviousPreview = true
                                loadPreviewImage(for: previousWallpaper, isNext: false)
                            } else if dragOffset < -20 && nextWallpaperImage == nil && !isLoadingNextPreview {
                                isLoadingNextPreview = true
                                loadPreviewImage(for: nextWallpaper, isNext: true)
                            }
                        }
                    }
                    .onEnded { value in
                        let verticalMovement = value.translation.height
                        let horizontalMovement = value.translation.width
                        let velocity = value.velocity.height

                        // Check if it's a back gesture from left edge
                        if value.startLocation.x < 50 && horizontalMovement > 100 && horizontalMovement > abs(verticalMovement) {
                            // Dismiss the screen with animation
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isPresented = false
                            }
                            return
                        }

                        // Only process vertical gestures (not horizontal)
                        if abs(verticalMovement) > 30 && abs(verticalMovement) > abs(horizontalMovement) * 1.5 && wallpapers?.count ?? 0 > 1 {

                            // Detect if it's a fast swipe or slow drag based on velocity
                            let isSwipe = abs(velocity) > 500  // 500 points per second threshold

                            // Improved thresholds for better user experience
                            let swipeThreshold = geometry.size.height * 0.12   // 12% for fast swipe (more sensitive)
                            let dragThreshold = geometry.size.height * 0.25    // 25% for slow drag (easier to trigger)

                            let thresholdToUse = isSwipe ? swipeThreshold : dragThreshold


                            if abs(dragOffset) > thresholdToUse {

                                // Add haptic feedback for successful swipe
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()

                                // Immediately change wallpaper to prevent half-states
                                handleSwipeNavigation(direction: verticalMovement > 0 ? .down : .up)

                            } else {
                                // Snap back to current wallpaper with improved elastic animation
                                withAnimation(.interpolatingSpring(stiffness: 400, damping: 35)) {
                                    dragOffset = 0
                                }
                            }
                        } else {
                            // Only handle non-tap drag gestures - taps are handled by onTapGesture
                            if abs(verticalMovement) >= 10 || abs(horizontalMovement) >= 10 {
                                // Snap back if gesture wasn't recognized as a valid swipe
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                    dragOffset = 0
                                }
                            }
                        }
                    }
            )
            .onAppear {
                safeAreaTop = getKeyWindow()?.safeAreaInsets.top ?? 0
                loadMainImage()
                startImageMetadataCalculation()
                setupAdjacentWallpapers()

                // Track wallpaper view and show interstitial ad if needed
                trackWallpaperView()

                // If this is a stub wallpaper (from banner tap), fetch full data in background
                if currentWallpaper.data.count <= 3 {
                    fetchFullWallpaperDataIfNeeded()
                }
            }
            .onDisappear {
                // Hide any active toasts when leaving the detail screen
                toastManager.hideToast()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .statusBar(hidden: false)
        .ignoresSafeArea()
        .interactiveDismissDisabled(false)
        .overlay(alignment: .center) {
            if showDownloadSuccess {
                DownloadSuccessDialog(
                    isPresented: $showDownloadSuccess,
                    wallpaperName: currentWallpaper.wallpaperName
                )
                .transition(AnyTransition.opacity.animation(.easeInOut))
                .onChange(of: showDownloadSuccess) { isShowing in
                    // Show interstitial ad after dialog is dismissed
                    if !isShowing {
                        adManager.showInterstitialAd {}
                    }
                }
            } else if isDownloading {
                // Progress indicator during download
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Saving to Photos...")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .transition(AnyTransition.opacity.animation(.easeInOut))
            } else if isSharing {
                // Progress indicator during share preparation
                HStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Preparing to share...")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .transition(AnyTransition.opacity.animation(.easeInOut))
            }
        }
        .fullScreenCover(isPresented: $showEditScreen) {
            if let image = originalImage {
                EditWallpaperScreen(wallpaper: currentWallpaper, originalImage: image)
            }
        }
        .fullScreenCover(isPresented: $showPreview) {
            WallpaperPreviewScreen(wallpaper: currentWallpaper, isPresented: $showPreview)
                .navigationBarHidden(true)
                .ignoresSafeArea(.all)
        }
        .alert("Wallpaper Downloaded", isPresented: $showPhotoAlert) {
            Button("View in Photos") {
                if let url = URL(string: "photos-redirect://") {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Photo Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .overlay(alignment: .bottom) {
            if toastManager.showToast {
                ToastView(
                    message: toastManager.toastMessage,
                    type: toastManager.toastType,
                    isPresented: $toastManager.showToast
                )
                .padding(.bottom, 100)
            }
        }
    }
    
    private func loadMainImage() {
        isMainImageLoading = true

        // Step 1: Show thumbnail immediately if it's already in cache (fast path)
        let thumbnailUrl = currentWallpaper.thumbnail.isEmpty ? currentWallpaper.imageUrl : currentWallpaper.thumbnail
        let thumbURL = URL(string: thumbnailUrl)

        // Try multiple cache layers for thumbnail
        let thumbImage: UIImage? = ImageCache.shared.getUIImage(for: thumbURL)
            ?? (thumbURL.flatMap { URLCache.shared.cachedResponse(for: URLRequest(url: $0)) }.flatMap { UIImage(data: $0.data) })

        if let thumbImage = thumbImage {
            // Show thumbnail immediately while full-res loads in background
            self.mainImage = thumbImage
            self.isMainImageLoaded = true
            self.isMainImageLoading = false
        }

        // Step 2: Load full-res image (cached or download)
        loadCachedImage(from: currentWallpaper.imageUrl) { image in
            DispatchQueue.main.async {
                if let image = image {
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.mainImage = image
                        self.isMainImageLoaded = true
                    }
                }
                self.isMainImageLoading = false
            }
        }
    }
    
    private func startImageMetadataCalculation() {
        // Start background calculation of image dimensions and size
        ImageMetadataCache.shared.getMetadata(for: currentWallpaper.imageUrl) { metadata in
            self.calculatedMetadata = metadata
        }
    }
    
    private func setupAdjacentWallpapers() {
        guard let wallpapers = wallpapers, wallpapers.count > 1 else { 
            return 
        }
        
        // Set next wallpaper
        let nextIndex = (currentWallpaperIndex + 1) % wallpapers.count
        nextWallpaper = wallpapers[nextIndex]
        
        // Set previous wallpaper
        let previousIndex = currentWallpaperIndex == 0 ? wallpapers.count - 1 : currentWallpaperIndex - 1
        previousWallpaper = wallpapers[previousIndex]
    }
    
    private func loadPreviewImage(for wallpaper: Wallpaper?, isNext: Bool) {
        guard let wallpaper = wallpaper else { 
            return 
        }
        guard let url = URL(string: wallpaper.imageUrl) else { 
            return 
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    if isNext {
                        self.nextWallpaperImage = image
                    } else {
                        self.previousWallpaperImage = image
                    }
                }
            } else {
            }
        }.resume()
    }
    
    private func shareWallpaper() {
        toastManager.showInfoToast(message: "Preparing to share...")
        isSharing = true
        // Use already-loaded mainImage if available to avoid re-downloading
        if let alreadyLoaded = mainImage {
            performShareWithImage(alreadyLoaded)
        } else {
            loadCachedImage(from: currentWallpaper.imageUrl) { [self] cachedImage in
                guard let image = cachedImage else {
                    DispatchQueue.main.async {
                        toastManager.showErrorToast(message: "Failed to load image")
                        isSharing = false
                    }
                    return
                }
                performShareWithImage(image)
            }
        }
    }

    private func performShareWithImage(_ image: UIImage) {
        // Write JPEG to a temp file off the main thread to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let fileName = "\(self.currentWallpaper.wallpaperName)_share.jpg"
            let fileURL = cachesDirectory.appendingPathComponent(fileName)

            guard let imageData = image.jpegData(compressionQuality: 0.85) else {
                DispatchQueue.main.async {
                    self.toastManager.showErrorToast(message: "Failed to prepare image for sharing")
                    self.isSharing = false
                }
                return
            }

            do {
                try imageData.write(to: fileURL)
            } catch {
                DispatchQueue.main.async {
                    self.toastManager.showErrorToast(message: "Failed to prepare image for sharing")
                    self.isSharing = false
                }
                return
            }

            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList]
                activityVC.completionWithItemsHandler = { _, _, _, _ in
                    try? FileManager.default.removeItem(at: fileURL)
                    DispatchQueue.main.async {
                        self.isSharing = false
                        self.adManager.showInterstitialAd {}
                    }
                }

                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first,
                      let rootVC = window.rootViewController else {
                    self.isSharing = false
                    return
                }

                var topVC = rootVC
                while let presentedVC = topVC.presentedViewController {
                    topVC = presentedVC
                }

                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = window
                    popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                }

                topVC.present(activityVC, animated: true)
            }
        }
    }

    private func editWallpaper() {
        isPreparing = true

        // Directly proceed to editing without ad
        performEdit()
    }

    private func performEdit() {
        // Load the cached image
        loadCachedImage(from: currentWallpaper.imageUrl) { cachedImage in
            guard let image = cachedImage else {
                DispatchQueue.main.async {
                    toastManager.showErrorToast(message: "Failed to load image")
                    isPreparing = false
                }
                return
            }

            DispatchQueue.main.async {
                // Set the image first, then show the screen
                self.originalImage = image
                isPreparing = false
                // Small delay to ensure the image is set before showing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showEditScreen = true
                }
            }
        }
    }

    private func loadCachedImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        // Check in-memory UIImage cache first (populated by CachedAsyncImage)
        if let memCached = ImageCache.shared.getUIImage(for: url) {
            completion(memCached)
            return
        }

        // Check HTTP URL cache second
        let cache = URLCache.shared
        if let cachedResponse = cache.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
            // Populate in-memory cache for faster future access
            ImageCache.shared.setUIImage(image, for: url)
            completion(image)
        } else {
            // If not cached, download the image
            downloadImage(from: urlString, completion: completion)
        }
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let aspectRatio = size.width / size.height
        var newSize: CGSize

        if size.width > maxDimension || size.height > maxDimension {
            if aspectRatio > 1 {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        } else {
            newSize = size
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    
    private func downloadWallpaper() {
        toastManager.showDownloadToast(message: "Downloading wallpaper...")
        checkPermissionAndDownload()
    }
    
    private func checkPermissionAndDownload() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    self.downloadAndSaveWallpaper()
                }
            }
        case .authorized, .limited:
            downloadAndSaveWallpaper()
        default:
            showPermissionAlert = true
        }
    }
    
    private func downloadAndSaveWallpaper() {
        isDownloading = true
        
        loadCachedImage(from: currentWallpaper.imageUrl) { image in
            guard let originalImage = image else {
                DispatchQueue.main.async {
                    self.toastManager.showErrorToast(message: "Failed to download wallpaper")
                    self.isDownloading = false
                }
                return
            }
            
            // Convert WebP or any format to JPEG for iOS compatibility
            guard let jpegData = originalImage.jpegData(compressionQuality: 0.9),
                  let jpegImage = UIImage(data: jpegData) else {
                DispatchQueue.main.async {
                    self.toastManager.showErrorToast(message: "Failed to convert image format")
                    self.isDownloading = false
                }
                return
            }
            
            print("📱 [DOWNLOAD] Successfully converted wallpaper to JPEG format")
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: jpegImage)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    self.isDownloading = false
                    if success {
                        self.showDownloadSuccess = true
                    } else {
                        self.toastManager.showErrorToast(message: "Failed to save wallpaper: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        }
    }
    
    private func toggleFavorite() {
        let isAdded = favoritesManager.toggleFavorite(wallpaper: currentWallpaper)
        toastManager.showFavoriteToast(wallpaperName: currentWallpaper.wallpaperName, isAdded: isAdded)
    }
    
    func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            completion(nil)
            return
        }
        
        // Start downloading the image
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Download error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("Invalid response from server")
                completion(nil)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Failed to convert data to UIImage")
                completion(nil)
                return
            }
            
        
           
            completion(image)
        }.resume()
    }

    private func getKeyWindow() -> UIWindow? {
        guard Thread.isMainThread else {
            var window: UIWindow?
            DispatchQueue.main.sync {
                window = getKeyWindow()
            }
            return window
        }
        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        return window
    }

    private func reportWallpaper() {
        let subject = "S25UltraWallpapers: Report Wallpaper"
        let body = """
        Report for: \(currentWallpaper.wallpaperName)
        ID: \(currentWallpaper.id)
        
        Issue:
        
        
        Device: \(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)
        """
        
        let email = "droidates@gmail.com"
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func showShareSheet() {
        guard let window = getKeyWindow() else { return }
        
        // Create a temporary file URL with the wallpaper name
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(currentWallpaper.wallpaperName).png")
        
        // Load the cached image
        loadCachedImage(from: currentWallpaper.imageUrl) { cachedImage in
            guard let image = cachedImage,
                  let imageData = image.pngData() else {
                DispatchQueue.main.async {
                    toastManager.showErrorToast(message: "Failed to prepare image")
                    isSharing = false
                }
                return
            }
            
            do {
                try imageData.write(to: tempURL)
                
                DispatchQueue.main.async {
                    let activityVC = UIActivityViewController(
                        activityItems: [tempURL],
                        applicationActivities: nil
                    )
                    activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList]
                    
                    activityVC.popoverPresentationController?.sourceView = window
                    activityVC.popoverPresentationController?.sourceRect = CGRect(
                        x: window.bounds.midX,
                        y: window.bounds.midY,
                        width: 0,
                        height: 0
                    )
                    
                    window.rootViewController?.present(activityVC, animated: true) {
                        self.isSharing = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    toastManager.showErrorToast(message: "Failed to prepare image for sharing")
                    isSharing = false
                }
            }
        }
    }
    
    // MARK: - Background Full Data Fetch

    /// When navigating from a banner tap, we create a stub Wallpaper with only 3 fields
    /// (imageUrl, thumbnail, wallpaperName) to allow instant navigation. This function
    /// fetches the complete wallpaper data in the background and updates currentWallpaper.
    private func fetchFullWallpaperDataIfNeeded() {
        let wallpaperId = currentWallpaper.id
        Task {
            if let full = try? await FirebaseManager.shared.fetchWallpaperById(wallpaperId, collection: "Samsung") {
                await MainActor.run { currentWallpaper = full }
                return
            }
            if let full = try? await FirebaseManager.shared.fetchWallpaperById(wallpaperId, collection: "TrendingWallpapers") {
                await MainActor.run { currentWallpaper = full }
            }
        }
    }

    // MARK: - View and Ad Tracking

    private func trackWallpaperView() {
        viewCountManager.recordWallpaperView()
        
        // Check if we should show interstitial ad for view count
        if viewCountManager.shouldShowInterstitialForView() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.adManager.showInterstitialAd {
                    // Ad completed
                }
            }
        }
    }
    
    private func trackSwipeInDetailScreen() {
        viewCountManager.recordSwipeInDetailScreen()
        
        // Check if we should show interstitial ad for swipe count
        if viewCountManager.shouldShowInterstitialForSwipe() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.adManager.showInterstitialAd {
                    // Ad completed
                }
            }
        }
    }
    
    // MARK: - Swipe Navigation
    private func handleSwipeNavigation(direction: SwipeDirection) {
        guard let wallpapers = wallpapers, wallpapers.count > 1 else { 
            return 
        }
        
        let newIndex: Int
        let newWallpaper: Wallpaper
        let preloadedImage: UIImage?
        
        switch direction {
        case .up:
            newIndex = (currentWallpaperIndex + 1) % wallpapers.count
            newWallpaper = wallpapers[newIndex]
            preloadedImage = nextWallpaperImage
        case .down:
            newIndex = currentWallpaperIndex == 0 ? wallpapers.count - 1 : currentWallpaperIndex - 1
            newWallpaper = wallpapers[newIndex]
            preloadedImage = previousWallpaperImage
        }
        
        guard newIndex >= 0 && newIndex < wallpapers.count else {
            return
        }
        
        dragOffset = 0
        currentWallpaper = newWallpaper
        currentWallpaperIndex = newIndex
        
        // Reset loading states
        isLoadingNextPreview = false
        isLoadingPreviousPreview = false
        
        // Use preloaded image if available
        if let preloadedImage = preloadedImage {
            mainImage = preloadedImage
            isMainImageLoaded = true
            isMainImageLoading = false
        } else {
            mainImage = nil
            isMainImageLoading = true
            isMainImageLoaded = false
            loadMainImage()
        }
        
        // Reset metadata
        calculatedMetadata = nil
        startImageMetadataCalculation()
        
        // Clear old preview images
        nextWallpaperImage = nil
        previousWallpaperImage = nil
        
        setupAdjacentWallpapers()
        
        // Track swipe and show interstitial ad if needed
        trackSwipeInDetailScreen()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

struct InfoItem: View {
    let icon: String
    let value: String

    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                Text(value)
            }
        
    
        }
    }
}


struct CircleActionButton: View {
    let icon: String
    var isActive: Bool = false
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: 50, height: 50)
                    .background(Color.black)
                    .clipShape(Circle())
            } else {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .red : .white)
                    .frame(width: 50, height: 50)
                    .background(Color.black)
                    .clipShape(Circle())
            }
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

class ImageToShare: NSObject, UIActivityItemSource {
    let image: UIImage
    let title: String
    let url: URL
    
    init(image: UIImage, title: String, url: URL) {
        self.image = image
        self.title = title
        self.url = url
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case .saveToCameraRoll, .copyToPasteboard:
            return image
        default:
            return url
        }
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return title
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, thumbnailImageForActivityType activityType: UIActivity.ActivityType?, suggestedSize size: CGSize) -> UIImage? {
        return image
    }
}

struct CollapsibleInfoContainer: View {
    let wallpaper: Wallpaper
    let calculatedMetadata: ImageMetadata?
    @Binding var isExpanded: Bool
    @Binding var showControls: Bool
    let isDownloading: Bool
    let isSharing: Bool
    let isPreparing: Bool
    let isFavorited: Bool
    let downloadAction: () -> Void
    let favoriteAction: () -> Void
    let shareAction: () -> Void
    let editAction: () -> Void
    let reportAction: () -> Void
    
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showInfoDialog = false
    @State private var showReportDialog = false
    
    // Use calculated metadata if available, otherwise fall back to wallpaper data
    private var displayDimensions: String {
        calculatedMetadata?.dimensions ?? wallpaper.dimensions
    }
    
    private var displaySize: String {
        calculatedMetadata?.size ?? wallpaper.size
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header - always visible
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: isExpanded ? 4 : 0) {
                    Text(wallpaper.wallpaperName)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    // Only show source when expanded
                    if isExpanded {
                        Text(wallpaper.source)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                    .font(.title2)
                    .foregroundColor(.white)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
            .onTapGesture {
                // Tap anywhere on header row - handle controls visibility and expansion
                print("📦 [CONTAINER TAP] Container header tapped - showControls: \(showControls), isExpanded: \(isExpanded)")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if !showControls {
                        // If controls are hidden, show them first
                        print("🎛️ [CONTAINER TAP] Showing controls first")
                        showControls = true
                    } else if isExpanded {
                        print("📦 [CONTAINER TAP] Collapsing expanded container")
                        isExpanded = false  // Collapse when expanded
                    } else {
                        print("📦 [CONTAINER TAP] Expanding container")
                        isExpanded = true   // Expand when collapsed
                    }
                }
            }
            
            // Expanded content - shows when expanded
            if isExpanded {
                VStack(spacing: 12) {
                    // Stats Grid - add background tap to collapse in empty areas
                    HStack(alignment: .top, spacing: 24) {
                        // Left Column
                        VStack(alignment: .leading, spacing: 16) {
                            InfoItem(icon: "arrow.down.circle", value: "\(wallpaper.downloads) Downloads")
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isExpanded = false
                                    }
                                }
                            
                            InfoItem(icon: "aspectratio", value: displayDimensions)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isExpanded = false
                                    }
                                }
                            
                            // INFO - clickable with underline (NO collapse)
                            Button(action: {
                                showInfoDialog = true
                            }) {
                                HStack {
                                    Image(systemName: "exclamationmark.shield")
                                    Text("INFO")
                                        .underline()
                                }
                                .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Right Column
                        VStack(alignment: .leading, spacing: 16) {
                            InfoItem(icon: "eye", value: "\(wallpaper.views) Views")
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isExpanded = false
                                    }
                                }
                            
                            InfoItem(icon: "internaldrive", value: displaySize)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        isExpanded = false
                                    }
                                }
                            
                            // REPORT - clickable with underline (NO collapse)
                            Button(action: {
                                showReportDialog = true
                            }) {
                                HStack {
                                    Image(systemName: "flag")
                                    Text("REPORT")
                                        .underline()
                                }
                                .foregroundColor(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .foregroundColor(.white)
                    .background(
                        // Invisible background for tap gesture in empty areas
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
                    )
                    
                    // Action Buttons (don't collapse)
                    HStack(spacing: 24) {
                        CircleActionButton(
                            icon: "arrow.down.circle",
                            isLoading: isDownloading,
                            action: downloadAction
                        )
                        
                        CircleActionButton(
                            icon: isFavorited ? "heart.fill" : "heart",
                            isActive: isFavorited,
                            action: favoriteAction
                        )
                        
                        CircleActionButton(
                            icon: "square.and.arrow.up",
                            isLoading: isSharing,
                            action: shareAction
                        )
                        
                        CircleActionButton(
                            icon: "pencil",
                            isLoading: isPreparing,
                            action: editAction
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(32)
        .alert("Information", isPresented: $showInfoDialog) {
            Button("OK") { }
        } message: {
            Text("This wallpaper is protected by copyright. All rights reserved.")
        }
        .alert("Report", isPresented: $showReportDialog) {
            Button("Cancel", role: .cancel) { }
            Button("Report") {
                reportAction()
            }
        } message: {
            Text("Report this wallpaper for inappropriate content or copyright issues.")
        }
    }
}


