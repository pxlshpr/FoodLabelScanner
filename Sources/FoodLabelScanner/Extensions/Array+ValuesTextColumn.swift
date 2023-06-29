import Foundation
import VisionSugar

import FoodDataTypes

extension Array where Element == ValuesTextColumn {

    mutating func insertNilForMissingValues() {
        /// Get the column with the largest size as the `referenceColumn`
        /// Now get all the columns excluding the `referenceColumn`, calling it `partialColumns`
        /// For each `partialColumn`
        ///     Get the deltas of the `midY` between each column
        ///     Go through these, comparing them to the deltas of the `midY` of the reference column
        ///     As soon as we determine an anomaly (ie. a value with a statistically significant different),
        ///         Use that to determine the an index missing a value and add it to the array
        ///     After going through all the deltas and determining the empty columns
        ///         Fill them up with `nil` so that they can be determined later via scaling
    }
    
    var hasMismatchingColumnSizes: Bool {
        guard let firstColumnSize = first?.valuesTexts.count else {
            return false
        }
        for column in self.dropFirst() {
            if column.valuesTexts.count != firstColumnSize {
                return true
            }
        }
        return false
    }
    
    mutating func splitUpColumnsWithAllMultiColumnedValues() {
        for i in indices {
            let column = self[i]
            guard let splitColumns = column.splitUpColumnsUsingMultiColumnedValues else {
                continue
            }
            self[i] = splitColumns.0
            self.insert(splitColumns.1, at: i + 1)
        }
    }
    
    mutating func cleanupEnergyValues(using extractedAttributes: [[AttributeText]]) {
        /// If we've got any two sets of energy values (ie. two kcal and/or two kJ values), pick those that that are closer to the energy attribute
        let energyAttribute = extractedAttributes.energyAttributeText
        var extractedEnergyPairs = 0
        var lastMultipleEnergyTextId: UUID? = nil
        for i in indices {
            var column = self[i]
            column.pickEnergyValueIfMultiplesWithinText(energyPairIndexToExtract: &extractedEnergyPairs, lastMultipleEnergyTextId: &lastMultipleEnergyTextId)
            column.removeDuplicateEnergy(using: energyAttribute)
            column.pickEnergyIfMultiplePresent()
            self[i] = column
        }
    }

    mutating func removeExtraLongFooterValuesWithNoAttributes(for attributes: [[AttributeText]]) {
        for i in indices {
            var column = self[i]
            column.removeExtraLongFooterValuesWithNoAttributes(for: attributes)
            self[i] = column
        }
    }
    

    mutating func removeColumnsWithServingAttributes() {
        removeAll { $0.containsServingAttribute }
    }
    
    mutating func removeColumnsWithNoValuesPastFirstAttributesColumn(in attributes: [[AttributeText]]) {
        guard let attributesRect = attributes.columnRects.first else {
            return
        }

        removeAll {
            $0.valuesTexts.filter { valuesText in
                let valuesTextRect = valuesText.text.rect
                let attributesRect = attributesRect
                
                let thresholdPercentage = 0.05
                let distance = valuesTextRect.maxX - attributesRect.maxX
                return distance / attributesRect.width >= thresholdPercentage
            }.isEmpty
        }
    }
    
    mutating func removeColumnsWithSingleValuesNotInColumnWithAllOtherSingleValues() {
        removeAll {
//            $0.portionOfSingleValuesThatAreInColumnWithOtherSingleValues != 1.0
            
            if $0.valuesTexts.count == 2 {
                guard let ratio = $0.valuesTexts[0].text.rect
                    .ratioOfXIntersection(with: $0.valuesTexts[1].text.rect) else {
                    return false
                }
                return ratio > 0
            } else {
                
                if $0.valuesTexts.count == 3,
                   $0.singleValuesTexts.count == 1 {
                    return true
                }
                
                return $0.containsMoreThanOneSingleValue
                &&
                $0.portionOfSingleValuesThatAreInColumnWithOtherSingleValues != 1.0
            }
        }
        
    }
    
    var topMostEnergyValueTextUsingValueUnits: ValuesText? {
        var top: ValuesText? = nil
        for column in self {
            guard let index = column.indexOfFirstEnergyValue else { continue }
            guard let topValuesText = top else {
                top = column.valuesTexts[index]
                continue
            }
            if column.valuesTexts[index].text.rect.minY < topValuesText.text.rect.minY {
                top = column.valuesTexts[index]
            }
        }
        return top
    }
    
