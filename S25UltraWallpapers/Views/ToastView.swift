import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType
    @Binding var isPresented: Bool
    @Environment(\.appTheme) private var theme
    
    enum ToastType {
        case favorite
        case unfavorite
        case download
        case share
        case error
        case info
        
        var icon: String {
            switch self {
            case .favorite: return "heart.fill"
            case .unfavorite: return "heart.slash.fill"
            case .download: return "arrow.down.circle.fill"
            case .share: return "square.and.arrow.up.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var iconColor: Color {
            switch self {
            case .favorite, .unfavorite: return .red
            case .download: return .green
            case .share: return .blue
            case .error: return .red
            case .info: return .blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.iconColor)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
            
            Spacer()
            
            // Close button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(.black)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
        }
    }
}

