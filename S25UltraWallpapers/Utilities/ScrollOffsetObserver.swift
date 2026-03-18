import SwiftUI
import UIKit

/// A tiny UIViewRepresentable that finds its nearest ancestor UIScrollView
/// and observes contentOffset via KVO. Much more reliable than GeometryReader
/// + PreferenceKey for tracking scroll position, especially when combined
/// with SwiftUI gestures on parent views.
struct ScrollOffsetObserver: UIViewRepresentable {
    let onOffsetChange: (CGFloat) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onOffsetChange: onOffsetChange)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        context.coordinator.view = view
        // Retry lookup multiple times since the view hierarchy may not be fully assembled
        context.coordinator.scheduleScrollViewLookup()
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onOffsetChange = onOffsetChange
    }

    class Coordinator: NSObject {
        var onOffsetChange: (CGFloat) -> Void
        weak var view: UIView?
        private var observation: NSKeyValueObservation?
        private weak var observedScrollView: UIScrollView?
        private var retryCount = 0
        private let maxRetries = 5

        init(onOffsetChange: @escaping (CGFloat) -> Void) {
            self.onOffsetChange = onOffsetChange
        }

        func scheduleScrollViewLookup() {
            // Try immediately on next runloop, then retry with increasing delays
            DispatchQueue.main.async { [weak self] in
                self?.findAndObserveScrollView()
            }
        }

        func findAndObserveScrollView() {
            guard let view = view else { return }
            var current: UIView? = view.superview
            while let sv = current {
                if let scrollView = sv as? UIScrollView {
                    guard scrollView !== observedScrollView else { return }
                    observation?.invalidate()
                    observedScrollView = scrollView
                    observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, change in
                        guard let self = self, let offset = change.newValue else { return }
                        DispatchQueue.main.async {
                            self.onOffsetChange(-offset.y)
                        }
                    }
                    return
                }
                current = sv.superview
            }
            // If not found, retry with delay (view hierarchy may not be ready)
            retryCount += 1
            if retryCount <= maxRetries {
                let delay = Double(retryCount) * 0.1
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.findAndObserveScrollView()
                }
            }
        }

        deinit {
            observation?.invalidate()
        }
    }
}
