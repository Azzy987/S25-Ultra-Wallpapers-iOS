//
//  SplashScreen.swift
//  S25UltraWallpapers
//
//  Created by Azam on 11/09/25.
//

import SwiftUI

struct SplashScreen: View {
    @State private var isIconAnimating = false
    @State private var showTitle = false
    @State private var showLoadingDots = false
    @State private var pulseAnimation = false
    @State private var backgroundGradientPhase: CGFloat = 0.0
    @State private var sparkleOpacity: Double = 0.0
    
    let onSplashComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.9),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color.black.opacity(0.95)
                ],
                startPoint: UnitPoint(x: 0.0 + backgroundGradientPhase, y: 0.0),
                endPoint: UnitPoint(x: 1.0 + backgroundGradientPhase, y: 1.0)
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: backgroundGradientPhase)
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Icon with animations
                ZStack {
                    // Pulsing background circle
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.3 : 0.6)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    // Sparkle effects around icon
                    ForEach(0..<8) { index in
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 4, height: 4)
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 90,
                                y: sin(Double(index) * .pi / 4) * 90
                            )
                            .opacity(sparkleOpacity)
                            .scaleEffect(sparkleOpacity)
                            .animation(
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: sparkleOpacity
                            )
                    }
                    
                    // App Icon
                    Image("LaunchImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                        .scaleEffect(isIconAnimating ? 1.0 : 0.8)
                        .rotationEffect(.degrees(isIconAnimating ? 0 : -10))
                        .animation(.spring(response: 1.2, dampingFraction: 0.8), value: isIconAnimating)
                }
                
                // App Title with typewriter effect
                VStack(spacing: 8) {
                    if showTitle {
                        Text("S25 Ultra Wallpapers")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .gray.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        
                        Text("Premium Wallpapers Collection")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .animation(.easeOut(duration: 0.8).delay(0.5), value: showTitle)
                
                Spacer()
                
                // Loading animation
                if showLoadingDots {
                    LoadingDotsView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                    .frame(height: 100)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Start background gradient animation immediately
        backgroundGradientPhase = 0.3
        
        // Start pulse animation immediately
        pulseAnimation = true
        
        // Start icon animation immediately for seamless transition from launch screen
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            isIconAnimating = true
        }
        
        // Show title quickly after icon animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                showTitle = true
            }
        }
        
        // Show sparkle effects earlier
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            sparkleOpacity = 1.0
        }
        
        // Show loading dots
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.6)) {
                showLoadingDots = true
            }
        }
        
        // Monitor Firebase initialization and complete splash screen
        monitorAppInitialization()
    }
    
    private func monitorAppInitialization() {
        let startTime = Date()
        
        // Check Firebase initialization status periodically
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            // Check if Firebase is ready and data is loaded
            let firebaseManager = FirebaseManager.shared
            if firebaseManager.isInitialized && !firebaseManager.wallpapers.isEmpty {
                timer.invalidate()
                
                // Ensure minimum display time of 2.5 seconds for better UX
                let minimumDisplayTime = 2.5
                let elapsedTime = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, minimumDisplayTime - elapsedTime)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        onSplashComplete()
                    }
                }
            }
        }
    }
}

struct LoadingDotsView: View {
    @State private var animationStates: [Bool] = [false, false, false]
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationStates[index] ? 1.3 : 0.8)
                    .opacity(animationStates[index] ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: animationStates[index]
                    )
            }
        }
        .onAppear {
            for index in 0..<3 {
                animationStates[index] = true
            }
        }
    }
}

#Preview {
    SplashScreen {
        print("Splash completed")
    }
}
