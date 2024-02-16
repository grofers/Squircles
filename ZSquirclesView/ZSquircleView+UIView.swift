import UIKit

public extension UIView {
    
    /// Call this function when you can not subclass your view from ZSquircleView e.g ZButton. The caller class should hold reference of the layers and preferably call this method from `layoutSubViews`
    func setupSquircleView(_ radius: CGFloat,
                           maskLayer: inout CAShapeLayer?,
                           borderLayer: CAShapeLayer,
                           borderConfig: ZSquircleView.BorderConfig?,
                           corners: UIRectCorner = .allCorners) {
        guard let path = UIBezierPath.squirclePath(for: self, withRadius: radius, andCorners: corners, borderWidth: borderConfig?.width ?? 0) else {
            return
        }
        
        maskLayer = (layer.mask as? CAShapeLayer) ?? CAShapeLayer()
        maskLayer?.path = path.cgPath
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.path = path.cgPath
        borderLayer.removeFromSuperlayer()
        if let borderConfig = borderConfig {
            borderLayer.lineWidth = 2 * borderConfig.width // Since line width is equally divided between in and out of layer
            borderLayer.strokeColor = borderConfig.color.cgColor
        }
        layer.addSublayer(borderLayer)
        layer.mask = maskLayer
        layer.masksToBounds = true
    }
    
    // this function returns control points in clockwise direction starting from top left side
    func squircleControlPoints(for rect: CGRect) -> [CGPoint] {
        let smoothening: CGFloat = 100
        let smootheningFactor = 100 - (97 + (3)/(100)*smoothening)
        
        let topLeft = CGPoint(x: rect.minX + smootheningFactor, y: rect.minY + smootheningFactor)
        let topRight = CGPoint(x: rect.maxX - smootheningFactor, y: rect.minY + smootheningFactor)
        let bottomLeft = CGPoint(x: rect.minX + smootheningFactor, y: rect.maxY - smootheningFactor)
        let bottomRight = CGPoint(x: rect.maxX -  smootheningFactor, y: rect.maxY - smootheningFactor)
        return [topRight, bottomRight, bottomLeft, topLeft]
    }
    
    // Points where different parts (curve, line, etc) of bezier path connect
    func bezierPathConnectionPoints(for rect: CGRect, cornerRadius: CGFloat, shouldUseHeightForCornerRadius: Bool = true, shouldApplyAnimatingPathGlitchFix: Bool = false) -> [CGPoint] {
        var finalCornerRadius = layer.cornerRadius
        
        if cornerRadius != 0.0 {
            finalCornerRadius = cornerRadius + 4.0
        }
        else {
            finalCornerRadius =  finalCornerRadius + 4.0
        }
        /*
         Corner radius can't exceed half of the shorter side; correct if necessary:
         */
        let minSide = min(rect.width, rect.height)
        let radius: CGFloat
        if shouldUseHeightForCornerRadius {
            radius = min(minSide/2, 2.5 * finalCornerRadius)
        } else {
            radius = 2.5 * finalCornerRadius
        }
        
        // The two points of the segment along the top side (clockwise):
        let p0 = CGPoint(x: rect.minX + radius, y: rect.minY)
        let p1 = CGPoint(x: rect.maxX - radius, y: rect.minY)
        
        // The two points of the segment along the right side (clockwise):
        let p2 = CGPoint(x: rect.maxX, y: rect.minY + radius)
        let p3 = CGPoint(x: rect.maxX, y: rect.maxY - radius)
        
        // The two points of the segment along the bottom side (clockwise):
        let p4 = CGPoint(x: rect.maxX - radius, y: rect.maxY)
        let p5 = CGPoint(x: rect.minX + radius, y: rect.maxY)
        
        let insetCorrection = shouldApplyAnimatingPathGlitchFix ? 0.01 : 0
        // The two points of the segment along the left side (clockwise):
        let p6 = CGPoint(x: rect.minX - insetCorrection, y: rect.maxY - radius)
        let p7 = CGPoint(x: rect.minX, y: rect.minY + radius)
        
        return [p0, p1, p2, p3, p4, p5, p6, p7]
    }
    
