import SwiftUI

extension Image {
    func asUIImage() -> UIImage? {
        let controller = UIHostingController(rootView: 
            self
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        )
        
        let view = controller.view
        let contentSize = view?.intrinsicContentSize ?? .zero
        view?.bounds = CGRect(origin: .zero, size: contentSize)
        view?.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: contentSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: view?.bounds ?? .zero, afterScreenUpdates: true)
        }
    }
} 
