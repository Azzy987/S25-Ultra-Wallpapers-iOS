import SwiftUI

struct SyncFloatingButton: View {
    @Binding var isSyncing: Bool
    let onSync: () async -> Void
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: {
            Task {
                await onSync()
            }
        }) {
            HStack(spacing: 8) {
                if isSyncing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(isSyncing ? "Syncing..." : "Sync")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: isSyncing ? [.gray, .gray.opacity(0.8)] : [theme.primary, theme.primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: theme.primary.opacity(0.3), radius: 6, x: 0, y: 3)
            )
        }
        .disabled(isSyncing)
        .animation(.easeInOut(duration: 0.2), value: isSyncing)
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    VStack(spacing: 20) {
        SyncFloatingButton(isSyncing: .constant(false)) {
            // Mock sync action
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        SyncFloatingButton(isSyncing: .constant(true)) {
            // Mock sync action
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}
#endif