import SwiftUI

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    private let content = """
    Privacy Policy

    Last updated: [Date]

    We respect your privacy and are committed to protecting your personal data.

    1. Information We Collect
    - Device information for crash reporting
    - Usage analytics to improve the app
    - Account information if you sign in

    2. How We Use Information
    - To provide and maintain our service
    - To notify you about changes to our service
    - To provide customer support

    3. Data Security
    We implement appropriate security measures to protect your personal information.

    4. Contact Us
    If you have questions about this Privacy Policy, contact us at: droidates@gmail.com
    """

    var body: some View {
        legalSheet(title: "Privacy Policy", content: content)
    }
}

struct TermsOfUseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    private let content = """
    Terms of Use

    Last updated: [Date]

    By using this app, you agree to these terms.

    1. Acceptable Use
    - Use the app only for lawful purposes
    - Do not attempt to reverse engineer the app
    - Respect intellectual property rights

    2. Premium Features
    - Premium subscriptions provide access to exclusive content
    - Subscriptions auto-renew unless cancelled
    - Refunds subject to App Store policies

    3. Limitation of Liability
    The app is provided "as is" without warranties.

    4. Changes to Terms
    We may update these terms from time to time.

    5. Contact
    Questions about these terms: droidates@gmail.com
    """

    var body: some View {
        legalSheet(title: "Terms of Use", content: content)
    }
}

// MARK: - Shared builder

private func legalSheet(title: String, content: String) -> some View {
    _LegalSheet(title: title, content: content)
}

private struct _LegalSheet: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Divider()

                ScrollView {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundColor(theme.onBackground)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                }
                .background(theme.background)

                Divider()

                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(theme.surface)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .background(theme.background)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(theme.themeType == .dark ? .dark : .light)
        .modifier(LargeDetentModifier())
    }
}

private struct LargeDetentModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}
