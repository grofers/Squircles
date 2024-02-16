import UIKit

open class ZSquircleView: UIView {
    
    private let maskLayerDelegate = MaskLayerDelegate()
    
    public struct ShadowConfig {
        let color: UIColor
        let offset: CGSize
        let radius: CGFloat
        let opacity: Float
        
        public init(color: UIColor, offset: CGSize, radius: CGFloat, opacity: Float) {
            self.color = color
            self.offset = offset
            self.radius = radius
            self.opacity = opacity
        }
    }
    
    @objc public class BorderConfig: NSObject {
        public let width: CGFloat
        public let color: UIColor
        
       @objc public init(width: CGFloat, color: UIColor) {
            self.width = width
            self.color = color
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError()
    }
    
    public override class var layerClass: AnyClass { return CAShapeLayer.self }
    
    private var _backgroundColor: UIColor? = .clear
    
    public override var backgroundColor: UIColor? {
        set {
            squircleContentView.backgroundColor = newValue
            _backgroundColor = newValue
        }

        get {
            _backgroundColor
        }
    }
    
    private var maskLayer: CAShapeLayer? = nil
    
    @objc public var squircleCornerRadius: CGFloat = 0
    
    ///Squircle path, while animating, might glitch out at the left corner - example case -> Res card with gold border. Default value is false, enable if you see a glitchy border at the corners.
    public var shouldApplyAnimatingPathGlitchFix: Bool = false
    
    /*
     For the views in which layout doesn't change on reuse, layoutSubviews is not called on the reused view.
     Hence, resetting the squircle properties in such cases resulted in no shadow/border on the reused view.
     As in most of the cases we are not supposed to change the shadow or border properties in the reused view - setting `shouldResetSquirclePropetiesOnReuse` to false by default.
     */
    public var shouldResetSquirclePropertiesOnReuse: Bool = false
    
    public lazy var squircleCorners: UIRectCorner = .allCorners
    
    public var shouldUseHeightForCornerRadius: Bool = true
    
    public var shadowConfig: ShadowConfig? {
        didSet {
            updateShadow()
        }
    }
    
   @objc public var borderConfig: BorderConfig? {
        didSet {
            updateBorder()
        }
    }
    
    open override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        switch event {
        case "path":
            return getActionForPathAnimation(forLayer: layer) ?? super.action(for: layer, forKey: event)
        case "shadowPath":
            return getActionForShadowPathAnimation(forLayer: layer) ?? super.action(for: layer, forKey: event)
        default:
            return super.action(for: layer, forKey: event)
        }
    }
    
    private func getActionForShadowPathAnimation(forLayer layer: CALayer) -> CAAction? {
        guard let priorPath = layer.shadowPath else {
            return nil
        }
        
        guard let sizeAnimation = layer.animation(forKey: "bounds.size") as? CABasicAnimation,
              let animation = sizeAnimation.copy() as? CABasicAnimation else {
                  return nil
              }
        animation.keyPath = "shadowPath"
        let action = MaskingViewAction()
        action.priorPath = priorPath
        action.pendingAnimation = animation
        return action
    }
    
    private func getActionForPathAnimation(forLayer layer: CALayer) -> CAAction? {
        guard let priorPath = (layer as? CAShapeLayer)?.path else {
            return nil
        }
        
        guard let sizeAnimation = maskLayer?.superlayer?.animation(forKey: "bounds.size") as? CABasicAnimation,
              let animation = sizeAnimation.copy() as? CABasicAnimation else {
            return nil
        }
        animation.keyPath = "path"
        let action = MaskingViewAction()
        action.priorPath = priorPath
        action.pendingAnimation = animation
        return action
    }
    
    @available(*, deprecated, renamed: "shapeLayer", message: "ZSquircleView uses CAShapeLayer as backing layer. Please use 'shapeLayer' property instead.")
    public override var layer: CALayer { super.layer }
    
    public var shapeLayer: CAShapeLayer { layer as! CAShapeLayer }
    
