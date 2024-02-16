import Foundation 

extension CGPoint {
    var isFinitePoint: Bool {
        x.isFinite && y.isFinite
    }
}