    func topMostEnergyValueTextUsingEnergyAttribute(from attributes: [[AttributeText]]) -> ValuesText? {
        guard let energyAttribute = attributes.attributeText(for: .energy) else {
            return nil
        }
        return topMostInlineValuesText(to: energyAttribute.text)
    }
    
    func topMostInlineValuesText(to text: RecognizedText) -> ValuesText? {
        var top: ValuesText? = nil
        for column in self {
            guard let topMostInlineValuesText = column.topMostInlineValuesText(to: text) else {
                continue
            }
            guard let topValuesText = top else {
                top = topMostInlineValuesText
                continue
            }
            if topMostInlineValuesText.text.rect.minY < topValuesText.text.rect.minY {
                top = topMostInlineValuesText
            }
        }
        return top
    }
    
    func topMostEnergyValueText(for attributes: [[AttributeText]]) -> ValuesText? {
        if let top = topMostEnergyValueTextUsingValueUnits {
            return top
        }
        /// If we still haven't got the top-most energy value, use the Energy attribute to find the-most value that is inline with it
        if let top = topMostEnergyValueTextUsingEnergyAttribute(from: attributes) {
            return top
        }
        return nil
    }
    
    mutating func removeOverlappingTextsWithSameString() {
        for i in indices {
            var column = self[i]
            column.removeOverlappingTextsWithSameString()
            self[i] = column
        }
    }
    
    mutating func removeFullyOverlappingTexts() {
        for i in indices {
            var column = self[i]
            column.removeFullyOverlappingTexts()
            self[i] = column
        }
    }
    
    mutating func removeReferenceColumns() {
        removeAll { $0.valuesTexts.containsReferenceEnergyValue }
    }

    mutating func removeTextsAboveEnergy(for attributes: [[AttributeText]]) {
        guard let energyText = topMostEnergyValueText(for: attributes)?.text else {
            return
        }
        
        // print("7️⃣ \(energyText.string)")
        removeTextsAbove(energyText)
    }
    
    mutating func removeTextsAboveHeader(from textSet: RecognizedTextSet) {
        for text in textSet.texts {
            if text.string.matchesRegex("(supplement|nutrition) facts") {
                removeTextsAbove(text)
                return
            }
        }
    }
    
    mutating func removeTextsAbove(_ text: RecognizedText) {
        for i in indices {
            var column = self[i]
            column.removeValueTextsAbove(text)
            self[i] = column
        }
    }
    
    mutating func removeSubsetColumns() {
        /// Remove all columns that are subset of other columns
        let selfCopy = self
        removeAll { $0.isSubsetOfColumn(in: selfCopy) }
    }
    
    mutating func removeFirstColumnIfItSpansPastSecondColumn() {
        guard count == 2 else { return }
        let threshold = 0.0
        if self[0].columnRect.maxX - self[1].columnRect.maxX > threshold {
            self.remove(at: 0)
        }
    }
    
    mutating func removeFooterText(for attributes: [[AttributeText]]) {
        /// if we have a common text amongst all columns, and its maxY is past the maxY of the last attribute, remove it from all columns
        guard let valuesText = commonLastValuesText,
              let bottomAttributeText = attributes.bottomAttributeText,
              valuesText.text.rect.maxY > bottomAttributeText.text.rect.maxY else {
            return
        }
        
        for i in self.indices {
            var column = self[i]
            column.valuesTexts.removeLast()
            self[i] = column
        }
    }
    
    var commonLastValuesText: ValuesText? {
        var commonLastValuesText: ValuesText? = nil
        for column in self {
            guard let lastValuesText = column.valuesTexts.last else {
                continue
            }
            guard let currentValuesText = commonLastValuesText else {
                commonLastValuesText = lastValuesText
                continue
            }
            guard currentValuesText == lastValuesText else {
                return nil
            }
        }
        return commonLastValuesText
    }
    
