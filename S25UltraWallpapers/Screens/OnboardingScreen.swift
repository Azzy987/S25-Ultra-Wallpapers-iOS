import SwiftUI
import UserNotifications
import Photos

struct OnboardingScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    @State private var currentPage = 0
    @State private var backgroundImageAlpha: CGFloat = 0
    @State private var showingPermissionAlert = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background images with crossfade animation
            TabView(selection: $currentPage) {
                ForEach(0..<3, id: \.self) { page in
                    backgroundImage(for: page)
                        .tag(page)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .disabled(true) // Disable swipe gestures
            .opacity(backgroundImageAlpha)
            .animation(.easeInOut(duration: 1.0), value: backgroundImageAlpha)
            
            // Content overlay - not using TabView to avoid conflicts
            VStack {
                Spacer()
                
                if currentPage == 0 {
                    OnboardingPageView(
                        title: "Welcome to S25 Ultra Wallpapers",
                        description: "Explore a handpicked collection of stunning, high-quality wallpapers designed to give your phone a whole new vibe.",
                        buttonText: "Get Started",
                        pageNumber: 1,
                        totalPages: 3,
                        onButtonTap: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                currentPage = 1
                            }
                        }
                    )
                } else if currentPage == 1 {
                    OnboardingPageView(
                        title: "Storage Access",
                        description: "Give your phone a new look with beautiful **Depth Effect Wallpapers**.\nWe'll need storage access to save them for you.",
                        buttonText: "Grant Permission",
                        pageNumber: 2,
                        totalPages: 3,
                        onButtonTap: {
                            requestPhotoLibraryPermission()
                        }
                    )
                } else {
                    OnboardingPageView(
                        title: "Stay Updated",
                        description: "Stay inspired with daily wallpaper drops and special collections.\nEnable notifications so you never miss a new release!",
                        buttonText: "Enable Notifications",
                        pageNumber: 3,
                        totalPages: 3,
                        onButtonTap: {
                            requestNotificationPermission()
                        }
                    )
                }
            }
            
            // Skip button
            VStack {
                HStack {
                    Spacer()
                    Button(action: completeOnboarding) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(16)
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 60) // Add top padding for status bar
                Spacer()
            }
        }
        .ignoresSafeArea(.all) // Full screen including status bar and home indicator
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                backgroundImageAlpha = 1.0
            }
        }
    }
    
    private func backgroundImage(for page: Int) -> some View {
        Image("OnboardingScreen\(page + 1)")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .clipped()
            .ignoresSafeArea(.all)
    }
    
    private func requestPhotoLibraryPermission() {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    print("Photo library access granted")
                case .denied, .restricted:
                    print("Photo library access denied")
                case .notDetermined:
                    print("Photo library access not determined")
                @unknown default:
                    print("Unknown photo library authorization status")
                }
                
                // Move to next page regardless of permission result
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentPage = 2
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        hasCompletedOnboarding = true
        onComplete()
    }
}

struct OnboardingPageView: View {
    let title: String
    let description: String
    let buttonText: String
    let pageNumber: Int
    let totalPages: Int
    let onButtonTap: () -> Void
    
    @Environment(\.appTheme) private var theme
    @State private var containerAlpha: CGFloat = 0
    @State private var titleAlpha: CGFloat = 0
    @State private var descriptionAlpha: CGFloat = 0
    @State private var buttonAlpha: CGFloat = 0
    @State private var indicatorAlpha: CGFloat = 0
    @State private var buttonScale: CGFloat = 1.0
    @State private var isAnimating = false
    
    var body: some View {
        VStack {
            Spacer()
            
            // Content container
            VStack(spacing: 24) {
                // Title
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(titleAlpha)
                    .offset(y: titleAlpha == 0 ? 20 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.3), value: titleAlpha)
                
                // Description with markdown support
                Text(parseMarkdown(description))
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .opacity(descriptionAlpha)
                    .offset(y: descriptionAlpha == 0 ? 15 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.45), value: descriptionAlpha)
                
                // Button
                Button(action: onButtonTap) {
                    HStack {
                        Text(buttonText)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [theme.primary, theme.primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(buttonScale)
                .opacity(buttonAlpha)
                .offset(y: buttonAlpha == 0 ? 10 : 0)
                .animation(.easeOut(duration: 0.3).delay(0.6), value: buttonAlpha)
                .simultaneousGesture(TapGesture().onEnded {
                    // Add haptic feedback
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                })
                
                // Page indicators
                VStack(spacing: 12) {
                    Text("\(pageNumber)/\(totalPages)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.primary)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Circle()
                                .fill(index == pageNumber - 1 ? theme.primary : Color.white.opacity(0.3))
                                .frame(width: index == pageNumber - 1 ? 10 : 8, height: index == pageNumber - 1 ? 10 : 8)
                                .animation(.easeInOut(duration: 0.3), value: pageNumber)
                        }
                    }
                }
                .opacity(indicatorAlpha)
                .animation(.easeOut(duration: 0.25).delay(0.75), value: indicatorAlpha)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [theme.primary.opacity(0.7), theme.primary.opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .opacity(containerAlpha)
            .offset(y: containerAlpha == 0 ? 50 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.1), value: containerAlpha)
            .padding(.horizontal, 16)
            .padding(.bottom, 50) // Extra padding for home indicator area
        }
        .onAppear {
            startAnimations()
            startButtonPulse()
        }
        .id(pageNumber) // This will recreate the view when pageNumber changes
    }
    
    private func startAnimations() {
        containerAlpha = 1.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            titleAlpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            descriptionAlpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            buttonAlpha = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            indicatorAlpha = 1.0
        }
    }
    
    
    private func startButtonPulse() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                if buttonAlpha > 0.9 {
                    buttonScale = 1.05
                }
            }
        }
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text)
        } catch {
            return AttributedString(text)
        }
    }
}

#Preview {
    OnboardingScreen(onComplete: {})
        .environmentObject(ThemeManager.shared)
}