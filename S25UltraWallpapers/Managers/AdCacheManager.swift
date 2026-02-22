//
//  AdCacheManager.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import Foundation
import GoogleMobileAds
import UIKit
import SwiftUI

class AdCacheManager: NSObject, ObservableObject {
    static let shared = AdCacheManager()
    
    // Cache configuration
    private let maxCachedAds = 10 // Maximum number of cached ads
    private let preloadDistance = 3 // Preload ads 3 positions ahead
    
    // Cache storage
    private var nativeAdCache: [Int: NativeAd] = [:]
    private var adLoaders: [Int: AdLoader] = [:]
    private var adLoadingStates: [Int: Bool] = [:]
    
    // Cache metadata
    @Published var cachedAdPositions: Set<Int> = []
    @Published var loadingAdPositions: Set<Int> = []
    
    // Debouncing to prevent excessive loading
    private var loadingDebounceTimer: Timer?
    private var pendingLoadPositions: Set<Int> = []
    
    private override init() {
        super.init()
        print("🔄 AdCacheManager initialized")
    }
    
    // MARK: - Cache Management
    
    func getCachedAd(for position: Int) -> NativeAd? {
        return nativeAdCache[position]
    }
    
    func isAdCached(for position: Int) -> Bool {
        return nativeAdCache[position] != nil
    }
    
    func isAdLoading(for position: Int) -> Bool {
        return adLoadingStates[position] == true
    }
    
    func preloadAdsAround(position: Int, rootViewController: UIViewController) {
        // Add positions to pending load queue
        for offset in -preloadDistance...preloadDistance {
            let targetPosition = position + offset
            if targetPosition >= 0 {
                pendingLoadPositions.insert(targetPosition)
            }
        }
        
        // Debounce loading to prevent excessive requests
        loadingDebounceTimer?.invalidate()
        loadingDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.processPendingLoads(rootViewController: rootViewController)
            }
        }
        
        // Clean up distant ads
        cleanupDistantAds(currentPosition: position)
    }
    
    private func processPendingLoads(rootViewController: UIViewController) {
        let positionsToLoad = Array(pendingLoadPositions)
        pendingLoadPositions.removeAll()
        
        Task { @MainActor in
            let shouldShowAds = AdManager.shared.shouldShowAds()
            for position in positionsToLoad {
                preloadAdIfNeeded(for: position, rootViewController: rootViewController, shouldShowAds: shouldShowAds)
            }
        }
    }
    
    private func preloadAdIfNeeded(for position: Int, rootViewController: UIViewController, shouldShowAds: Bool) {
        // Don't load if already cached, loading, or user is premium
        guard !isAdCached(for: position),
              !isAdLoading(for: position),
              shouldShowAds else {
            return
        }
        
        loadNativeAd(for: position, rootViewController: rootViewController)
    }
    
    private func loadNativeAd(for position: Int, rootViewController: UIViewController) {
        print("🔄 Loading native ad for position \(position)")
        
        // Mark as loading
        adLoadingStates[position] = true
        DispatchQueue.main.async {
            self.loadingAdPositions.insert(position)
        }
        
        // Create ad loader
        let adLoader = AdManager.shared.createNativeAdLoader(
            rootViewController: rootViewController,
            delegate: self
        )
        
        adLoaders[position] = adLoader
        
        // Load the ad
        let request = Request()
        adLoader.load(request)
    }
    
    private func cleanupDistantAds(currentPosition: Int) {
        let cleanupDistance = maxCachedAds / 2
        let positions = Array(nativeAdCache.keys)
        
        for position in positions {
            let distance = abs(position - currentPosition)
            if distance > cleanupDistance {
                removeAdFromCache(position: position)
            }
        }
    }
    
    private func removeAdFromCache(position: Int) {
        nativeAdCache.removeValue(forKey: position)
        adLoadingStates.removeValue(forKey: position)
        adLoaders.removeValue(forKey: position)
        
        DispatchQueue.main.async {
            self.cachedAdPositions.remove(position)
            self.loadingAdPositions.remove(position)
        }
        
        print("🗑️ Removed ad from cache at position \(position)")
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStats() -> String {
        return """
        🔄 Ad Cache Statistics:
        Cached Ads: \(nativeAdCache.count)
        Loading Ads: \(loadingAdPositions.count)
        Max Cache Size: \(maxCachedAds)
        Cache Positions: \(Array(cachedAdPositions).sorted())
        """
    }
    
    func clearCache() {
        nativeAdCache.removeAll()
        adLoadingStates.removeAll()
        adLoaders.removeAll()
        
        DispatchQueue.main.async {
            self.cachedAdPositions.removeAll()
            self.loadingAdPositions.removeAll()
        }
        
        print("🗑️ Ad cache cleared")
    }
}

// MARK: - GADNativeAdLoaderDelegate

