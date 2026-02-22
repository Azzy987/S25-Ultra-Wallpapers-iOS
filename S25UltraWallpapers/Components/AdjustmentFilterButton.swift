// AdjustmentFilterButton.swift
import SwiftUI

struct AdjustmentFilterButton: View {
    // MARK: - Properties
    let title: String
    let icon: String
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void
    let onLockedTap: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            if isLocked {
                onLockedTap()
            } else {
                action()
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isSelected ? theme.primary : theme.surfaceVariant)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
                        )
                        .shadow(
                            color: isSelected ? theme.primary.opacity(0.3) : theme.onSurface.opacity(0.1),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? 4 : 2
                        )
                        .opacity(isLocked ? 0.6 : 1.0)
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .white : (isLocked ? theme.onSurface.opacity(0.6) : theme.onSurface))
                    
                    // Lock overlay for locked filters
                    if isLocked {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 64, height: 64)
                            .overlay(
                                VStack(spacing: 2) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("TAP")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(0.9)
                                }
                            )
                    }
                }
                
                // Title with lock indicator
                HStack(spacing: 4) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(theme.primary)
                    }
                    
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundColor(isLocked ? theme.onSurface.opacity(0.6) : theme.onSurface)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isLocked)
    }
}

// MARK: - Preview
struct AdjustmentFilterButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            AdjustmentFilterButton(
                title: "Brightness",
                icon: "sun.max",
                isSelected: false,
                isLocked: false,
                action: {},
                onLockedTap: {}
            )
            
            AdjustmentFilterButton(
                title: "Contrast",
                icon: "circle.lefthalf.filled",
                isSelected: true,
                isLocked: false,
                action: {},
                onLockedTap: {}
            )
            
            AdjustmentFilterButton(
                title: "Saturation",
                icon: "drop.fill",
                isSelected: false,
                isLocked: true,
                action: {},
                onLockedTap: {}
            )
        }
        .padding()
        .environment(\.appTheme, AppColors.dark)
        .background(Color.black)
    }
}