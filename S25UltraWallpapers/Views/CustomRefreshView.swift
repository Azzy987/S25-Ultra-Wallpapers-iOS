//
//  CustomRefreshView.swift
//  S25UltraWallpapers
//
//  Created by Azam on 24/08/25.
//

import SwiftUI

// MARK: Custom View Builder
struct CustomRefreshView<Content: View>: View {
    var content: Content
    var showsIndicator: Bool
    // MARK: Async Call Back
    var onRefresh: ()async->()
    init(showsIndicator: Bool = false,@ViewBuilder content: @escaping ()->Content,onRefresh: @escaping ()async->()){
        self.showsIndicator = showsIndicator
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    @StateObject var scrollDelegate: ScrollViewModel = .init()
    var body: some View {
        ScrollView(.vertical, showsIndicators: showsIndicator) {
            VStack(spacing: 0){
                // Since We Need It From Dynamic Island
                // Making it as Transparent 150px Height Rectangle
                Rectangle()
                    .fill(.clear)
                    .frame(height: 150 * scrollDelegate.progress)
                
                content
            }
            .offset(coordinateSpace: "SCROLL") { offset in
                // MARK: Storing Content Offset
                scrollDelegate.contentOffset = offset
                
                // MARK: Stopping The Progress When Its Elgible For Refresh
                if !scrollDelegate.isEligible{
                    var progress = offset / 150
                    progress = (progress < 0 ? 0 : progress)
                    progress = (progress > 1 ? 1 : progress)
                    scrollDelegate.scrollOffset = offset
                    scrollDelegate.progress = progress
                }
                
                if scrollDelegate.isEligible && !scrollDelegate.isRefreshing{
                    scrollDelegate.isRefreshing = true
                    // MARK: Haptic Feedback
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
        .overlay(alignment: .top, content: {
            // Simple pull-to-refresh indicator for all devices
            if scrollDelegate.progress > 0 {
                VStack(spacing: 12) {
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                            .frame(width: 40, height: 40)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: scrollDelegate.progress)
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                        
                        // Icon/Loading state
                        if scrollDelegate.isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: scrollDelegate.isEligible ? "checkmark" : "arrow.down")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .rotationEffect(.degrees(scrollDelegate.isEligible ? 0 : scrollDelegate.progress * 180))
                        }
                    }
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                            .frame(width: 50, height: 50)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .opacity(scrollDelegate.progress)
                    .animation(.easeInOut(duration: 0.2), value: scrollDelegate.isEligible)
                    .animation(.easeInOut(duration: 0.2), value: scrollDelegate.isRefreshing)
                }
                .padding(.top, getSafeAreaTop() + 20)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false) // Don't block touch events
            }
        })
        .coordinateSpace(name: "SCROLL")
        .onAppear(perform: scrollDelegate.addGesture)
        .onDisappear(perform: scrollDelegate.removeGesture)
        .onChange(of: scrollDelegate.isRefreshing) { newValue in
            // MARK: Calling Async Method
            if newValue{
                Task{
                    // MARK: 1 Sec Sleep For Smooth Animation
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    await onRefresh()
                    // MARK: After Refresh Done Resetting Properties
                    withAnimation(.easeInOut(duration: 0.25)){
                        scrollDelegate.progress = 0
                        scrollDelegate.isEligible = false
                        scrollDelegate.isRefreshing = false
                        scrollDelegate.scrollOffset = 0
                    }
                }
            }
        }
    }
    
    // MARK: Get Safe Area Top
    private func getSafeAreaTop() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = windowScene.windows.first else {
            return 0
        }
        
        return window.safeAreaInsets.top
    }
    
}

struct CustomRefreshView_Previews: PreviewProvider {
    static var previews: some View {
        // MARK: For Testing Purpose
        CustomRefreshView(showsIndicator: false) {
            VStack{
                Rectangle()
                    .fill(.red)
                    .frame(height: 200)
                
                Rectangle()
                    .fill(.yellow)
                    .frame(height: 200)
            }
        } onRefresh: {
            
        }
    }
}

// MARK: For Simultanous Pan Gesture
class ScrollViewModel: NSObject,ObservableObject,UIGestureRecognizerDelegate{
    // MARK: Properties
    @Published var isEligible: Bool = false
    @Published var isRefreshing: Bool = false
    // MARK: Offsets and Progress
    @Published var scrollOffset: CGFloat = 0
    @Published var contentOffset: CGFloat = 0
    @Published var progress: CGFloat = 0
    let gestureID = UUID().uuidString
    
    // MARK: Since We need to Know when the user Left the Screen to Start Refresh
    // Adding Pan Gesture To UI Main Application Window
    // With Simultaneous Gesture Desture
    // Thus it Wont disturb SwiftUI Scroll's And Gesture's
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: Adding Gesture
    func addGesture(){
        // Only add gesture if not already added
        let existingGestures = rootController().view.gestureRecognizers?.compactMap { $0.name } ?? []
        guard !existingGestures.contains(gestureID) else { return }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onGestureChange(gesture:)))
        panGesture.delegate = self
        panGesture.name = gestureID
        
        rootController().view.addGestureRecognizer(panGesture)
    }
    
    // MARK: Removing When Leaving The View
    func removeGesture(){
        rootController().view.gestureRecognizers?.removeAll(where: { gesture in
            gesture.name == gestureID
        })
        
        // Reset state when gesture is removed
        DispatchQueue.main.async {
            self.isEligible = false
            self.isRefreshing = false
            self.scrollOffset = 0
            self.contentOffset = 0
            self.progress = 0
        }
    }
    
    // MARK: Finding Root Controller
    func rootController()->UIViewController{
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else{
            return .init()
        }
        
        guard let root = screen.windows.first?.rootViewController else{
            return .init()
        }
        
        return root
    }
    
    @objc
    func onGestureChange(gesture: UIPanGestureRecognizer){
        if gesture.state == .cancelled || gesture.state == .ended{
            print("User Released Touch")
            // MARK: Your Max Duration Goes Here
            if !isRefreshing{
                if scrollOffset > 150{
                    isEligible = true
                }else{
                    isEligible = false
                }
            }
        }
    }
}

// MARK: Offset Modifier
extension View{
    @ViewBuilder
    func offset(coordinateSpace: String,offset: @escaping (CGFloat)->())->some View{
        self
            .overlay {
                GeometryReader{proxy in
                    let minY = proxy.frame(in: .named(coordinateSpace)).minY
                    
                    Color.clear
                        .preference(key: OffsetKey.self, value: minY)
                        .onPreferenceChange(OffsetKey.self) { value in
                            offset(value)
                        }
                }
            }
    }
}

// MARK: Offset Preference Key
struct OffsetKey: PreferenceKey{
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}