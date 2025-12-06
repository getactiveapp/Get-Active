import SwiftUI
import UIKit

// MARK: - Custom Refresh Control with Get Active Logo
struct CustomRefreshControlModifier: ViewModifier {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .background(RefreshControlReader(isRefreshing: $isRefreshing, onRefresh: onRefresh))
    }
}

extension View {
    func customRefreshable(isRefreshing: Binding<Bool>, onRefresh: @escaping () async -> Void) -> some View {
        modifier(CustomRefreshControlModifier(isRefreshing: isRefreshing, onRefresh: onRefresh))
    }
}

// MARK: - Get Active Logo Refresh View
struct GetActiveLogoRefreshView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Red circle
            Circle()
                .fill(Color.getActiveRed)
                .frame(width: 50, height: 50)
            
            // A/G monogram inside
            ZStack {
                // Letter A
                Text("A")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .offset(x: -3)
                
                // G curve extending from right side
                Path { path in
                    path.move(to: CGPoint(x: 20, y: 10))
                    path.addQuadCurve(to: CGPoint(x: 25, y: 15), control: CGPoint(x: 22, y: 12))
                    path.addLine(to: CGPoint(x: 25, y: 20))
                    path.addQuadCurve(to: CGPoint(x: 22, y: 25), control: CGPoint(x: 23, y: 22))
                }
                .stroke(Color.white, lineWidth: 3)
            }
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - UIKit Bridge for Custom Refresh Control
struct RefreshControlReader: UIViewRepresentable {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let scrollView = uiView.findScrollView() {
                setupRefreshControl(for: scrollView, context: context)
            }
        }
    }
    
    private func setupRefreshControl(for scrollView: UIScrollView, context: Context) {
        if scrollView.refreshControl == nil {
            let refreshControl = UIRefreshControl()
            
            // Create custom view with rotating logo
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            containerView.backgroundColor = .clear
            
            // Create the logo view
            let logoView = GetActiveLogoUIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            containerView.addSubview(logoView)
            
            refreshControl.tintColor = .clear
            refreshControl.backgroundColor = .clear
            refreshControl.addSubview(containerView)
            
            // Position the logo in the center of refresh control
            containerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                containerView.centerXAnchor.constraint(equalTo: refreshControl.centerXAnchor),
                containerView.centerYAnchor.constraint(equalTo: refreshControl.centerYAnchor),
                containerView.widthAnchor.constraint(equalToConstant: 50),
                containerView.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            // Handle refresh action
            refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.refresh(_:)), for: .valueChanged)
            
            scrollView.refreshControl = refreshControl
            context.coordinator.scrollView = scrollView
        }
        
        context.coordinator.onRefresh = onRefresh
        context.coordinator.isRefreshing = $isRefreshing
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var scrollView: UIScrollView?
        var onRefresh: (() async -> Void)?
        var isRefreshing: Binding<Bool>?
        
        @objc func refresh(_ sender: UIRefreshControl) {
            Task {
                isRefreshing?.wrappedValue = true
                await onRefresh?()
                await MainActor.run {
                    sender.endRefreshing()
                    isRefreshing?.wrappedValue = false
                }
            }
        }
    }
}

// MARK: - UIKit View for Get Active Logo with Rotation
class GetActiveLogoUIView: UIView {
    private var logoLayer: CALayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLogo()
        startRotation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLogo()
        startRotation()
    }
    
    private func setupLogo() {
        backgroundColor = .clear
        
        // Create red circle
        let circleLayer = CAShapeLayer()
        let circlePath = UIBezierPath(ovalIn: bounds)
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = UIColor.systemRed.cgColor
        layer.addSublayer(circleLayer)
        
        // Create A/G monogram text
        let textLayer = CATextLayer()
        textLayer.string = "AG"
        textLayer.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        textLayer.fontSize = 28
        textLayer.foregroundColor = UIColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.frame = bounds
        textLayer.contentsScale = UIScreen.main.scale
        layer.addSublayer(textLayer)
        
        logoLayer = layer
    }
    
    private func startRotation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1.0
        rotation.repeatCount = .infinity
        layer.add(rotation, forKey: "rotation")
    }
}

// MARK: - UIView Extension to Find ScrollView
extension UIView {
    func findScrollView() -> UIScrollView? {
        if let scrollView = self as? UIScrollView {
            return scrollView
        }
        var responder: UIResponder? = self
        while responder != nil {
            responder = responder?.next
            if let scrollView = responder as? UIScrollView {
                return scrollView
            }
        }
        for subview in subviews {
            if let scrollView = subview.findScrollView() {
                return scrollView
            }
        }
        return nil
    }
}