extension AdCacheManager: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        // Find which position this loader belongs to
        guard let position = adLoaders.first(where: { $0.value === adLoader })?.key else {
            print("❌ Could not find position for loaded ad")
            return
        }
        
        print("✅ Native ad loaded for position \(position)")
        
        // Cache the ad
        nativeAdCache[position] = nativeAd
        
        // Update loading state
        adLoadingStates[position] = false
        adLoaders.removeValue(forKey: position)
        
        DispatchQueue.main.async {
            self.cachedAdPositions.insert(position)
            self.loadingAdPositions.remove(position)
        }
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        // Find which position this loader belongs to
        guard let position = adLoaders.first(where: { $0.value === adLoader })?.key else {
            print("❌ Could not find position for failed ad load")
            return
        }
        
        print("❌ Failed to load native ad for position \(position): \(error.localizedDescription)")
        
        // Clean up loading state
        adLoadingStates[position] = false
        adLoaders.removeValue(forKey: position)
        
        DispatchQueue.main.async {
            self.loadingAdPositions.remove(position)
        }
        
        // Retry after a delay for important positions
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            if let rootVC = self?.findRootViewController() {
                Task { @MainActor in
                    let shouldShowAds = AdManager.shared.shouldShowAds()
                    self?.preloadAdIfNeeded(for: position, rootViewController: rootVC, shouldShowAds: shouldShowAds)
                }
            }
        }
    }
    
    private func findRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - Cached Native Ad View

struct CachedNativeAdView: View {
    let position: Int
    let height: CGFloat
    
    @Environment(\.appTheme) private var theme
    @StateObject private var cacheManager = AdCacheManager.shared
    @StateObject private var adManager = AdManager.shared
    
    init(position: Int, height: CGFloat = 320) {
        self.position = position
        self.height = max(height, 320) // Ensure minimum height of 320px
    }
    
    var body: some View {
        Group {
            if adManager.shouldShowAds() {
                if cacheManager.isAdCached(for: position) {
                    CachedNativeAdRepresentable(
                        position: position,
                        height: max(height, 320),
                        nativeAd: cacheManager.getCachedAd(for: position)!
                    )
                    .frame(height: max(height, 320))
                } else {
                    // Show loading placeholder with proper height
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                            .scaleEffect(0.9)
                        
                        Text("Loading Ad...")
                            .font(.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    .frame(height: max(height, 320))
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surfaceVariant.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .onAppear {
                        // Trigger ad loading when this position becomes visible
                        if let rootVC = findRootViewController() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                cacheManager.preloadAdsAround(
                                    position: position,
                                    rootViewController: rootVC
                                )
                            }
                        }
                    }
                }
            } else {
                // Premium users or ad-free mode - no ad space
                EmptyView()
            }
        }
    }
    
    private func findRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - Cached Native Ad Representable

struct CachedNativeAdRepresentable: UIViewRepresentable {
    let position: Int
    let height: CGFloat
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> CachedNativeAdUIView {
        let adView = CachedNativeAdUIView(nativeAd: nativeAd)
        
        return adView
    }
    
    func updateUIView(_ uiView: CachedNativeAdUIView, context: Context) {
        // Update if needed
    }
}

// MARK: - Cached Native Ad UI View

class CachedNativeAdUIView: UIView {
    private let nativeAd: NativeAd
    private var containerView: UIView?
    private var didSetup = false

    init(nativeAd: NativeAd) {
        self.nativeAd = nativeAd
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Defer setup until we have real bounds so Google SDK sees a non-zero size
        if !didSetup && bounds.width > 0 && bounds.height > 0 {
            didSetup = true
            setupAdView()
        }
    }

    private func setupAdView() {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground
        container.layer.cornerRadius = 12
        container.clipsToBounds = true

        // Media view first (large, horizontal) - minimum 300x150 per Google recommendation
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 12
        mediaView.mediaContent = nativeAd.mediaContent

        // Header row: icon + headline + body
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        if let iconImage = nativeAd.icon?.image {
            iconImageView.image = iconImage
        }

        let headlineLabel = UILabel()
        headlineLabel.font = .boldSystemFont(ofSize: 15)
        headlineLabel.numberOfLines = 1
        headlineLabel.text = nativeAd.headline

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.text = nativeAd.body

        let adLabel = UILabel()
        adLabel.text = "Ad"
        adLabel.font = .boldSystemFont(ofSize: 10)
        adLabel.textColor = .white
        adLabel.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.9)
        adLabel.textAlignment = .center
        adLabel.layer.cornerRadius = 4
        adLabel.clipsToBounds = true

        let callToActionButton = UIButton(type: .system)
        callToActionButton.backgroundColor = .systemBlue
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)

        [mediaView, iconImageView, headlineLabel, bodyLabel, adLabel, callToActionButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview($0)
        }

        // Layout: media on top (large horizontal), then info row below
        NSLayoutConstraint.activate([
            // Media view - large horizontal area at top
            mediaView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            mediaView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            mediaView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            mediaView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            mediaView.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: 0.6),

            // Ad label - small badge below media
            adLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
            adLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            adLabel.widthAnchor.constraint(equalToConstant: 24),
            adLabel.heightAnchor.constraint(equalToConstant: 16),

            // Icon
            iconImageView.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
            iconImageView.leadingAnchor.constraint(equalTo: adLabel.trailingAnchor, constant: 8),
            iconImageView.widthAnchor.constraint(equalToConstant: 36),
            iconImageView.heightAnchor.constraint(equalToConstant: 36),

            // Headline
            headlineLabel.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 8),
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            headlineLabel.trailingAnchor.constraint(equalTo: callToActionButton.leadingAnchor, constant: -8),

            // Body
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2),
            bodyLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            bodyLabel.trailingAnchor.constraint(equalTo: callToActionButton.leadingAnchor, constant: -8),

            // CTA button - right side
            callToActionButton.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            callToActionButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            callToActionButton.widthAnchor.constraint(equalToConstant: 90),
            callToActionButton.heightAnchor.constraint(equalToConstant: 34),
            callToActionButton.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -8)
        ])

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        containerView = container
    }
}
