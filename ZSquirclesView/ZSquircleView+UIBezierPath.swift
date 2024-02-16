import UIKit

public extension UIBezierPath {
    
    private static var squirclePathCache = NSCache<NSString, UIBezierPath>()
    private static var squircleBorderPathCache = NSCache<NSString, UIBezierPath>()
    
    static func squirclePath(for view: UIView, withRadius radius: CGFloat, andCorners corners: UIRectCorner, borderWidth: CGFloat, shouldUseHeightForCornerRadius: Bool = true, shouldApplyAnimatingPathGlitchFix: Bool = false) -> UIBezierPath? {
        let pathKey = bezierPathKey(for: view, withRadius: radius, andCorners: corners, borderWidth: borderWidth) as NSString
        
        var path: UIBezierPath?
        
        if let fetchedPath = squirclePathCache.object(forKey: pathKey) {
            path = fetchedPath
        } else if let bezierPath = view.squirclePath(withRadius: radius, andCorners: corners, borderWidth: borderWidth, shouldUseHeightForCornerRadius: shouldUseHeightForCornerRadius, shouldApplyAnimatingPathGlitchFix: shouldApplyAnimatingPathGlitchFix) {
            path = bezierPath
            squirclePathCache.setObject(bezierPath, forKey: pathKey)
        }
        
        return path
    }
    
    static func squircleBorderPath(for view: UIView,
                                   withRadius radius: CGFloat,
                                   andCorners corners: UIRectCorner,
                                   borderWidth: CGFloat,
                                   shouldUseHeightForCornerRadius: Bool = true) -> UIBezierPath? {
        let pathKey = bezierPathKey(for: view,
                                    withRadius: radius,
                                    andCorners: corners,
                                    borderWidth: borderWidth) as NSString
        
        var path: UIBezierPath?
        
        if let fetchedPath = squircleBorderPathCache.object(forKey: pathKey) {
            path = fetchedPath
        } else if let bezierPath = view.squircleBorderPath(withRadius: radius,
                                                           andCorners: corners,
                                                           borderWidth: borderWidth,
                                                           shouldUseHeightForCornerRadius: shouldUseHeightForCornerRadius) {
            path = bezierPath
            squircleBorderPathCache.setObject(bezierPath, forKey: pathKey)
        }
        
        return path
    }
    
    //Simplest way to create a key for cache. Path depends on `bounds`, layer's cornerRadius, squircleRadius asked & corners to apply on.
    private static func bezierPathKey(for view: UIView, withRadius radius: CGFloat, andCorners corners: UIRectCorner, borderWidth: CGFloat) -> NSString {
        NSString(string: "\(view.bounds.minX)\(view.bounds.minY)\(view.bounds.height)\(view.bounds.width)\(view.layer.cornerRadius)\(radius)\(corners.bezierPathKey)\(borderWidth)")
    }
}

//Creating a key instead of using rawValue because `allCorners` raw value for some reason is quite big. We only need 4 character value to form topLeft(1), topRight(2), bottomLeft(4), bottomRight(8)
fileprivate extension UIRectCorner {

    var bezierPathKey: String {
        let topLeftValue = contains(.topLeft) ? "1" : "0"
        let topRightValue = contains(.topRight) ? "1" : "0"
        let bottomLeftValue = contains(.bottomLeft) ? "1" : "0"
        let bottomRightValue = contains(.bottomRight) ? "1" : "0"
        
        return topLeftValue + topRightValue + bottomLeftValue + bottomRightValue
    }
    
}

fileprivate extension UIView {
    
    //Reference - https://www.figma.com/blog/desperately-seeking-squircles/
    func squirclePath(withRadius cornerRadius: CGFloat, andCorners corners: UIRectCorner, borderWidth: CGFloat, shouldUseHeightForCornerRadius: Bool = true, shouldApplyAnimatingPathGlitchFix: Bool = false) -> UIBezierPath? {
        let rect: CGRect = bounds.insetBy(dx: borderWidth, dy: borderWidth)
        //For circle or capsule we don't want squircle, so we can directly return oval or capsule path
        if corners == .allCorners {
            if bounds.width == bounds.height && bounds.height == 2 * cornerRadius {
                return UIBezierPath(ovalIn: rect)
            } else if cornerRadius > min(bounds.height, bounds.width)/2 {
                return UIBezierPath(roundedRect: rect, cornerRadius: min(bounds.height, bounds.width) / 2)
            }
        }
        
        let controlPoints = squircleControlPoints(for: rect)
        let bezierPathPoints = bezierPathConnectionPoints(for: rect, cornerRadius: cornerRadius, shouldUseHeightForCornerRadius: shouldUseHeightForCornerRadius, shouldApplyAnimatingPathGlitchFix: shouldApplyAnimatingPathGlitchFix)

        //Number of control points also wont grow more than 8 since our views are simple rectangle
        guard controlPoints.allSatisfy({ $0.isFinitePoint }) else { return nil }
        
        let path = UIBezierPath()
        path.move(to: bezierPathPoints[0])
        path.addLine(to: bezierPathPoints[1])
        
        if corners.contains(.topRight) {
            path.addCurve(to: bezierPathPoints[2], controlPoint1: controlPoints[0], controlPoint2: controlPoints[0])
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: bezierPathPoints[2])
        }
        
        path.addLine(to: bezierPathPoints[3])
        
        if corners.contains(.bottomRight) {
            path.addCurve(to: bezierPathPoints[4], controlPoint1: controlPoints[1], controlPoint2: controlPoints[1])
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: bezierPathPoints[4])
        }
        
        path.addLine(to: bezierPathPoints[5])
        
        if corners.contains(.bottomLeft) {
            path.addCurve(to: bezierPathPoints[6], controlPoint1: controlPoints[2], controlPoint2: controlPoints[2])
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: bezierPathPoints[6])
        }
        
        path.addLine(to: bezierPathPoints[7])
        
        if corners.contains(.topLeft) {
            path.addCurve(to: bezierPathPoints[0], controlPoint1: controlPoints[3], controlPoint2: controlPoints[3])
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: bezierPathPoints[0])
        }
        
        return path
    }
}
