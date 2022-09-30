import Foundation
import VisionSugar

extension CGRect {
    func precedes(_ rect: CGRect, allowsOverlapping: Bool) -> Bool {
        if allowsOverlapping {
            return minX < rect.minX
        } else {
            return maxX < rect.minX
        }
    }
    
    func succeeds(_ rect: CGRect, allowsOverlapping: Bool) -> Bool {
        if allowsOverlapping {
            return maxX > rect.maxX
        } else {
            return minX > rect.maxX
        }
    }
}

extension RecognizedText {
    func precedes(_ text: RecognizedText, allowsOverlapping: Bool) -> Bool {
        rect.precedes(text.rect, allowsOverlapping: allowsOverlapping)
    }
    
    func succeeds(_ text: RecognizedText, allowsOverlapping: Bool) -> Bool {
        rect.succeeds(text.rect, allowsOverlapping: allowsOverlapping)
    }
    
    func overlapsByMinimumThreshold(_ text: RecognizedText) -> Bool {
        let mininumHeightOverlapThreshold = 0.08
        return rect.rectWithXValues(of: text.rect).intersection(text.rect).height/text.rect.height >= mininumHeightOverlapThreshold
    }
}
extension Array where Element == RecognizedText {
    /** Returns an array of the inline `recognizedText`s to the one we specify, in the direction indicating by `preceding`—whilst ignoring those provided.
     
        The return array is 2-dimensional, where each element is another array of elements that appear in the same column as one another, in order of how much they intersect with the source `recognizedText`. These arrays are in the order of the how far away from the `recognizedText` they are.
     */
    func inlineTextColumns(as recognizedText: RecognizedText, preceding: Bool = false, allowOverlapping: Bool = false, ignoring textsToIgnore: [RecognizedText] = []) -> [[RecognizedText]] {
        
        var row: [[RecognizedText]] = []
        var discarded: [RecognizedText] = []
        let candidates = filter {
            $0.isInSameRowAs(recognizedText)
            && !textsToIgnore.contains($0)
            
            && (preceding ?
                $0.precedes(recognizedText, allowsOverlapping: allowOverlapping)
                : $0.succeeds(recognizedText, allowsOverlapping: allowOverlapping)
            )

            /// Filter out texts that overlap the recognized text by at least the minimum threshold
            && $0.overlapsByMinimumThreshold(recognizedText)
            /// Filter out empty `recognizedText`s
            && $0.candidates.filter { !$0.isEmpty }.count > 0
        }.sorted {
            $0.rect.minX < $1.rect.minX
        }
        

        /// Deal with multiple recognizedText we may have grabbed from the same column due to them both overlapping with `recognizedText` by choosing the one that intersects with it the most
        for candidate in candidates {

            guard !discarded.contains(candidate) else {
                continue
            }
            let column = candidates.filter {
                $0.isInSameColumnAs(candidate)
            }
            guard column.count > 1 else {
                row.append([candidate])
                continue
            }
            
            var columnElementsAndIntersections: [(recognizedText: RecognizedText,
                                                  intersection: CGRect)] = []
            for columnElement in column {
                /// first normalize the x values of both rects, `columnElement`, `closest` to `recognizedText` in new temporary variables, by assigning both the same x values (`origin.x` and `size.width`)
                let xNormalizedRect = columnElement.rect.rectWithXValues(of: recognizedText.rect)
                let intersection = xNormalizedRect.intersection(recognizedText.rect)
                columnElementsAndIntersections.append(
                    (columnElement, intersection)
                )
                discarded.append(columnElement)
            }
            
            /// Now order the `columnElementsAndIntersections` in decreasing order of `intersection.height` — which indicates how far away from the source `recognizedText` they are
            columnElementsAndIntersections.sort { $0.intersection.height > $1.intersection.height }
            
            /// Now that its sorted, map the recognized texts into an array and provide that in the result array
            row.append(columnElementsAndIntersections.map { $0.recognizedText })
        }
        
        return row
    }
}
