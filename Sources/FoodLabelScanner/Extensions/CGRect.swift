import Foundation

let SubstantialOverlapRatioThreshold = 0.9

//TODO: Move this to SwiftSugar
extension CGRect {
    func rectWithXValues(of rect: CGRect) -> CGRect {
        CGRect(x: rect.origin.x, y: origin.y,
               width: rect.size.width, height: size.height)
    }
    
    func rectWithYValues(of rect: CGRect) -> CGRect {
        CGRect(x: origin.x, y: rect.origin.y,
               width: size.width, height: rect.size.height)
    }
}

extension CGRect {
    
    var isSubstantiallyLong: Bool {
        width/height < 0.5
    }
    
    func overlapsSubstantially(with rect: CGRect) -> Bool {
        guard let ratio = ratioOfIntersection(with: rect) else {
            return false
        }
        return ratio > SubstantialOverlapRatioThreshold
    }

    func ratioOfXIntersection(with rect: CGRect) -> Double? {
        let yNormalizedRect = self.rectWithYValues(of: rect)
        return rect.ratioOfIntersection(with: yNormalizedRect)
    }

    func ratioOfYIntersection(with rect: CGRect) -> Double? {
        let xNormalizedRect = self.rectWithXValues(of: rect)
        return rect.ratioOfIntersection(with: xNormalizedRect)
    }

    func ratioThatIsInline(with rect: CGRect) -> Double? {
        let xNormalizedRect = self.rectWithXValues(of: rect)
        
        let intersection = xNormalizedRect.intersection(rect)
        guard !intersection.isNull else {
            return nil
        }
        
        return intersection.area / area
    }

    func heightThatIsInline(with rect: CGRect) -> Double? {
        let xNormalizedRect = self.rectWithXValues(of: rect)
        let intersection = xNormalizedRect.intersection(rect)
        guard !intersection.isNull else { return nil }
        return intersection.height
    }

    func ratioOfIntersection(with rect: CGRect) -> Double? {
        let intersection = rect.intersection(self)
        guard !intersection.isNull else {
            return nil
        }
        
        /// Get the ratio of the intersection to whichever the smaller of the two rects are, and only add it if it covers at least 90%
        let smallerRect = CGRect.smaller(of: rect, and: self)
        return intersection.area / smallerRect.area
    }
    
    static func smaller(of rect1: CGRect, and rect2: CGRect) -> CGRect {
        if rect1.area < rect2.area {
            return rect1
        } else {
            return rect2
        }
    }
    var area: CGFloat {
        size.width * size.height
    }
}