    mutating func removeInvalidColumns() {
        guard let highestNumberOfRows = sorted(by: {
            $0.valuesTexts.count > $1.valuesTexts.count
        }).first?.valuesTexts.count else {
            return
        }
        
        /// Remove columns with too few rows
        if highestNumberOfRows > 1 {
            self = filter {
//                $0.valuesTexts.count > Int(ceil(0.1 * Double(highestNumberOfRows)))
                $0.valuesTexts.count > Int(ceil(0.15 * Double(highestNumberOfRows)))
            }
        }
        
        /// Remove columns that contain all attribute texts
        self = filter { column in
            column.valuesTexts.count > column.valuesTexts.filter { Attribute.detect(in: $0.text.string).count > 0 }.count
        }
        
        /// Remove columns that contain mostly attribute texts
//        self = filter { column in
//            let attributeTextsCount = column.valuesTexts.filter { Attribute.detect(in: $0.text.string).count > 0 }.count
//            let percentageOfAttributeTexts = Double(attributeTextsCount)/Double(column.valuesTexts.count)
//            return percentageOfAttributeTexts < 0.65
//        }

    }

    mutating func removeColumnsWithProportionallyLessValues() {
        guard let highestNumberOfRows = sorted(by: {
            $0.valuesTexts.count > $1.valuesTexts.count
        }).first?.valuesTexts.count else {
            return
        }
        
        /// Remove columns with too few rows
        self = filter {
//            $0.valuesTexts.count > Int(ceil(0.1 * Double(highestNumberOfRows)))
            $0.valuesTexts.count > Int(ceil(0.15 * Double(highestNumberOfRows)))
        }
        
//        /// Remove columns that contain all attribute texts
//        self = filter { column in
//            column.valuesTexts.count > column.valuesTexts.filter { Attribute.detect(in: $0.text.string).count > 0 }.count
//        }
    }

    mutating func removeTextsBelowLastAttribute(of extractedAttributes: [[AttributeText]]) {
        guard let bottomAttributeText = extractedAttributes.bottomAttributeText else {
            return
        }

        for i in self.indices {
            var column = self[i]
            column.removeValueTextsBelow(bottomAttributeText)
            self[i] = column
        }
    }

    mutating func removeTextsAboveFirstAttribute(of extractedAttributes: [[AttributeText]]) {
        guard let topAttributeText = extractedAttributes.topAttributeText else {
            return
        }

        for i in self.indices {
            var column = self[i]
            column.removeValueTextsAbove(topAttributeText)
            self[i] = column
        }
    }

    mutating func removeDuplicateColumns() {
        self = self.uniqued()
    }
    
    mutating func removeTextsWithMultipleNutrientValues() {
        for i in self.indices {
            var column = self[i]
            column.removeTextsWithMultipleNutrientValues()
            self[i] = column
        }
    }
    
    mutating func removeTextsWithExtraLargeValues() {
        for i in self.indices {
            var column = self[i]
            column.removeTextsWithExtraLargeValues()
            self[i] = column
        }
    }
    
    mutating func removeTextsWithHeaderAttributes() {
        for i in self.indices {
            var column = self[i]
            column.removeTextsWithHeaderAttributes()
            self[i] = column
        }
    }
    
    mutating func removeColumnsWithMultipleNutrientValues() {
        removeAll { column in
            column.valuesTexts.contains { valuesText in
                valuesText.values.filter { $0.hasNutrientUnit }.count > 3
            }
        }
    }
    
    mutating func removeEmptyColumns() {
        removeAll { $0.valuesTexts.count == 0 }
    }
    
    mutating func pickTopColumns(using attributes: [[AttributeText]]) {
        let groups = groupedColumnsOfTexts(for: attributes)
        self = Self.pickTopColumns(from: groups)
    }

    /// - Group columns based on their positions
    mutating func groupedColumnsOfTexts(for attributes: [[AttributeText]]) -> [[ValuesTextColumn]] {
        var groups: [[ValuesTextColumn]] = []
        for column in self {

            var didAdd = false
            for i in groups.indices {
                if column.belongsTo(groups[i], using: attributes) {
                    groups[i].append(column)
                    didAdd = true
                    break
                }
            }

            if !didAdd {
                groups.append([column])
            }
        }
        return groups
    }
    
    /// - Pick the column with the most elements in each group
    static func pickTopColumns(from groupedColumns: [[ValuesTextColumn]]) -> [ValuesTextColumn] {
        var topColumns: [ValuesTextColumn] = []
        for group in groupedColumns {
            guard let top = group.sorted(by: { $0.valuesTexts.count > $1.valuesTexts.count }).first else { continue }
            topColumns.append(top)
        }
        return topColumns
    }
    
    /// - Order columns
    ///     Compare `midX`'s of shortest text from each column
    mutating func sort() {
        sort(by: {
            guard let midX0 = $0.midXOfShortestText, let midX1 = $1.midXOfShortestText else {
                return false
            }
            return midX0 < midX1
        })
    }
}

