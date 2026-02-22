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
    @State private var dragOffset: CGFloat = 0

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
                // Black background like detail screen
                Color.black.ignoresSafeArea()
                
                // Wallpaper background - matching detail screen fit exactly
                if let wallpaperImage = wallpaperImage {
                    Image(uiImage: wallpaperImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                } else {
                    Color.black
                        .frame(width: geometry.size.width, height: geometry.size.height)
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
            
            // Always visible controls overlay - fixed position
            VStack {
                // Top controls with fixed positioning
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

                    // Lock/Home toggle
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
                }
                .padding(.horizontal, 20)
                .padding(.top, max(50, geometry.safeAreaInsets.top + 16))

                Spacer()
            }
            
            // Preview mode overlays removed for cleaner wallpaper view
            // Users can see the pure wallpaper without distracting overlays
            }
        }
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow downward swipe to dismiss
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    // Dismiss if swiped down more than 100 points
                    if value.translation.height > 100 {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isPresented = false
                        }
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: geometry.size.height * 0.15)

                // Lock screen time display
                VStack(spacing: 8) {
                    Text(currentTime, format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                    Text(currentTime, style: .time)
                        .font(.system(size: 80, weight: .thin))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 2)
                }

                Spacer()

                // Notifications section
                VStack(spacing: 12) {
                    // First notification
                    HStack(spacing: 12) {
                        Image(systemName: "message.fill")
                            .foregroundColor(.green)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Messages")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Hey! How are you?")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }

                        Spacer()

                        Text("now")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(18)

                    // Second notification
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Mail")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            Text("You have a new email")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(2)
                        }

                        Spacer()

                        Text("5m ago")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial)
                    .cornerRadius(18)
                }
                .padding(.horizontal, 20)

                Spacer()
                    .frame(height: 40)

                // Bottom action buttons
                HStack(spacing: 60) {
                    VStack(spacing: 8) {
                        Image(systemName: "flashlight.off.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                        Text("Flashlight")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                        Text("Camera")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 40)
            }
        }
    }
    
    @ViewBuilder
    private var fullScreenHomeOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.15)

                    // Widgets section at top - 2 square widgets side by side
                    HStack(spacing: 16) {
                        // Square Weather widget with solid blue gradient (not transparent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sofia")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)

                            Text("17°")
                                .font(.system(size: 32, weight: .thin))
                                .foregroundColor(.white)

                            Spacer()

                            VStack(alignment: .leading, spacing: 1) {
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                Text("Cloudy")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                Text("H:18° L:12°")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.4, green: 0.5, blue: 0.8), Color(red: 0.3, green: 0.6, blue: 0.85)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18)

                        // Square Calendar widget (solid white, not transparent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FRIDAY")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.red)

                            Text("20")
                                .font(.system(size: 38, weight: .thin))
                                .foregroundColor(.black)

                            Spacer()

                            Text("No events today")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                        .background(Color.white)
                        .cornerRadius(18)
                    }
                    .padding(.horizontal, 25)
                    .frame(height: 155)

                    Spacer()
                        .frame(height: 20)

                    // App icons grid (2x4 = 8 apps)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                        ForEach(0..<8) { index in
                            fullScreenAppIcon(for: index)
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    // Small centered search capsule above dock
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Search")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial.opacity(0.7))
                        )
                        Spacer()
                    }
                    .padding(.bottom, 6)

                    // Dock - centered
                    HStack(spacing: 22) {
                        ForEach(0..<4) { index in
                            fullScreenDockIcon(for: index)
                        }
                    }
                    .padding(.horizontal, 35)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(.ultraThinMaterial.opacity(0.6))
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    
    @ViewBuilder
    private func fullScreenAppIcon(for index: Int) -> some View {
        let icons: [(icon: String, color: Color)] = [
            ("phone.fill", .green),
            ("mail.fill", .blue),
            ("safari.fill", .blue),
            ("message.fill", .green),
            ("photo.fill", .blue),
            ("map.fill", .green),
            ("facetime", .green),
            ("video.fill", .blue)
        ]

        let iconData = icons[safe: index] ?? ("app.fill", .gray)

        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [iconData.color, iconData.color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: iconData.icon)
                    .font(.title2)
                    .foregroundColor(iconData.color == .white || iconData.color == .gray ? .black : .white)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    @ViewBuilder
    private func fullScreenDockIcon(for index: Int) -> some View {
        let dockIcons: [(icon: String, color: Color)] = [
            ("phone.fill", .green),
            ("safari.fill", .blue),
            ("message.fill", .green),
            ("camera.fill", .gray)
        ]

        let iconData = dockIcons[safe: index] ?? ("app.fill", .gray)

        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [iconData.color, iconData.color.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: iconData.icon)
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

 