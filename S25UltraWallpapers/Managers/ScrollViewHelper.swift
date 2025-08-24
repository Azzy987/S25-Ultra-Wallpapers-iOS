import SwiftUI

class ScrollViewHelper: ObservableObject {
    @Published var showScrollToTop = false
    @Published var shouldScrollToTop = false
    private var lastOffset: CGFloat = 0

    func updateScrollPosition(_ offset: CGFloat) {
        let threshold: CGFloat = 300
        let isScrolledPastThreshold = offset > threshold

        if showScrollToTop != isScrolledPastThreshold {
            withAnimation {
                showScrollToTop = isScrolledPastThreshold
            }
        }

      //  print("Scroll offset: \(offset), Show button: \(showScrollToTop)")
    }
}
