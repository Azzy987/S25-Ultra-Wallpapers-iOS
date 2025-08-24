import SwiftUI
import Combine

struct WallpaperPreviewScreen: View {
    let wallpaper: Wallpaper
    @Binding var isPresented: Bool
    @Environment(\.appTheme) private var theme
    @State private var previewMode: PreviewMode = .lockScreen
    @State private var wallpaperImage: UIImage?
    @State private var isLoading = true
    @State private var showControls = true
    
    // State for displaying the live time on the lock screen
    @State private var currentTime = Date()
    
    // Timer to update the time every second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum PreviewMode: String, CaseIterable {
        case lockScreen = "Lock"
        case homeScreen = "Home"
        
        var displayName: String {
            switch self {
            case .lockScreen: return "Lock Screen"
            case .homeScreen: return "Home Screen"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
            // True full-screen wallpaper background - extends to all edges
            if let wallpaperImage = wallpaperImage {
                Image(uiImage: wallpaperImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all) // Extends to status bar and home indicator
                    .clipped()
            } else {
                Color.black
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea(.all)
            }
            
            // Loading indicator
            if isLoading {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Loading wallpaper...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 16)
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
            
            // Conditionally display the correct overlay based on the previewMode
            // This ensures the icons and widgets are actually shown
            if !isLoading {
                switch previewMode {
                case .lockScreen:
                    fullScreenLockOverlay
                case .homeScreen:
                    fullScreenHomeOverlay
                }
            }
            
            // Always visible controls overlay
            VStack {
                // Top controls with proper safe area spacing
                HStack {
                    // Close button
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Lock/Home toggle with spacing from status bar
                    HStack(spacing: 4) {
                        ForEach(PreviewMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    previewMode = mode
                                }
                            } label: {
                                Text(mode.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(previewMode == mode ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        previewMode == mode ? 
                                        AnyView(Color.white.opacity(0.9)) : 
                                        AnyView(Color.clear)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(4)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 24)
                
                Spacer()
            }
            
            // Preview mode overlays removed for cleaner wallpaper view
            // Users can see the pure wallpaper without distracting overlays
            }
        }
        .onAppear {
            loadWallpaperImage()
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
        .statusBarHidden(true) // Hiding the status bar is better for a true preview
        .preferredColorScheme(.dark) // Ensure white status bar content
    }
    
    @ViewBuilder
    private var fullScreenLockOverlay: some View {
        VStack {
            Spacer()
            
            // Lock screen time display with live time
            VStack(spacing: 8) {
                Text(currentTime, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                
                Text(currentTime, style: .time)
                    .font(.system(size: 84, weight: .thin))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
            }
            .padding(.top, 100)
            
            Spacer()
            
            // Lock screen bottom controls
            VStack(spacing: 20) {
                // Sample notification
                HStack {
                    Image(systemName: "message.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Messages")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Check out this amazing wallpaper!")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal, 30)
                
                // Bottom action buttons with proper spacing from bottom
                HStack {
                    Image(systemName: "flashlight.off.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(18)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(18)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 120)
            }
        }
    }
    
    @ViewBuilder
    private var fullScreenHomeOverlay: some View {
        VStack {
            Spacer()
            
            // App icons grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 25) {
                ForEach(0..<16) { index in
                    fullScreenAppIcon(for: index)
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Dock with proper spacing from bottom
            HStack(spacing: 25) {
                ForEach(0..<4) { index in
                    fullScreenDockIcon(for: index)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 120)
        }
    }
    
    
    @ViewBuilder
    private func fullScreenAppIcon(for index: Int) -> some View {
        let icons = ["phone.fill", "mail.fill", "safari.fill", "music.note", 
                     "camera.fill", "photo.fill", "message.fill", "facetime",
                     "calendar", "clock.fill", "calculator", "settings",
                     "weather.sun.fill", "compass.drawing", "flashlight.on.fill", "shortcuts"]
        
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: icons[safe: index] ?? "app.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func fullScreenDockIcon(for index: Int) -> some View {
        let dockIcons = ["phone.fill", "safari.fill", "message.fill", "music.note"]
        
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: dockIcons[safe: index] ?? "app.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    
    private func loadWallpaperImage() {
        isLoading = true
        guard let url = URL(string: wallpaper.imageUrl) else {
            isLoading = false
            return
        }
        
        // Check cache first
        let cache = URLCache.shared
        let request = URLRequest(url: url)
        
        if let cachedResponse = cache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.wallpaperImage = image
                    self.isLoading = false
                }
            }
            return
        }
        
        // Download if not cached
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.wallpaperImage = image
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}

 