    func squircleBorderPath(withRadius cornerRadius: CGFloat,
                            andCorners corners: UIRectCorner,
                            borderWidth: CGFloat,
                            shouldUseHeightForCornerRadius: Bool = true) -> UIBezierPath? {
        
        getSquircleBorderPath(withBounds: bounds,
                              cornerRadius: cornerRadius,
                              andCorners: corners,
                              borderWidth: borderWidth,
                              shouldUseHeightForCornerRadius: shouldUseHeightForCornerRadius)
    }
    
    func getSquircleBorderPath(withBounds bounds: CGRect,
                               cornerRadius: CGFloat,
                               andCorners corners: UIRectCorner,
                               borderWidth: CGFloat,
                               shouldUseHeightForCornerRadius: Bool = true) -> UIBezierPath? {
        let borderInset: CGFloat = borderWidth / 2
        let rect: CGRect = bounds.insetBy(dx: borderInset, dy: borderInset)
        //For circle we don't can directly return oval path
        if bounds.width == bounds.height && bounds.height == 2 * cornerRadius {
            return UIBezierPath(ovalIn: rect)
        } else if cornerRadius > min(bounds.height, bounds.width)/2 {
            return UIBezierPath(roundedRect: rect, cornerRadius: min(bounds.height, bounds.width)/2)
        }
        
        let controlPoints = squircleControlPoints(for: rect)
        let bezierPathPoints = bezierPathConnectionPoints(for: rect,
                                                          cornerRadius: cornerRadius,
                                                          shouldUseHeightForCornerRadius: shouldUseHeightForCornerRadius)
        
        //Number of control points also wont grow more than 8 since our views are simple rectangle
        guard controlPoints.allSatisfy({ $0.isFinitePoint }) else { return nil }
        
        let path = UIBezierPath()
        path.move(to: bezierPathPoints[0])
        
        //Borders on all sides
        if corners.contains(.allCorners) {
            path.addLine(to: bezierPathPoints[1])
            path.addCurve(to: bezierPathPoints[2],
                          controlPoint1: controlPoints[0],
                          controlPoint2: controlPoints[0])
            path.addLine(to: bezierPathPoints[3])
            path.addCurve(to: bezierPathPoints[4],
                          controlPoint1: controlPoints[1],
                          controlPoint2: controlPoints[1])
            path.addLine(to: bezierPathPoints[5])
            path.addCurve(to: bezierPathPoints[6],
                          controlPoint1: controlPoints[2],
                          controlPoint2: controlPoints[2])
            path.addLine(to: bezierPathPoints[7])
            path.addCurve(to: bezierPathPoints[0],
                          controlPoint1: controlPoints[3],
                          controlPoint2: controlPoints[3])
        }
        //Borders on top, left and right
        else if corners.contains(.topCorners) {
            path.addLine(to: bezierPathPoints[1])
            path.addCurve(to: bezierPathPoints[2],
                          controlPoint1: controlPoints[0],
                          controlPoint2: controlPoints[0])
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + borderInset))
            path.move(to: .init(x: rect.minX, y: rect.maxY + borderInset))
            path.addLine(to: bezierPathPoints[7])
            path.addCurve(to: bezierPathPoints[0],
                          controlPoint1: controlPoints[3],
                          controlPoint2: controlPoints[3])
        }
        //Borders on bottom, left and right
        else if corners.contains(.bottomCorners) {
            path.move(to: .init(x: rect.maxX, y: rect.minY - borderInset))
            path.addLine(to: bezierPathPoints[3])
            path.addCurve(to: bezierPathPoints[4],
                          controlPoint1: controlPoints[1],
                          controlPoint2: controlPoints[1])
            path.addLine(to: bezierPathPoints[5])
            path.addCurve(to: bezierPathPoints[6],
                          controlPoint1: controlPoints[2],
                          controlPoint2: controlPoints[2])
            path.addLine(to: .init(x: rect.minX, y: rect.minY - borderInset))
        }
        //Borders on left and right
        else {
            path.move(to: .init(x: rect.maxX, y: rect.minY - borderInset))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY + borderInset))
            path.move(to: .init(x: rect.minX, y: rect.maxY + borderInset))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY - borderInset))
        }
        
        return path
    }
}

