//
//  NativeAdView.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import SwiftUI
import GoogleMobileAds
import UIKit

// MARK: - SwiftUI Native Ad View

struct NativeAdView: View {
    let height: CGFloat
    @Environment(\.appTheme) var theme
    @StateObject private var adManager = AdManager.shared
    
    init(height: CGFloat = 320) {
        self.height = height
    }
    
    var body: some View {
        Group {
            if adManager.shouldShowAds() {
                NativeAdRepresentable(height: height)
                    .frame(height: height)
                    .background(theme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.onSurfaceVariant.opacity(0.2), lineWidth: 1)
                    )
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - UIViewRepresentable for Native Ad

struct NativeAdRepresentable: UIViewRepresentable {
    let height: CGFloat

    func makeUIView(context: Context) -> NativeAdUIView {
        let screenWidth = UIScreen.main.bounds.width
        let adView = NativeAdUIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: height))
        adView.loadAd()
        return adView
    }

    func updateUIView(_ uiView: NativeAdUIView, context: Context) {
        // No updates needed
    }
}

// MARK: - UIView for Native Ad

class NativeAdUIView: UIView {
    private var adLoader: AdLoader?
    private var adContainerView: UIView?
    private var heightConstraint: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.systemBackground
        layer.cornerRadius = 16
        clipsToBounds = true
        
        // Add loading indicator
        let loadingView = createLoadingView()
        addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: 30),
            loadingView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func createLoadingView() -> UIView {
        let container = UIView()
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.startAnimating()
        
        container.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    func loadAd() {
        guard let rootViewController = findViewController() else {
            print("❌ Could not find root view controller for native ad")
            return
        }
        
        adLoader = AdManager.shared.createNativeAdLoader(
            rootViewController: rootViewController,
            delegate: self
        )
        
        adLoader?.load(Request())
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}

// MARK: - GADNativeAdLoaderDelegate

extension NativeAdUIView: NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("✅ Native ad received")
        
        // Remove loading indicator
        subviews.forEach { $0.removeFromSuperview() }
        
        // Create native ad view programmatically
        // Note: Using programmatic approach since native ad view from nib may not be compatible with current SDK
        createProgrammaticNativeAdView(nativeAd: nativeAd)
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ Native ad failed to load: \(error.localizedDescription)")
        
        // Remove loading indicator and show error state
        subviews.forEach { $0.removeFromSuperview() }
        
        let errorLabel = UILabel()
        errorLabel.text = "Ad not available"
        errorLabel.textColor = .secondaryLabel
        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.textAlignment = .center
        
        addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func createProgrammaticNativeAdView(nativeAd: NativeAd) {
        let container = UIView()
        container.backgroundColor = UIColor.systemBackground

        // Media view first (large, horizontal) - minimum 300x150 per Google recommendation
        let mediaView = MediaView()
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.layer.cornerRadius = 12

        // Header row: icon + headline + body
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true

        let headlineLabel = UILabel()
        headlineLabel.font = .boldSystemFont(ofSize: 15)
        headlineLabel.numberOfLines = 1

        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2

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

            // Ad label - small badge top-left of media
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

        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        if let iconImage = nativeAd.icon?.image {
            iconImageView.image = iconImage
        }
        mediaView.mediaContent = nativeAd.mediaContent

        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        self.adContainerView = container
    }
    
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Native Ad Example")
            .font(.headline)
        
        NativeAdView(height: 320)
            .padding(.horizontal)
        
        Spacer()
    }
    .environment(\.appTheme, AppColors.light)
}