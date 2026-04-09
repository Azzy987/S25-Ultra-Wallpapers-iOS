import SwiftUI

/// Shown once (before the paywall) so users can read and accept the Privacy Policy.
/// After accepting, sets "privacy_policy_accepted" = true and calls onAccept.
struct PrivacyConsentScreen: View {
    let onAccept: () -> Void

    @Environment(\.appTheme) private var theme
    @State private var showFullPolicy = false

    private let summary = """
    Before you continue, please review how we handle your data.

    • We collect anonymous usage analytics to improve the app.
    • If you sign in, we store your account info securely via Firebase.
    • We use RevenueCat to manage purchases — no card details are stored by us.
    • We never sell your personal data to third parties.

    Tap "Privacy Policy" to read the full policy.
    """

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(paywallAccent.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 36))
                        .foregroundColor(paywallAccent)
                }

                Spacer().frame(height: 24)

                Text("Privacy & Data")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.onSurface)

                Spacer().frame(height: 8)

                Text("We care about your privacy")
                    .font(.system(size: 14))
                    .foregroundColor(theme.onSurfaceVariant)

                Spacer().frame(height: 28)

                // Summary card
                Text(summary)
                    .font(.system(size: 14))
                    .foregroundColor(theme.onSurface)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(theme.surfaceVariant.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.onSurface.opacity(0.08), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                // Read full policy link
                Button {
                    showFullPolicy = true
                } label: {
                    Text("Read Full Privacy Policy →")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(paywallAccent)
                }

                Spacer()

                // Accept button
                Button(action: accept) {
                    Text("I Understand & Accept")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(paywallAccent)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 12)

                Text("By accepting you agree to our Privacy Policy and Terms of Use.")
                    .font(.system(size: 11))
                    .foregroundColor(theme.onSurfaceVariant.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 32)
            }
        }
        .sheet(isPresented: $showFullPolicy) {
            PrivacyPolicySheet()
                .environment(\.appTheme, theme)
        }
    }

    private func accept() {
        UserDefaults.standard.set(true, forKey: "privacy_policy_accepted")
        onAccept()
    }
}
