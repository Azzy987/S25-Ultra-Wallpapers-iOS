import SwiftUI

// iOS compatibility modifier for ScrollTargetBehavior
struct ScrollTargetBehaviorCompatModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.scrollTargetBehavior(.paging)
        } else {
            content
        }
    }
} 