    @objc public let squircleContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    public init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        addSubview(squircleContentView)
        NSLayoutConstraint.activate([
            squircleContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            squircleContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            squircleContentView.topAnchor.constraint(equalTo: topAnchor),
            squircleContentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        squircleContentView.clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    @objc open func prepareForReuse() {
        guard shouldResetSquirclePropertiesOnReuse else { return }
        prepareForReuseInternal()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if squircleCornerRadius == 0 {
            prepareForReuseInternal() //Calling internal method as we don't want prepareForReuse of child classes to be called here as they might be doing something specific to their implementation
            return
        }
        guard let path = UIBezierPath.squirclePath(for: self, withRadius: squircleCornerRadius, andCorners: squircleCorners, borderWidth: borderConfig?.width ?? 0,shouldUseHeightForCornerRadius: shouldUseHeightForCornerRadius, shouldApplyAnimatingPathGlitchFix: shouldApplyAnimatingPathGlitchFix) else { return }
        
        if maskLayer == nil {
            maskLayer = CAShapeLayer()
            maskLayer?.delegate = maskLayerDelegate
        }
        maskLayer?.path = path.cgPath
        squircleContentView.layer.mask = maskLayer
        
        shapeLayer.path = path.cgPath
        updateBorder()
        
        shapeLayer.shadowPath = path.cgPath
        updateShadow()
    }
    
}

private extension ZSquircleView {
    
    func updateShapeLayerPathIfNeeded() {
        guard shapeLayer.path == nil else { return }
        
        guard let path = maskLayer?.path ?? UIBezierPath.squirclePath(for: self, withRadius: squircleCornerRadius, andCorners: squircleCorners, borderWidth: borderConfig?.width ?? 0, shouldUseHeightForCornerRadius: shouldUseHeightForCornerRadius)?.cgPath else { return }
        
        shapeLayer.path = path
        shapeLayer.shadowPath = path
    }
    
    func updateBorder() {
        guard let border = borderConfig else {
            resetBorder()
            return
        }
        updateShapeLayerPathIfNeeded()
        shapeLayer.lineWidth = 2 * border.width // Since line width is equally divided between in and out of layer
        shapeLayer.strokeColor = border.color.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
    }
    
    func updateShadow() {
        guard let shadow = shadowConfig else {
            resetShadow()
            return
        }
        shapeLayer.shadowColor = shadow.color.cgColor
        shapeLayer.shadowRadius = shadow.radius
        shapeLayer.shadowOffset = shadow.offset
        shapeLayer.shadowOpacity = shadow.opacity
    }
    
    func prepareForReuseInternal() {
        resetMask()
        resetShadow()
        resetBorder()
    }
    
    func resetMask() {
        guard maskLayer != nil else {
            return
        }
        squircleContentView.layer.mask = nil
        maskLayer = nil
    }
    
    func resetShadow() {
        shapeLayer.shadowPath = nil
        shapeLayer.shadowOpacity = 0
    }
    
    func resetBorder() {
        shapeLayer.path = nil
        shapeLayer.lineWidth = 0
    }
}

fileprivate extension ZSquircleView {
    
    final class MaskLayerDelegate: NSObject, CALayerDelegate {
        
        func action(for layer: CALayer, forKey event: String) -> CAAction? {
            guard event == "path" else {
                return nil
            }

            guard let priorPath = (layer as? CAShapeLayer)?.path else {
                return nil
            }

            guard let sizeAnimation = layer.superlayer?.animation(forKey: "bounds.size") as? CABasicAnimation,
                  let animation = sizeAnimation.copy() as? CABasicAnimation else {
                return nil
            }
            animation.keyPath = "path"
            let action = MaskingViewAction()
            action.priorPath = priorPath
            action.pendingAnimation = animation
            return action
        }
    }
    
    private class MaskingViewAction: NSObject, CAAction {
        
        var pendingAnimation: CABasicAnimation? = nil
        var priorPath: CGPath? = nil
        
        // CAAction Protocol
        func run(forKey event: String, object anObject: Any, arguments dict: [AnyHashable : Any]?) {
            guard let layer = anObject as? CAShapeLayer, let animation = self.pendingAnimation else {
                return
            }
            animation.fromValue = self.priorPath
            
            switch event {
            case "path":
                animation.toValue = layer.path
            case "shadowPath":
                animation.toValue = layer.shadowPath
            default: break
            }
            layer.add(animation, forKey: animation.keyPath ?? "path")
        }
    }
}

