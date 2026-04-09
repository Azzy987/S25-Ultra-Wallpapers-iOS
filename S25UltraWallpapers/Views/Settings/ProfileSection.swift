import SwiftUI
import AuthenticationServices

struct ProfileSection: View {
    @StateObject private var userManager = UserManager.shared
    @Environment(\.appTheme) private var theme
    @State private var showSignInSheet = false

    var body: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Profile")

            VStack(spacing: 0) {
                // Avatar + info row
                HStack(spacing: 16) {
                    Group {
                        if let imageURL = userManager.profileImageURL,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(theme.onSurfaceVariant)
                                    .font(.system(size: 40))
                            }
                        } else {
                            Image(systemName: userManager.isSignedIn ? "person.circle.fill" : "person.circle")
                                .foregroundColor(theme.onSurfaceVariant)
                                .font(.system(size: 40))
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(userManager.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.onSurface)
                            if userManager.isPremium {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                            }
                        }
                        if userManager.isSignedIn {
                            Text(userManager.email)
                                .font(.system(size: 14))
                                .foregroundColor(theme.onSurfaceVariant)
                        } else {
                            Text("Sign in to sync your favorites")
                                .font(.system(size: 14))
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        if userManager.isPremium {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                Text("Premium Active")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)

                // Sign In / Sign Out button
                Button(action: {
                    if userManager.isSignedIn {
                        userManager.signOut()
                    } else {
                        showSignInSheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: userManager.isSignedIn
                              ? "rectangle.portrait.and.arrow.right"
                              : "person.badge.plus")
                            .foregroundColor(userManager.isSignedIn ? .red : theme.primary)
                            .font(.system(size: 16))

                        Text(userManager.isSignedIn ? "Sign Out" : "Sign In")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(userManager.isSignedIn ? .red : theme.primary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(theme.onSurfaceVariant)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.15), radius: 8, x: 0, y: 4)
                    .shadow(color: theme.onSurface.opacity(0.08), radius: 2, x: 0, y: 1)
            )
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInSheet()
                .environment(\.appTheme, theme)
        }
    }
}

// MARK: - Sign In Sheet

struct SignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var userManager = UserManager.shared
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(theme.onSurfaceVariant.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 28)

            // Icon
            ZStack {
                Circle()
                    .fill(theme.primaryContainer.opacity(0.3))
                    .frame(width: 72, height: 72)
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            .padding(.bottom, 20)

            // Title + subtitle
            Text("Sign in to continue")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(theme.onSurface)
                .padding(.bottom, 8)

            Text("Sync your favorites and premium status\nacross all your devices.")
                .font(.system(size: 15))
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.bottom, 36)

            VStack(spacing: 12) {
                // Sign in with Apple
                SignInWithAppleButton(.signIn) { request in
                    let appleRequest = userManager.appleSignInRequest()
                    request.requestedScopes = appleRequest.requestedScopes
                    request.nonce = appleRequest.nonce
                } onCompletion: { result in
                    userManager.handleAppleSignInResult(result)
                    // Dismiss once auth state updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if userManager.isSignedIn { dismiss() }
                    }
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 52)
                .cornerRadius(12)

                // Divider with "or"
                HStack(spacing: 12) {
                    Rectangle().fill(theme.onSurfaceVariant.opacity(0.2)).frame(height: 1)
                    Text("or")
                        .font(.system(size: 13))
                        .foregroundColor(theme.onSurfaceVariant)
                    Rectangle().fill(theme.onSurfaceVariant.opacity(0.2)).frame(height: 1)
                }

                // Sign in with Google
                Button(action: {
                    userManager.signInWithGoogle()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if userManager.isSignedIn { dismiss() }
                    }
                }) {
                    HStack(spacing: 10) {
                        // Google "G" logo drawn with text — no image asset needed
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 24, height: 24)
                            Text("G")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                        }

                        Text("Sign in with Google")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.onSurface)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.onSurfaceVariant.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)

            // Privacy note
            Text("By signing in you agree to our Terms of Use\nand Privacy Policy.")
                .font(.system(size: 12))
                .foregroundColor(theme.onSurfaceVariant.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 24)
                .padding(.horizontal, 32)

            Spacer(minLength: 32)
        }
        .background(theme.background.ignoresSafeArea())
        .modifier(SheetPresentationModifier())
        .onChange(of: userManager.isSignedIn) { signedIn in
            if signedIn { dismiss() }
        }
    }
}
// MARK: - iOS Version Compatibility

struct SheetPresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.height(520)])
                .presentationDragIndicator(.hidden)
        } else {
            content
        }
    }
}

