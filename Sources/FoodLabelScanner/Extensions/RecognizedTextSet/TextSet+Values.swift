import Foundation
import VisionSugar

extension RecognizedTextSet {

    func column(startingFrom startingText: RecognizedText, preceding: Bool) -> [RecognizedText] {
        texts.column(startingFrom: startingText, preceding: preceding)
    }

    func columnOfValueTexts(startingFrom startingText: RecognizedText, preceding: Bool) -> [ValuesText] {
        
        /// Only include texts that are a minimum of 5% overlapping (in the x-axis) with the starting text
        //TODO: Make this a parameter on the column(startingFrom:...) function instead of filtering the values it returns
        let columnOfTexts = column(startingFrom: startingText, preceding: preceding).filter {
            guard let intersectionRatio = startingText.rect.ratioOfXIntersection(with: $0.rect), intersectionRatio >= 0.05 else {
                return false
            }
            
//            let percentageIncreaseOfWidth = $0.rect.percentageOfIncreaseOfWidth(with: startingText.rect)
//            print("8️⃣ \(percentageIncreaseOfWidth.rounded()) % — \"\($0.string)\" and \"\(startingText.string)\"")
//            guard percentageIncreaseOfWidth < 1.5 else {
//                return false
//            }
            return true
        }
        
        var column: [ValuesText] = []
        var discarded: [RecognizedText] = []
        
        /// Now go through the texts
        for text in columnOfTexts {
            
            guard !discarded.contains(text) else {
                continue
            }
            
            /// Disqualify texts that are substantially long. This removes incorrectly read values (usually 0's) that span multiple lines and get read as a completely unrelated number.
            guard !text.rect.isSubstantiallyLong else {
                continue
            }
            
            /// Make sure we don't have a discarded text containing the same string that also overlaps it considerably
            guard !discarded.contains(where: {
                $0.string == text.string
                &&
                $0.rect.overlapsSubstantially(with: text.rect)
            }) else {
                continue
            }

            //TODO: Shouldn't we check all arrays here so that we grab the FastRecognized results that may not have been grabbed as a fallback?
            /// Get texts on same row arranged by their `minX` values
            let textsOnSameRow = columnOfTexts.textsOnSameRow(as: text)

            /// Pick the left most text on the row, making sure it hasn't been discarded
            guard let pickedText = textsOnSameRow.first, !discarded.contains(pickedText) else {
                continue
            }
            discarded.append(contentsOf: textsOnSameRow)

            /// Return nil if any non-skippable texts are encountered
            guard !text.string.isSkippableValueElement else {
                continue
            }
            
            guard !pickedText.string.containsHeaderAttribute else {
                continue
            }

            guard let valuesText = valuesText(for: pickedText, from: startingText) else {
                continue
            }
            
            /// **We're not doing this any longer since we're only storing the .accurate textSet result now**
            /// If this `valuesText` has more than one value that aren't energy, and
            ///     we're able to find texts within the other arrays for each one of them
            ///     then append them in place of this `valuesText` in the order that they appear vertically,
            ///         after adding them to the discarded list
//            if valuesText.values.filter({ !$0.hasEnergyUnit }).count > 1,
//               let overlappingSingleValuesTexts = overlappingSingleValuesTextsForValuesIn(valuesText)
//            {
//                for valuesText in overlappingSingleValuesTexts {
//                    if !discarded.contains(where: { $0.id == valuesText.text.id }) {
//                        discarded.append(valuesText.text)
//                    }
//                    column.append(valuesText)
//                }
//                continue
//            }
            
            /// If we picked an alternate overlapping valuesText, make sure that's added to discarded
            if !discarded.contains(where: { $0.id == valuesText.text.id }) {
                discarded.append(valuesText.text)
            }
            
            /// Stop if a second energy value is encountered after a non-energy value has been added—as this usually indicates the bottom of the table where strings containing the representative diet (stating something like `2000 kcal diet`) are found.
            if column.containsValueWithEnergyUnit, valuesText.containsValueWithEnergyUnit,
               let last = column.last, !last.containsValueWithEnergyUnit {
                break
            }

            column.append(valuesText)
        }
        
        return column
    }
    
    func valuesText(for pickedText: RecognizedText, from startingText: RecognizedText) -> ValuesText? {
        guard !pickedText.string.containsServingAttribute, !pickedText.containsHeaderAttribute else {
            return nil
        }
        
        /// First try and get a valid `ValuesText` here
        if let valuesText = ValuesText(pickedText), !valuesText.isSingularPercentValue {
            return valuesText
        }
        
        /// **We're not doing this any longer since we're only storing the .accurate textSet result now**
        /// If this failed, check the other arrays of the VisionResult by grabbing any texts in those that overlap with this one and happen to have a non-singular percent value within it.
//        for overlappingText in alternativeTexts(overlapping: pickedText, for: startingText) {
//            guard !overlappingText.string.containsServingAttribute, !overlappingText.containsHeaderAttribute else {
//                continue
//            }
//            if let valuesText = ValuesText(overlappingText), valuesText.isSingularNutritionUnitValue {
//                return valuesText
//            }
//        }
        return nil
    }
}

extension Array where Element == RecognizedText {
    func column(startingFrom startingText: RecognizedText, preceding: Bool) -> [RecognizedText] {
        filter {
            $0.isInSameColumnAs(startingText)
            && (preceding ? $0.rect.maxY < startingText.rect.maxY : $0.rect.minY > startingText.rect.minY)
        }.sorted {
//            preceding ? $0.rect.minY > $1.rect.minY : $0.rect.minY < $1.rect.minY
            preceding ? $0.rect.midY > $1.rect.midY : $0.rect.midY < $1.rect.midY
        }
    }
    
    func textsOnSameRow(as text: RecognizedText, preceding: Bool = true, includeSearchText: Bool = true, allowsOverlap: Bool = false) -> [RecognizedText] {
        filter {
            let overlapsVertically = $0.rect.minY < text.rect.maxY && $0.rect.maxY > text.rect.minY
            let horizontalCondition: Bool
            if allowsOverlap {
                horizontalCondition = preceding ? $0.rect.minX < text.rect.minX : text.rect.minX < $0.rect.minX
            } else {
                horizontalCondition = preceding ? $0.rect.maxX < text.rect.minX : text.rect.maxX < $0.rect.minX
            }
            let isOnSameLine = (overlapsVertically && horizontalCondition)
            if includeSearchText {
                return isOnSameLine || $0 == text
            } else {
                return isOnSameLine
            }
        }.sorted {
            $0.rect.minX < $1.rect.minX
        }
    }
}
