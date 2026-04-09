import SwiftUI
import RevenueCat

// MARK: - Shared accent color for paywall

let paywallAccent = Color(red: 0.49, green: 0.38, blue: 1.0)

// MARK: - OnboardingPaywallScreen
// Shown once after onboarding. No close button — "Maybe Later" is the only exit.

struct OnboardingPaywallScreen: View {
    let onDone: () -> Void

    @StateObject private var rcManager = RevenueCatManager.shared
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false

    var body: some View {
        PaywallContentView(
            showCloseButton: false,
            onDismiss: {
                UserDefaults.standard.set(true, forKey: "paywall_shown_after_onboarding")
                onDone()
            }
        )
        .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicySheet() }
        .sheet(isPresented: $showTerms) { TermsOfUseSheet() }
        .task { await rcManager.refreshAll() }
    }
}

// MARK: - PaywallContentView
// Single source of truth for paywall UI — used by both OnboardingPaywallScreen and PremiumScreen.

struct PaywallContentView: View {
    let showCloseButton: Bool
    let onDismiss: () -> Void

    @StateObject private var rcManager = RevenueCatManager.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    @Environment(\.appTheme) private var theme
    @State private var carouselIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var isPurchasing = false
    @State private var purchaseError: String? = nil
    @State private var showPrivacyPolicy = false
    @State private var showTerms = false
    @State private var carouselTimer: Timer?

    private let cardGap: CGFloat = 14

    private var lifetimePackage: Package? {
        rcManager.currentOffering?.lifetime
            ?? rcManager.currentOffering?.availablePackages.first(where: { $0.packageType == .lifetime })
            ?? rcManager.currentOffering?.availablePackages.first
    }

    private var priceString: String {
        lifetimePackage?.storeProduct.localizedPriceString ?? "$4.99"
    }

    // Derived colors based on current theme
    private var bgColor: Color { theme.background }
    private var cardBgColor: Color { theme.surface }
    private var textPrimary: Color { theme.onSurface }
    private var textSecondary: Color { theme.onSurfaceVariant }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background
                bgColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // ── Header ──────────────────────────────────────────────
                    headerSection
                        .padding(.top, 10)
                        .padding(.bottom, 10)

                    // ── Carousel ─────────────────────────────────────────────
                    let carouselH = geo.size.height * 0.44
                    carouselSection(totalWidth: geo.size.width, height: carouselH)

