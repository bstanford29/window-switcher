import CoreGraphics

/// Helper utilities for geometry comparisons
enum GeometryHelper {

    /// Standard tolerance for position/size matching (in points)
    /// Using 5 points as the standard - tight enough for accuracy, loose enough for rounding
    static let standardTolerance: CGFloat = 5

    /// Check if two positions match within tolerance
    static func positionsMatch(_ a: CGPoint, _ b: CGPoint, tolerance: CGFloat = standardTolerance) -> Bool {
        abs(a.x - b.x) < tolerance && abs(a.y - b.y) < tolerance
    }

    /// Check if two sizes match within tolerance
    static func sizesMatch(_ a: CGSize, _ b: CGSize, tolerance: CGFloat = standardTolerance) -> Bool {
        abs(a.width - b.width) < tolerance && abs(a.height - b.height) < tolerance
    }

    /// Check if two rectangles match within tolerance (both position and size)
    static func boundsMatch(_ a: CGRect, _ b: CGRect, tolerance: CGFloat = standardTolerance) -> Bool {
        positionsMatch(a.origin, b.origin, tolerance: tolerance) &&
        sizesMatch(a.size, b.size, tolerance: tolerance)
    }
}
