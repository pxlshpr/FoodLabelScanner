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
        
        /// ** Heuristic ** Pick the first 3, and order them by the minX value so that we're picking the closest one
        for column in row.indices {
            /// ** Heuristic ** Remove any texts that may contain "2,000"
            row[column] = row[column].filter { !$0.string.contains("2,000") }
            if row[column].count > 3 {
                row[column] = Array(row[column][0...2])
            }
            
            /// Sort by minX
            row[column] = row[column].sorted(by: { text1, text2 in
                text1.rect.minX < text2.rect.minX
            })
            /// Sort by distance to midY
            row[column] = row[column].sorted(by: { text1, text2 in
                let distance1 = abs(text1.rect.midY - recognizedText.rect.midY)
                let distance2 = abs(text2.rect.midY - recognizedText.rect.midY)
                return distance1 < distance2
            })

        }
        
        return row
    }
    
    func inlineTextRows(as recognizedText: RecognizedText, preceding: Bool = false, ignoring textsToIgnore: [RecognizedText] = []) -> [[RecognizedText]] {
        
        var column: [[RecognizedText]] = []
        var discarded: [RecognizedText] = []
        let candidates = filter {
            $0.isInSameColumnAs(recognizedText)
            && !textsToIgnore.contains($0)
            && (preceding ? $0.rect.maxY < recognizedText.rect.maxY : $0.rect.minY > recognizedText.rect.minY)
            
            /// Filter out empty `recognizedText`s
            && $0.candidates.filter { !$0.isEmpty }.count > 0
        }.sorted {
            preceding ?
                $0.rect.minY > $1.rect.minY
                : $0.rect.minY < $1.rect.minY
        }

        /// Deal with multiple recognizedTexts we may have grabbed from the same row due to them both overlapping with `recognizedText` by choosing the one that intersects with it the most
        for candidate in candidates {

            guard !discarded.contains(candidate) else {
                continue
            }
            let row = candidates.filter {
                $0.isInSameRowAs(candidate)
            }
            guard row.count > 1 else {
                column.append([candidate])
                continue
            }
            
            var rowElementsAndIntersections: [(recognizedText: RecognizedText,
                                               intersection: CGRect)] = []
            for rowElement in row {
                /// first normalize the y values of both rects, `rowElement`, `closest` to `recognizedText` in new temporary variables, by assigning both the same y values (`origin.y` and `size.height`)
                let yNormalizedRect = rowElement.rect.rectWithYValues(of: recognizedText.rect)
//                let closestYNormalizedRect = closest.rect.rectWithYValues(of: recognizedText.rect)
                let intersection = yNormalizedRect.intersection(recognizedText.rect)
                rowElementsAndIntersections.append(
                    (rowElement, intersection)
                )
                
//                let closestIntersection = closestYNormalizedRect.intersection(recognizedText.rect)
//
//                let intersectionRatio = intersection.width / rowElement.rect.width
//                let closestIntersectionRatio = closestIntersection.width / closest.rect.width
//
//                if intersectionRatio > closestIntersectionRatio {
//                    closest = rowElement
//                }
                
                discarded.append(rowElement)
            }
            
            /// Now order the `rowElementsAndIntersections` in decreasing order of `intersection.width` — which indicates how far away from the source `recognizedText` they are
            rowElementsAndIntersections.sort { $0.intersection.width > $1.intersection.width }
            
            /// Now that its sorted, map the recognized texts into an array and provide that in the result array
            column.append(rowElementsAndIntersections.map { $0.recognizedText })
        }
        
        return column
    }
}