                    // ── Features ─────────────────────────────────────────────
                    featuresSection
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                    // ── Bottom card ──────────────────────────────────────────
                    Spacer(minLength: 0)
                    bottomCard(bottomInset: geo.safeAreaInsets.bottom)
                }
                .ignoresSafeArea(edges: .bottom)

                // Optional close button (Settings → Premium path only)
                if showCloseButton {
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(textPrimary)
                                .padding(9)
                                .background(textPrimary.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.top, 12)
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) { PrivacyPolicySheet() }
        .sheet(isPresented: $showTerms) { TermsOfUseSheet() }
        .alert("Purchase Error", isPresented: .constant(purchaseError != nil)) {
            Button("OK") { purchaseError = nil }
        } message: {
            Text(purchaseError ?? "")
        }
        .onAppear { startAutoAdvance() }
        .onDisappear { carouselTimer?.invalidate(); carouselTimer = nil }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text("GO PREMIUM")
                .font(.system(size: 11, weight: .bold))
                .tracking(2)
                .foregroundColor(paywallAccent)

            Text("Unlock Everything")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(textPrimary)
        }
    }

    // MARK: Carousel

    private func carouselSection(totalWidth: CGFloat, height: CGFloat) -> some View {
        // Extra vertical room so rotating card corners don't clip at top/bottom
        return VStack(spacing: 12) {
            peekCarousel(totalWidth: totalWidth, height: height, containerHeight: height)
                .frame(width: totalWidth, height: height)
                .clipped()

            // Dots inside a glass capsule container
            dotsContainer
        }
        .onAppear {
            if firebaseManager.paywallBanners.isEmpty {
                firebaseManager.loadPaywallBanners()
            }
        }
    }

    // MARK: Peek Carousel
    //
    // Layout:  card[i].centerX = totalWidth/2 + (i - carouselIndex) * step + dragOffset
    // Active card: full scale. Neighbours: 94% scale, so they clearly sit behind.
    // Transition: spring slide + simultaneous scale pulse on the incoming card.

    @ViewBuilder
    private func peekCarousel(totalWidth: CGFloat, height: CGFloat, containerHeight: CGFloat) -> some View {
        let cardWidth = totalWidth * 0.74
        let step = cardWidth + cardGap
        let banners = firebaseManager.paywallBanners

        if banners.isEmpty {
            ShimmerCardView(width: cardWidth, height: height)
                .frame(width: cardWidth, height: height)
                .position(x: totalWidth / 2, y: containerHeight / 2)
        } else {
            let count = banners.count
            ZStack {
                // Render back-to-front: furthest cards drawn first, active on top
                ForEach(banners.indices.sorted { abs($0 - carouselIndex) > abs($1 - carouselIndex) }, id: \.self) { i in
                    let offset = i - carouselIndex
                    if abs(offset) <= 2 {
                        let centerX = totalWidth / 2 + CGFloat(offset) * step + dragOffset
                        // Active card full size; each step back shrinks by 6%
                        let scale: CGFloat = offset == 0 ? 1.0 : (1.0 - CGFloat(abs(offset)) * 0.06)

                        carouselCard(url: banners[i], cardWidth: cardWidth, height: height)
                            .scaleEffect(scale)
                            .position(x: centerX, y: containerHeight / 2)
                            .zIndex(Double(10 - abs(offset)))
                            // Smooth spring for the position slide
                            .animation(.spring(response: 0.55, dampingFraction: 0.82), value: carouselIndex)
                            .animation(.spring(response: 0.55, dampingFraction: 0.82), value: dragOffset)
                    }
                }
            }
            .frame(width: totalWidth, height: containerHeight)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let isAtStart = carouselIndex == 0 && value.translation.width > 0
                        let isAtEnd = carouselIndex == count - 1 && value.translation.width < 0
                        dragOffset = isAtStart || isAtEnd
                            ? value.translation.width * 0.2
                            : value.translation.width
                    }
                    .onEnded { value in
                        let threshold = cardWidth * 0.22
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            if value.translation.width < -threshold {
                                carouselIndex = min(carouselIndex + 1, count - 1)
                            } else if value.translation.width > threshold {
                                carouselIndex = max(carouselIndex - 1, 0)
                            }
                            dragOffset = 0
                        }
                    }
            )
        }
    }

    @ViewBuilder
    private func carouselCard(url: String, cardWidth: CGFloat, height: CGFloat) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty:
                ShimmerCardView(width: cardWidth, height: height)
            default:
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.2))
            }
        }
        .frame(width: cardWidth, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func animateToIndex(_ newIndex: Int) {
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            carouselIndex = newIndex
            dragOffset = 0
        }
    }

    // MARK: Dots

    @ViewBuilder
    private var dotsContainer: some View {
        let count = firebaseManager.paywallBanners.isEmpty ? 3 : firebaseManager.paywallBanners.count
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                let isActive = firebaseManager.paywallBanners.isEmpty ? false : i == carouselIndex
                Capsule()
                    .fill(isActive ? paywallAccent : textSecondary.opacity(0.35))
                    .frame(width: isActive ? 18 : 6, height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: carouselIndex)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(cardBgColor)
        .clipShape(Capsule())
        .shadow(color: textPrimary.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: textPrimary.opacity(0.08), radius: 2, x: 0, y: 1)
    }

    // MARK: Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PaywallFeatureRow(text: "Ad-free experience", systemImage: "minus.circle", delay: 0.1)
            PaywallFeatureRow(text: "500+ Exclusive wallpapers", systemImage: "photo.stack", delay: 0.25)
            PaywallFeatureRow(text: "Unlock all premium filters", systemImage: "sparkles", delay: 0.4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
    }

    // MARK: Bottom card

    private func bottomCard(bottomInset: CGFloat) -> some View {
        VStack(spacing: 12) {
            // Plan card
            ZStack(alignment: .top) {
                VStack(spacing: 3) {
                    Text(priceString)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textPrimary)
                    Text("One-time purchase · Forever access")
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .padding(.top, 6)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(textPrimary.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(paywallAccent.opacity(0.5), lineWidth: 1.5)
                        )
                )

                // BEST OFFER badge on top border
                Text("BEST OFFER")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(paywallAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .offset(y: -10)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            // CTA button
            Button(action: purchaseLifetime) {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Get Lifetime Access →")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(paywallAccent)
                .clipShape(Capsule())
            }
            .disabled(isPurchasing)
            .padding(.horizontal, 20)

            // Maybe Later
            Button(action: {
                UserDefaults.standard.set(true, forKey: "paywall_shown_after_onboarding")
                onDismiss()
            }) {
                Text("Maybe Later")
                    .font(.system(size: 14))
                    .foregroundColor(textSecondary.opacity(0.7))
            }

            // Footer links
            HStack(spacing: 4) {
                Button("Privacy Policy") { showPrivacyPolicy = true }
                    .foregroundColor(textSecondary.opacity(0.6))
                Text("·").foregroundColor(textSecondary.opacity(0.5))
                Button("Terms of Use") { showTerms = true }
                    .foregroundColor(textSecondary.opacity(0.6))
            }
            .font(.system(size: 11))

            // Safe area spacer
            Spacer().frame(height: max(bottomInset, 8))
        }
        // Clip content to the rounded-top shape
        .clipShape(PaywallTopRoundedShape())
        // Fill behind the clipped content
        .background(
            PaywallTopRoundedShape()
                .fill(cardBgColor)
                .ignoresSafeArea(edges: .bottom)
        )
        // Shadow applied OUTSIDE the clip so it isn't cut off
        .shadow(color: textPrimary.opacity(0.14), radius: 16, x: 0, y: -6)
        .shadow(color: textPrimary.opacity(0.07), radius: 4, x: 0, y: -2)
    }

    // MARK: Purchase

    private func purchaseLifetime() {
        guard let pkg = lifetimePackage else {
            UserDefaults.standard.set(true, forKey: "paywall_shown_after_onboarding")
            onDismiss()
            return
        }
        isPurchasing = true
        Task {
            do {
                let purchased = try await rcManager.purchase(package: pkg)
                isPurchasing = false
                if purchased {
                    UserDefaults.standard.set(true, forKey: "paywall_shown_after_onboarding")
                    onDismiss()
                }
            } catch {
                isPurchasing = false
                purchaseError = error.localizedDescription
            }
        }
    }

    private func startAutoAdvance() {
        carouselTimer?.invalidate()
        carouselTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
            let count = firebaseManager.paywallBanners.count
            guard count > 1 else { return }
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                carouselIndex = (carouselIndex + 1) % count
            }
        }
    }
}

// MARK: - Shimmer card

struct ShimmerCardView: View {
    let width: CGFloat
    let height: CGFloat
    @State private var offset: CGFloat = 0

    var body: some View {
        let shimmerColors: [Color] = [
            Color.white.opacity(0.05),
            Color.white.opacity(0.15),
            Color.white.opacity(0.05)
        ]
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.gray.opacity(0.25))
            .overlay(
                LinearGradient(
                    colors: shimmerColors,
                    startPoint: UnitPoint(x: offset - 0.4, y: offset - 0.4),
                    endPoint: UnitPoint(x: offset, y: offset)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    offset = 1
                }
            }
    }
}

// MARK: - Paywall feature row

struct PaywallFeatureRow: View {
    let text: String
    let systemImage: String
    let delay: Double
    @State private var visible = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 15))
                .foregroundColor(paywallAccent)
                .frame(width: 22, height: 22)
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .opacity(visible ? 1 : 0)
        .offset(x: visible ? 0 : -32)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) { visible = true }
            }
        }
    }
}

// MARK: - Shape helper

struct PaywallTopRoundedShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 24
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                    radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                    radius: radius, startAngle: .degrees(180), endAngle: .degrees(-90), clockwise: false)
        path.closeSubpath()
        return path
    }
}
