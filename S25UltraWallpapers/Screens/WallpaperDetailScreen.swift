import SwiftUI
import PhotosUI

enum SwipeDirection {
    case up, down
}

struct WallpaperDetailScreen: View {
    let wallpaper: Wallpaper
    let animation: Namespace.ID
    @Binding var isPresented: Bool
    
    // Optional wallpaper list for swipe navigation
    let wallpapers: [Wallpaper]?
    let currentIndex: Int?
    
    @State private var currentWallpaper: Wallpaper
    @State private var currentWallpaperIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showEditScreen = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
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
    
    // Initializer
    init(wallpaper: Wallpaper, animation: Namespace.ID, isPresented: Binding<Bool>, wallpapers: [Wallpaper]? = nil, currentIndex: Int? = nil) {
        self.wallpaper = wallpaper
        self.animation = animation
        self._isPresented = isPresented
        self.wallpapers = wallpapers
        self.currentIndex = currentIndex
        self._currentWallpaper = State(initialValue: wallpaper)
        self._currentWallpaperIndex = State(initialValue: currentIndex ?? 0)
        
        print("\n🏁 === WallpaperDetailScreen INIT ===")
        print("🏁 Initial wallpaper: \(wallpaper.wallpaperName)")
        print("🏁 Initial index: \(currentIndex ?? 0)")
        print("🏁 Total wallpapers: \(wallpapers?.count ?? 0)")
        if let wallpapers = wallpapers {
            print("🏁 Wallpaper list:")
            for (index, wp) in wallpapers.enumerated() {
                let marker = index == (currentIndex ?? 0) ? " ← CURRENT" : ""
                print("🏁   [\(index)]: \(wp.wallpaperName)\(marker)")
            }
        }
        print("🏁 === INIT END ===\n")
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
                        // Thumbnail layer
                        CachedAsyncImage(url: URL(string: currentWallpaper.thumbnail)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .matchedGeometryEffect(
                                        id: "wallpaper-\(currentWallpaper.id)",
                                        in: animation,
                                        isSource: false
                                    )
                            case .failure:
                                Image(systemName: "photo")
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
                                .animation(.easeIn(duration: 0.3), value: isMainImageLoaded)
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
                    // Back button at top
                    VStack {
                        HStack {
                            Button {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
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
                    
                    // Collapsible Bottom container - only show when main image is loaded
                    if isMainImageLoaded {
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
                            isDownloading: isDownloading,
                            isSharing: isSharing,
                            isPreparing: isPreparing,
                            downloadAction: downloadWallpaper,
                            favoriteAction: toggleFavorite,
                            shareAction: shareWallpaper,
                            editAction: editWallpaper,
                            reportAction: reportWallpaper
                        )
                        .frame(maxWidth: geometry.size.width - 48)
                        .padding(.bottom, 36)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .ignoresSafeArea()
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        let verticalMovement = value.translation.height
                        let horizontalMovement = abs(value.translation.width)
                        
                        // Only process vertical swipes (not horizontal)
                        if abs(verticalMovement) > abs(horizontalMovement) && wallpapers?.count ?? 0 > 1 {
                            // Limit drag offset to screen height for smooth tracking
                            let maxOffset = geometry.size.height
                            let newDragOffset = max(-maxOffset, min(maxOffset, verticalMovement))
                            
                            // Only update dragOffset if it's significantly different to prevent jitter
                            if abs(newDragOffset - dragOffset) > 5 {
                                dragOffset = newDragOffset
                            }
                            
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
                        let horizontalMovement = abs(value.translation.width)
                        let velocity = value.velocity.height
                        
                        // Only process vertical gestures (not horizontal)
                        if abs(verticalMovement) > 30 && abs(verticalMovement) > horizontalMovement * 1.5 && wallpapers?.count ?? 0 > 1 {
                            
                            print("\n📱 === GESTURE END ===")
                            print("📱 verticalMovement: \(verticalMovement)")
                            print("📱 velocity: \(velocity)")
                            print("📱 dragOffset: \(dragOffset)")
                            print("📱 currentIndex: \(currentWallpaperIndex)")
                            
                            // Detect if it's a fast swipe or slow drag based on velocity
                            let isSwipe = abs(velocity) > 500  // 500 points per second threshold
                            
                            let swipeThreshold = geometry.size.height * 0.15   // 15% for fast swipe
                            let dragThreshold = geometry.size.height * 0.4     // 40% for slow drag
                            
                            let thresholdToUse = isSwipe ? swipeThreshold : dragThreshold
                            
                            print("📱 isSwipe: \(isSwipe), threshold: \(thresholdToUse)")
                            
                            if abs(dragOffset) > thresholdToUse {
                                print("📱 ✅ THRESHOLD MET - Triggering navigation")
                                
                                // Immediately change wallpaper to prevent half-states
                                handleSwipeNavigation(direction: verticalMovement > 0 ? .down : .up)
                                
                            } else {
                                print("📱 ❌ THRESHOLD NOT MET - Snapping back")
                                // Snap back to current wallpaper with elastic animation
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                    dragOffset = 0
                                }
                            }
                            print("📱 === GESTURE END ===\n")
                        } else {
                            // Handle tap to collapse info or snap back
                            if abs(verticalMovement) < 10 && horizontalMovement < 10 {
                                if isInfoExpanded {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        isInfoExpanded = false
                                    }
                                }
                            } else {
                                // Snap back if gesture wasn't recognized
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
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .statusBar(hidden: false)
        .ignoresSafeArea()
        .interactiveDismissDisabled(false)
        .overlay(alignment: .bottom) {
            if showToast {
                ToastView(
                    message: toastMessage,
                    type: toastType,
                    isPresented: $showToast
                )
            }
        }
        .overlay(alignment: .center) {
            if showDownloadSuccess {
                DownloadSuccessDialog(
                    isPresented: $showDownloadSuccess,
                    wallpaperName: currentWallpaper.wallpaperName
                )
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
    }
    
    private func loadMainImage() {
        guard let url = URL(string: currentWallpaper.imageUrl) else { 
            print("🖼️ loadMainImage: Invalid URL for \(currentWallpaper.wallpaperName)")
            return 
        }
        
        print("🖼️ Loading main image for: \(currentWallpaper.wallpaperName)")
        isMainImageLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("🖼️ ✅ Main image loaded for: \(self.currentWallpaper.wallpaperName)")
                    withAnimation(.easeIn(duration: 0.3)) {
                        self.mainImage = image
                        self.isMainImageLoaded = true
                        self.isMainImageLoading = false
                    }
                }
            } else {
                print("🖼️ ❌ Failed to load main image for: \(self.currentWallpaper.wallpaperName)")
                DispatchQueue.main.async {
                    self.isMainImageLoading = false
                }
            }
        }.resume()
    }
    
    private func startImageMetadataCalculation() {
        // Start background calculation of image dimensions and size
        ImageMetadataCache.shared.getMetadata(for: currentWallpaper.imageUrl) { metadata in
            self.calculatedMetadata = metadata
        }
    }
    
    private func setupAdjacentWallpapers() {
        guard let wallpapers = wallpapers, wallpapers.count > 1 else { 
            print("🔄 setupAdjacentWallpapers: No wallpapers or count <= 1")
            return 
        }
        
        print("🔄 setupAdjacentWallpapers: currentIndex=\(currentWallpaperIndex), total=\(wallpapers.count)")
        print("🔄 Current wallpaper: \(currentWallpaper.wallpaperName)")
        
        // Set next wallpaper
        let nextIndex = (currentWallpaperIndex + 1) % wallpapers.count
        nextWallpaper = wallpapers[nextIndex]
        print("🔄 Next wallpaper[\(nextIndex)]: \(nextWallpaper?.wallpaperName ?? "nil")")
        
        // Set previous wallpaper
        let previousIndex = currentWallpaperIndex == 0 ? wallpapers.count - 1 : currentWallpaperIndex - 1
        previousWallpaper = wallpapers[previousIndex]
        print("🔄 Previous wallpaper[\(previousIndex)]: \(previousWallpaper?.wallpaperName ?? "nil")")
    }
    
    private func loadPreviewImage(for wallpaper: Wallpaper?, isNext: Bool) {
        guard let wallpaper = wallpaper else { 
            print("📸 loadPreviewImage: wallpaper is nil for \(isNext ? "next" : "previous")")
            return 
        }
        guard let url = URL(string: wallpaper.imageUrl) else { 
            print("📸 loadPreviewImage: invalid URL for \(wallpaper.wallpaperName)")
            return 
        }
        
        print("📸 Loading \(isNext ? "next" : "previous") preview: \(wallpaper.wallpaperName)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    print("📸 ✅ Loaded \(isNext ? "next" : "previous") preview: \(wallpaper.wallpaperName)")
                    if isNext {
                        self.nextWallpaperImage = image
                    } else {
                        self.previousWallpaperImage = image
                    }
                }
            } else {
                print("📸 ❌ Failed to load \(isNext ? "next" : "previous") preview: \(wallpaper.wallpaperName)")
            }
        }.resume()
    }
    
    private func shareWallpaper() {
        toastMessage = "Preparing to share..."
        toastType = .info
        showToast = true
        isSharing = true
        
        loadCachedImage(from: currentWallpaper.imageUrl) { [self] cachedImage in
            guard let image = cachedImage else {
                DispatchQueue.main.async {
                    toastMessage = "Failed to load image"
                    showToast = true
                    isSharing = false
                }
                return
            }
            
            // Create a temporary file in the caches directory
            let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            let fileName = "\(currentWallpaper.wallpaperName)_\(UUID().uuidString).jpg"
            let fileURL = cachesDirectory.appendingPathComponent(fileName)
            
            do {
                // Convert image to data and write to file
                if let imageData = image.jpegData(compressionQuality: 0.8) {
                    try imageData.write(to: fileURL)
                    
                    DispatchQueue.main.async {
                        // Create activity items
                        let activityItems: [Any] = [image, fileURL]
                        
                        let activityVC = UIActivityViewController(
                            activityItems: activityItems,
                            applicationActivities: nil
                        )
                        
                        // Configure activity view controller
                        activityVC.excludedActivityTypes = [.assignToContact, .addToReadingList]
                        activityVC.completionWithItemsHandler = { _, completed, _, _ in
                            // Clean up temporary file
                            try? FileManager.default.removeItem(at: fileURL)
                            
                            DispatchQueue.main.async {
                                isSharing = false
                            }
                        }
                        
                        // Present the activity view controller
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first,
                           let rootVC = window.rootViewController {
                            
                            // Find the topmost presented view controller
                            var topVC = rootVC
                            while let presentedVC = topVC.presentedViewController {
                                topVC = presentedVC
                            }
                            
                            // Configure popover for iPad
                            if let popover = activityVC.popoverPresentationController {
                                popover.sourceView = window
                                popover.sourceRect = CGRect(
                                    x: window.bounds.midX,
                                    y: window.bounds.midY,
                                    width: 0,
                                    height: 0
                                )
                            }
                            
                            topVC.present(activityVC, animated: true)
                        } else {
                            isSharing = false
                            toastMessage = "Couldn't present share sheet"
                            showToast = true
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    toastMessage = "Failed to prepare image for sharing"
                    showToast = true
                    isSharing = false
                }
            }
        }
    }

    private func editWallpaper() {
        toastMessage = "Preparing to edit..."
        toastType = .info
        showToast = true
        isPreparing = true

        // Load the cached image
        loadCachedImage(from: currentWallpaper.imageUrl) { cachedImage in
            guard let image = cachedImage else {
                DispatchQueue.main.async {
                    toastMessage = "Failed to load cached image"
                    showToast = true
                    isPreparing = false
                }
                return
            }

            DispatchQueue.main.async {
                originalImage = image
                showEditScreen = true
                isPreparing = false
            }
        }
    }

    private func loadCachedImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        let cache = URLCache.shared
        if let cachedResponse = cache.cachedResponse(for: URLRequest(url: url)),
           let image = UIImage(data: cachedResponse.data) {
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
        toastMessage = "Downloading wallpaper..."
        toastType = .download
        showToast = true
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    downloadAndSaveWallpaper()
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
            guard let image = image else {
                DispatchQueue.main.async {
                    self.toastMessage = "Failed to download wallpaper"
                    self.showToast = true
                    self.isDownloading = false
                }
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    self.isDownloading = false
                    if success {
                        self.showDownloadSuccess = true
                    } else {
                        self.toastMessage = "Failed to save wallpaper"
                        self.showToast = true
                    }
                }
            }
        }
    }
    
    private func toggleFavorite() {
        if favoritesManager.isFavorite(currentWallpaper.id) {
            _ = favoritesManager.toggleFavorite(wallpaper: currentWallpaper)
            toastMessage = "\(currentWallpaper.wallpaperName) removed from favorites"
            toastType = .unfavorite
        } else {
            _ = favoritesManager.toggleFavorite(wallpaper: currentWallpaper)
            toastMessage = "\(currentWallpaper.wallpaperName) added to favorites"
            toastType = .favorite
        }
        showToast = true
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
                    toastMessage = "Failed to prepare image"
                    showToast = true
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
                    toastMessage = "Failed to prepare image for sharing"
                    showToast = true
                    isSharing = false
                }
            }
        }
    }
    
    // MARK: - Swipe Navigation
    private func handleSwipeNavigation(direction: SwipeDirection) {
        guard let wallpapers = wallpapers, wallpapers.count > 1 else { 
            print("🚫 handleSwipeNavigation: No wallpapers or count <= 1")
            return 
        }
        
        print("\n🎯 === SWIPE NAVIGATION START ===")
        print("🎯 Direction: \(direction)")
        print("🎯 Current index BEFORE: \(currentWallpaperIndex)")
        print("🎯 Current wallpaper BEFORE: \(currentWallpaper.wallpaperName)")
        print("🎯 Total wallpapers: \(wallpapers.count)")
        print("🎯 DragOffset: \(dragOffset)")
        
        let newIndex: Int
        let newWallpaper: Wallpaper
        let preloadedImage: UIImage?
        
        switch direction {
        case .up:
            // Next wallpaper
            newIndex = (currentWallpaperIndex + 1) % wallpapers.count
            newWallpaper = wallpapers[newIndex] // Use wallpapers array directly
            preloadedImage = nextWallpaperImage
            print("🎯 SWIPE UP: newIndex=\(newIndex), newWallpaper=\(newWallpaper.wallpaperName)")
        case .down:
            // Previous wallpaper  
            newIndex = currentWallpaperIndex == 0 ? wallpapers.count - 1 : currentWallpaperIndex - 1
            newWallpaper = wallpapers[newIndex] // Use wallpapers array directly
            preloadedImage = previousWallpaperImage
            print("🎯 SWIPE DOWN: newIndex=\(newIndex), newWallpaper=\(newWallpaper.wallpaperName)")
        }
        
        // Validate the new index
        guard newIndex >= 0 && newIndex < wallpapers.count else {
            print("🚫 Invalid newIndex: \(newIndex), wallpapers.count: \(wallpapers.count)")
            return
        }
        
        // Ensure dragOffset is 0 to prevent half-states
        print("🎯 Setting dragOffset to 0")
        dragOffset = 0
        
        // Change wallpaper immediately
        currentWallpaper = newWallpaper
        currentWallpaperIndex = newIndex
        
        print("🎯 Current index AFTER: \(currentWallpaperIndex)")
        print("🎯 Current wallpaper AFTER: \(currentWallpaper.wallpaperName)")
        
        // Reset loading states
        isLoadingNextPreview = false
        isLoadingPreviousPreview = false
        
        // Use preloaded image if available
        if let preloadedImage = preloadedImage {
            print("🎯 Using preloaded image")
            mainImage = preloadedImage
            isMainImageLoaded = true
            isMainImageLoading = false
        } else {
            print("🎯 Loading new main image")
            // Reset image states for new wallpaper
            mainImage = nil
            isMainImageLoading = true
            isMainImageLoaded = false
            loadMainImage()
        }
        
        // Reset metadata
        calculatedMetadata = nil
        startImageMetadataCalculation()
        
        // Clear old preview images BEFORE setting up new ones
        nextWallpaperImage = nil
        previousWallpaperImage = nil
        
        // Setup new adjacent wallpapers
        setupAdjacentWallpapers()
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        print("🎯 === SWIPE NAVIGATION END ===\n")
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
    let isDownloading: Bool
    let isSharing: Bool
    let isPreparing: Bool
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
                // Tap anywhere on header row - expand when collapsed, collapse when expanded
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if isExpanded {
                        isExpanded = false  // Collapse when expanded
                    } else {
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
                            icon: favoritesManager.isFavorite(wallpaper.id) ? "heart.fill" : "heart",
                            isActive: favoritesManager.isFavorite(wallpaper.id),
                            action: favoriteAction
                        )
                        
                        CircleActionButton(
                            icon: "square.and.arrow.up",
                            isLoading: isSharing,
                            action: shareAction
                        )
                        
                        CircleActionButton(
                            icon: "slider.horizontal.3",
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


