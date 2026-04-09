import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Premium Details Sheet
struct PremiumDetailsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var userManager = UserManager.shared
    @StateObject private var rcManager = RevenueCatManager.shared
    @State private var showCancelConfirmation = false
    @State private var isCancelling = false
    @State private var showCustomerCenter = false
    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Premium Status Header
                    premiumStatusHeader
                    
                    // Subscription Details
                    subscriptionDetails
                    
                    // Premium Features
                    premiumFeatures
                    
                    // Account Management
                    accountManagement
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Premium Details")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
        .alert("Cancel Premium?", isPresented: $showCancelConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Cancel Premium", role: .destructive) {
                cancelPremiumSubscription()
            }
        } message: {
            Text("Are you sure you want to cancel your premium subscription? You'll lose access to premium features.")
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreAlertMessage)
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
    }
    
    @ViewBuilder
    private var premiumStatusHeader: some View {
        VStack(spacing: 16) {
            // Premium badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Premium Active")
                .font(.title2.bold())
                .foregroundColor(theme.onSurface)
            
            Text("You have access to all premium features")
                .font(.subheadline)
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var subscriptionDetails: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Subscription Details")
                    .font(.headline.bold())
                    .foregroundColor(theme.onSurface)
                Spacer()
            }
            
            VStack(spacing: 12) {
                DetailRow(
                    title: "Plan Type",
                    value: userManager.premiumStatusText,
                    valueColor: theme.primary
                )
                
                if let activeSince = userManager.premiumActiveSince {
                    DetailRow(
                        title: "Active Since",
                        value: formatDate(activeSince),
                        valueColor: theme.onSurfaceVariant
                    )
                }
                
                if userManager.premiumType != .lifetime {
                    if let expiryDate = userManager.premiumExpiryDate {
                        let daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
                        
                        DetailRow(
                            title: "Expires On",
                            value: formatDate(expiryDate),
                            valueColor: daysRemaining < 7 ? .red : .orange
                        )
                        
                        DetailRow(
                            title: "Days Remaining",
                            value: "\(max(0, daysRemaining)) days",
                            valueColor: daysRemaining < 7 ? .red : .green
                        )
                    }
                } else {
                    DetailRow(
                        title: "Validity",
                        value: "Lifetime Access",
                        valueColor: .green
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    @ViewBuilder
    private var premiumFeatures: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Premium Features")
                    .font(.headline.bold())
                    .foregroundColor(theme.onSurface)
                Spacer()
            }
            
            VStack(spacing: 12) {
                FeatureRow(
                    icon: "photo.stack.fill",
                    title: "Unlimited Exclusive Wallpapers",
                    description: "Access to 1000+ premium wallpapers",
                    iconColor: .blue
                )
                
                FeatureRow(
                    icon: "eye.slash.fill",
                    title: "Ad-Free Experience",
                    description: "Browse without any advertisements",
                    iconColor: .green
                )
                
                FeatureRow(
                    icon: "camera.filters",
                    title: "Premium Filters",
                    description: "Professional editing filters",
                    iconColor: .purple
                )
                
                FeatureRow(
                    icon: "slider.horizontal.3",
                    title: "Advanced Editing Tools",
                    description: "Brightness, contrast, saturation controls",
                    iconColor: .orange
                )
                
                FeatureRow(
                    icon: "icloud.fill",
                    title: "Cloud Sync",
                    description: "Sync favorites across all devices",
                    iconColor: .cyan
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    @ViewBuilder
    private var accountManagement: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Account Management")
                    .font(.headline.bold())
                    .foregroundColor(theme.onSurface)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Restore Purchases Button
                Button(action: {
                    isRestoring = true
                    Task {
                        do {
                            try await rcManager.restorePurchases()
                            restoreAlertMessage = rcManager.isPro
                                ? "Your purchases have been restored successfully!"
                                : "No active purchases found for this Apple ID."
                        } catch {
                            restoreAlertMessage = error.localizedDescription
                        }
                        isRestoring = false
                        showRestoreAlert = true
                    }
                }) {
                    HStack {
                        if isRestoring {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundColor(theme.primary)
                        }
                        Text(isRestoring ? "Restoring..." : "Restore Purchases")
                            .foregroundColor(theme.onSurface)
                        Spacer()
                        if !isRestoring {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                    .padding()
                }
                .disabled(isRestoring)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.surfaceVariant.opacity(0.5))
                )

                // Manage Subscription via Customer Center
                Button(action: { showCustomerCenter = true }) {
                    HStack {
                        Image(systemName: "person.circle")
                            .foregroundColor(theme.primary)
                        Text("Manage Subscription")
                            .foregroundColor(theme.onSurface)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    }
                    .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.surfaceVariant.opacity(0.5))
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    // MARK: - Actions

    private func cancelPremiumSubscription() {
        // Cancellation is handled through Apple's subscription management
        // opened via the Customer Center sheet.
        showCustomerCenter = true
    }
}

// MARK: - Supporting Views

struct DetailRow: View {
    let title: String
    let value: String
    let valueColor: Color
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(theme.onSurfaceVariant)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PremiumDetailsSheet()
        .environmentObject(ThemeManager.shared)
}
#endif
