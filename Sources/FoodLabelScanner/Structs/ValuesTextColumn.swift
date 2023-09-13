import VisionSugar
import SwiftUI

import PrepShared

//TODO: Create test cases for it starting with spicy chips
struct ValuesTextColumn {

    var valuesTexts: [ValuesText]

    init?(startingFrom text: RecognizedText, in textSet: RecognizedTextSet) {
        guard let valuesText = ValuesText(text), !valuesText.isSingularPercentValue else {
            return nil
        }

        let above = textSet.columnOfValueTexts(startingFrom: text, preceding: true).reversed()
        let below = textSet.columnOfValueTexts(startingFrom: text, preceding: false)
        self.valuesTexts = above + [valuesText] + below
    }
    
    init(valuesTexts: [ValuesText]) {
        self.valuesTexts = valuesTexts
    }
}

extension ValuesTextColumn {
    //TODO: Rename this
    var desc: String {
        return "[" + valuesTexts.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

extension ValuesTextColumn: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(valuesTexts)
    }
}

extension Array where Element == ValuesTextColumn {
    func containsNoValuesTexts(from column: ValuesTextColumn) -> Bool {
        !contains { c in
            c.valuesTexts.contains {
                column.valuesTexts.contains($0)
            }
        }
    }
    
    func containsNoSingleValuesTexts(from column: ValuesTextColumn) -> Bool {
        !contains { c in
            c.valuesTexts.contains {
                column.singleValuesTexts.contains($0)
            }
        }
    }

}

/// Helpers for `ExtractedValues.removeTextsAboveEnergy(_:)`
extension ValuesTextColumn {
    
    var rect: CGRect {
        valuesTexts.rect
    }
    
    var containsServingAttribute: Bool {
        valuesTexts.containsServingAttribute
    }
    var hasValuesAboveEnergyValue: Bool {
        /// Return false if we didn't detect an energy value
        guard let index = indexOfFirstEnergyValue else { return false }
        /// Return true if its not the first element
        return index != 0
    }
    
    var indexOfFirstEnergyValue: Int? {
        for i in valuesTexts.indices {
            if valuesTexts[i].containsValueWithEnergyUnit,
               !valuesTexts[i].containsNutrientUnit,
               !valuesTexts[i].containsEnergyDisqualifyingTexts
            {
                return i
            }
        }
        return nil
    }
    
    func topMostInlineValuesText(to text: RecognizedText) -> ValuesText? {
        for valuesText in valuesTexts {
            let xNormalizedRect = valuesText.text.rect.rectWithXValues(of: text.rect)
            if xNormalizedRect.intersects(text.rect) {
                return valuesText
            }
        }
        return nil
    }
    
    func indexOfLastValueTextInline(with attributeText: AttributeText) -> Int? {
        let thresholdY = attributeText.text.rect.height
        let aRect = attributeText.text.rect
        for i in valuesTexts.indices {
            let vRect = valuesTexts[i].text.rect
            
            guard !(vRect.minX < aRect.minX && vRect.minY > aRect.maxY) else {
                return i
            }
            if valuesTexts[i].text.rect.minY > attributeText.text.rect.maxY + thresholdY {
                return i
            }
        }
        return nil
    }

    func indexOfFirstValueTextInline(with attributeText: AttributeText) -> Int? {
        let thresholdY = attributeText.text.rect.height
        for i in valuesTexts.indices {
            if valuesTexts[i].text.rect.maxY + thresholdY > attributeText.text.rect.minY {
                return i
            }
        }
        return nil
    }

    mutating func removeValuesTextsAboveEnergy() {
        guard let index = indexOfFirstEnergyValue else { return }
        valuesTexts.removeFirst(index)
    }
    
    var hasMultipleKcalValues: Bool {
        valuesTexts.kcalValues.count > 1
    }
    
    var hasMultipleKjValues: Bool {
        valuesTexts.kjValues.count > 1
    }
    
    var hasBothKcalAndKjValues: Bool {
        !valuesTexts.kjValues.isEmpty && !valuesTexts.kcalValues.isEmpty
    }
        
    mutating func removeDuplicateEnergy(using energyAttribute: AttributeText?) {
        if hasMultipleKjValues {
            pickEnergyValue(from: valuesTexts.kjValues, for: energyAttribute)
        }
        if hasMultipleKcalValues {
            pickEnergyValue(from: valuesTexts.kcalValues, for: energyAttribute)
        }
    }
    
    mutating func pickEnergyIfMultiplePresent() {
        guard hasBothKcalAndKjValues else {
            return
        }
        
        //TODO: Have this a preference where we choose kcal over kj so that it is configurable when using the classifier
        valuesTexts.removeAll(where: { $0.containsValueWithKcalUnit })
    }
    
    mutating func removeExtraLongFooterValuesWithNoAttributes(for attributes: [[AttributeText]]) {
        guard let bottomAttributeText = attributes.bottomAttributeText else {
            return
        }
        valuesTexts.removeAll(where: {
            guard let attributeColumnBottom = attributes.columnRects.first?.maxY else {
                return false
            }
//            let textMaxY = $0.text.rect.maxY
//            let textMinY = $0.text.rect.minY
//            let attributesColumnRectsMaxY = attributes.columnRects[0].maxY
//            let bottomAttributeTextMaxY = bottomAttributeText.text.rect.maxY
            
            let isExtraLongWithNoAttributes = Attribute.detect(in: $0.text.string).isEmpty
            &&
            $0.text.rect.width / $0.text.rect.height > 6.4
            &&
            $0.text.rect.minY > attributeColumnBottom
            
            
            return isExtraLongWithNoAttributes
        })
    }
        
    mutating func pickEnergyValue(from multipleValues: [ValuesText], for energyAttribute: AttributeText?) {
        var array = multipleValues
        /// If we have an energy attribute, determine the closest value to it
        if let first = array.first {
//        if let closest = array.closestValueText(to: energyAttribute?.text) {
            /// Remove it from array of kj values
            array.removeAll(where: { $0 == first })

            /// Now remove the remaining kj values from the `valueText`s array
            valuesTexts.removeAll(where: { array.contains($0) })
        }
    }
    
    mutating func removeValueTextsBelow(_ attributeText: AttributeText) {
        guard let index = indexOfLastValueTextInline(with: attributeText) else { return }
        valuesTexts.removeLast(valuesTexts.count - index)
    }
    
    mutating func removeValueTextsAbove(_ attributeText: AttributeText) {
        guard let index = indexOfFirstValueTextInline(with: attributeText) else { return }
        valuesTexts.removeFirst(index)
    }
    
    mutating func removeTextsWithMultipleNutrientValues() {
        valuesTexts.removeAll { valuesText in
            valuesText.values.filter { $0.hasNutrientUnit }.count > 2
        }
    }

    mutating func removeTextsWithExtraLargeValues() {
        valuesTexts.removeAll { valuesText in
            valuesText.values.contains(where: { $0.amount > 15_000 })
        }
    }
    
    mutating func removeTextsWithHeaderAttributes() {
        valuesTexts.removeAll { valuesText in
            valuesText.text.string.contains("100 g")
        }
    }

    mutating func removeValueTextsAbove(_ text: RecognizedText) {
        valuesTexts.removeAll(where: {
            let thresholdY = 0.02 * text.rect.height
            return $0.text.rect.minY + thresholdY < text.rect.minY
        })
    }
    
    mutating func removeFullyOverlappingTexts() {
        guard valuesTexts.count > 1 else { return }
        
        for i in 1..<valuesTexts.count {
            guard i < valuesTexts.count else {
                continue
            }

            let valuesText = valuesTexts[i]

            let fullyOverlappingAndTaller = valuesTexts.filter {
                guard $0 != valuesText else { return false }
                return $0.text.rect.minY < valuesText.text.rect.minY
                && $0.text.rect.maxY > valuesText.text.rect.maxY
                && $0.text.rect.percentageOfIncreaseOfWidth(with: valuesText.text.rect) < 0.5
            }
            
            if !fullyOverlappingAndTaller.isEmpty {
                valuesTexts.remove(at: i)
            }
        }
    }
    
    mutating func removeOverlappingTextsWithSameString() {
        guard valuesTexts.count > 1 else { return }
        
        for i in 1..<valuesTexts.count {
            guard i < valuesTexts.count else {
                continue
            }
            
            let valuesText = valuesTexts[i]
            let previousValuesTexts = valuesTexts[0..<i]
            
            /// if any of the previous valuesTexts contains
            if previousValuesTexts.contains(where: {
                $0.text.rect == valuesText.text.rect
                &&
                $0.text.string == valuesText.text.string
            }) {
                valuesTexts.remove(at: i)
            }
        }
    }
}

extension CGRect {
    func percentageOfIncreaseOfWidth(with rect: CGRect) -> Double {
        let smallerValue = rect.width < width ? rect.width : width
        return abs(rect.width - width)/smallerValue
    }
}

extension ValuesTextColumn {

    //TODO: Improve this
    /**
     Returns a `CGRect` which represents a union of all the single-value `ValueText`'s of the column.

     Any outliers that may span multple columns are ignored when calculating this union.
     
     Improve this by ignoring inline values that may be wider than the other single-value ValueText's. Do this by either ignoring those that also have an Attribute that can be extracted from the text or—better yet—write a function on ValueText that returns a boolean of whether the text contains any extraneous strings to the actual value strings and use this.
     */
    var columnRect: CGRect {
        columnRect(of: singleValuesTexts)
    }

    func columnRectOfSingleValuesNotWithinOrVerticallyOutsideOf(_ attributes: [[AttributeText]]) -> CGRect {
        columnRect(of: singleValuesNotWithinOrVerticallyOutsideOf(attributes))
    }
    
    func singleValuesNotWithinOrVerticallyOutsideOf(_ attributes: [[AttributeText]]) -> [ValuesText] {
        singleValuesTexts.filter {
            /// Do not include value texts that are substantailly contained by any of the attribute columns
//            guard !attributes.contains(rect: $0.text.rect) else {
//                return false
//            }
            
            /// Do not include value texts that are vertically outside of any of the attribute columns
            guard attributes.overlapsVertically(with: $0.text.rect) else {
                return false
            }
            
            return true
        }
    }

    func columnRect(of valuesTexts: [ValuesText]) -> CGRect {
        var unionRect: CGRect? = nil
        for valuesText in valuesTexts {
            
            /// Skip values that don't have exactly one value
            guard valuesText.values.count == 1 else {
                continue
            }
            
            guard let rect = unionRect else {
                /// Set the first `ValuesText.rect` to be the `unionRect`
                unionRect = valuesText.text.rect
                continue
            }
            
            /// Keep joining `unionRect` with any subsequent `ValuesText.rect`'s
            unionRect = rect.union(valuesText.text.rect)
        }
        
        /// Now return the union
        return unionRect ?? .zero
    }
    
    var containsAllMultiColumnedValues: Bool {
        valuesTexts.allSatisfy { valuesText in
            valuesText.values.filter {
                $0.unit != .p
            }.count == 2
        }
    }
    
    var splitUpColumnsUsingMultiColumnedValues: (ValuesTextColumn, ValuesTextColumn)? {
        var valuesTexts1: [ValuesText] = []
        var valuesTexts2: [ValuesText] = []
        
        for valuesText in valuesTexts {
            let valuesWithoutPercentages = valuesText.values.filter({ $0.unit != .p })
            guard valuesWithoutPercentages.count == 2 else { return nil }
            valuesTexts1.append(ValuesText(values: [valuesWithoutPercentages[0]],
                                           text: valuesText.text))
            valuesTexts2.append(ValuesText(values: [valuesWithoutPercentages[1]],
                                           text: valuesText.text))
        }
        
        return (ValuesTextColumn(valuesTexts: valuesTexts1),
                ValuesTextColumn(valuesTexts: valuesTexts2))
    }
    
    func belongsTo(_ group: [ValuesTextColumn], using attributes: [[AttributeText]]) -> Bool {
        
        guard let topGroupColumn = group.sorted(by: { $0.valuesTexts.count > $1.valuesTexts.count }).first else {
            return false
        }

        let groupRect = topGroupColumn.columnRectOfSingleValuesNotWithinOrVerticallyOutsideOf(attributes)
        let yNormalizedRect = columnRectOfSingleValuesNotWithinOrVerticallyOutsideOf(attributes).rectWithYValues(of: groupRect)
        
        guard let intersectionRatio = groupRect.ratioOfIntersection(with: yNormalizedRect) else {
            return false
        }

        /// We chose `0.43` because `0.423` was needed to identify a column as not belonging to in case `21AB8151-540A-41A9-BAB2-8674FD3A46E7` (check for one that starts with a value with amount 297) and `0.45` was needed to identify a column as belonging to the group in case `31D0CA8B-5069-4AB3-B865-47CD1D15D879` (check for one that starts with a value with amount 5).
        let intersectionRatioIsSubstantial = intersectionRatio >= 0.43
        let intersects = groupRect.intersects(yNormalizedRect)
        
        /// We added this check because `31D0CA8B-5069-4AB3-B865-47CD1D15D879` fails the `intersectionRatio` check. This makes sure that none of the `ValuesText`'s in this column exists in any of the group before continuing.
        if group.containsNoSingleValuesTexts(from: self) {
            /// We added this after case `21AB8151-540A-41A9-BAB2-8674FD3A46E7` where both columns overlapped by each other slightly (the intersection ratio—the width of the intersection as a proportion of the width of the smaller column's width was `2.9%`

            
//            if intersectionRatioIsSubstantial {
//                print("""
//\(self.desc)
//--- belongs to
//\(group.desc)
//--- because
//groupRect: \(groupRect)
//--- has a substantial intersection ratio: \(intersectionRatio)
//yNormalizedRect: \(yNormalizedRect)
//=============================================
//
//""")
//            } else {
//                    print("""
//\(self.desc)
//--- doesn't belong to
//\(group.desc)
//--- because
//groupRect: \(groupRect)
//--- doesn't have a substantial intersection ratio: \(intersectionRatio)
//yNormalizedRect: \(yNormalizedRect)
//=============================================
//
//""")
//            }

            return intersectionRatioIsSubstantial
            
        } else {
            
//            if intersects {
//                print("""
//\(self.desc)
//--- belongs to
//\(group.desc)
//--- because
//groupRect: \(groupRect)
//--- intersects
//yNormalizedRect: \(yNormalizedRect)
//=============================================
//
//""")
//            } else {
//                    print("""
//\(self.desc)
//--- doesn't belong to
//\(group.desc)
//--- because
//groupRect: \(groupRect)
//--- doesn't intersect
//yNormalizedRect: \(yNormalizedRect)
//=============================================
//
//""")
//            }
            
            return intersects
        }
    }
    
    var shortestText: RecognizedText? {
        valuesTexts.compactMap { $0.text }.shortestText
    }
    
    var midXOfShortestText: CGFloat? {
        shortestText?.rect.midX
    }
}

extension Array where Element == ValuesTextColumn {
    var shortestText: RecognizedText? {
        let shortestTexts = compactMap { $0.shortestText }
        return shortestTexts.sorted(by: { $0.rect.width < $1.rect.width }).first
    }
    
    mutating func removeFirstSetOfValues() {
        for i in indices {
            var column = self[i]
            column.valuesTexts.remove(at: 0)
            self[i] = column
        }
    }
    
    var firstSetOfValuesTextsContainingEnergy: [ValuesText]? {
        var valuesTexts: [ValuesText?] = []
        for column in self {
            guard let firstValuesText = column.valuesTexts.first else {
                valuesTexts.append(nil)
                continue
            }
            if firstValuesText.containsValueWithEnergyUnit {
                valuesTexts.append(firstValuesText)
            }
        }
        
        let nonNilValuesTexts = valuesTexts.compactMap { $0 }
        guard nonNilValuesTexts.count > 0 else {
            return nil
        }
        return valuesTexts.count == nonNilValuesTexts.count ? nonNilValuesTexts : nil
    }
}

extension ValuesText: CustomDebugStringConvertible {
    var debugDescription: String {
        return "[" + values.map { $0.description }.joined(separator: ", ") + "]"
    }
    var description: String {
        return "[" + values.map { $0.description }.joined(separator: ", ") + "]"
    }
}

extension Array where Element == ValuesTextColumn {
    var desc: [String] {
        return map { $0.desc }
    }
}

//MARK: - Experimental

extension ValuesTextColumn {
    func numberOfValuesInlineWith(attributes: [[AttributeText]]) -> Int {
        valuesTexts.filter {
            $0.isInlineWithAnyAttribute(in: attributes)
        }.count
    }
    
    var numberOfSingleValuesThatAreInColumnWithOtherSingleValues: Int {
        singleValuesTexts.filter {
            $0.isInColumnWithAllValuesTexts(in: singleValuesTexts, except: $0)
        }.count
    }
    
    var singleValuesTexts: [ValuesText] {
        valuesTexts.filter { $0.values.count == 1 }
    }
    
    func portionOfValuesInlineWith(attributes: [[AttributeText]]) -> Double {
        Double(numberOfValuesInlineWith(attributes: attributes)) / Double(valuesTexts.count)
    }
    
    var portionOfSingleValuesThatAreInColumnWithOtherSingleValues: Double {
        Double(numberOfSingleValuesThatAreInColumnWithOtherSingleValues) / Double(singleValuesTexts.count)
    }
    
    var containsMoreThanOneSingleValue: Bool {
        singleValuesTexts.count > 1
    }
}

extension ValuesText {

    func isInColumnWithAllValuesTexts(in valuesTexts: [ValuesText], except: ValuesText) -> Bool {
        for valuesText in valuesTexts {
            guard valuesText != except else { continue }
            if self.text.isInColumn(with: valuesText.text) {
                return true
            }
        }
        return false
    }

    func isInlineWithAnyAttribute(in attributes: [[AttributeText]]) -> Bool {
        for attributeText in attributes.reduce([], +) {
            if self.text.isInline(with: attributeText.text) {
                return true
            }
        }
        return false
    }
}

extension RecognizedText {
    func isInColumn(with text: RecognizedText) -> Bool {
        rect.rectWithYValues(of: text.rect).intersects(text.rect)
    }
    func isInline(with text: RecognizedText) -> Bool {
        rect.rectWithXValues(of: text.rect).intersects(text.rect)
    }
}

extension ValuesTextColumn {
    /// Returns true if this column is a subset of a column (ie. containing all the elements in the same order, but with a fewer count) than any of the columns in the provided array
    func isSubsetOfColumn(in array: [ValuesTextColumn]) -> Bool {
        array.contains { isSubset(of: $0) }
    }

    func isSubset_legacy(of column: ValuesTextColumn) -> Bool {
        guard valuesTexts.count < column.valuesTexts.count else {
            return false
        }
        
        let set = Set(valuesTexts)
        let columnSet = Set(column.valuesTexts)
        return set.isSubset(of: columnSet)
//        let allElemtsEqual = findListSet.isSubsetOfSet(otherSet: listSet)
    }
    
    func isSubset(of column: ValuesTextColumn) -> Bool {
        /// If the `valuesTexts` array is not less than the column's one, or we have no elements in this array, or we're unable to find the first element in the column's array, return false immediately.
        guard valuesTexts.count < column.valuesTexts.count,
              let first = valuesTexts.first,
              let startIndex = column.valuesTexts.firstIndex(of: first)
        else {
            return false
        }
        
        /// If the `valuesTexts` array has only 1 element and we've already found it, return `true`
        guard valuesTexts.count > 1 else { return true }
        
        /// For all the remaining `valuesTexts`
        for i in 1..<valuesTexts.count {
            let columnIndex = startIndex + i
            
            /// If the column's array doesn't have an element at the respective index (`i` elements after the `startIndex`), or that element doesn't match the element at `i` of this array, return false immediately.
            guard columnIndex < column.valuesTexts.count,
                  valuesTexts[i] == column.valuesTexts[columnIndex] else {
                return false
            }
        }
        
        /// If the remaining `valueTexts` passed, return true
        return true
    }
}

extension Array where Element == [ValuesTextColumn] {
    var desc: [[String]] {
        map { $0.desc }
    }
    
    mutating func removeExtraneousColumns() {
        for i in indices {
            let group = self[i]
            guard group.count > 2 else { continue }
            self[i] = group.enumerated().compactMap{ $0.offset < 2 ? $0.element : nil }
        }
    }
    
    mutating func removeColumnsInSameColumnAsAttributes(in extractedAttributes: [[AttributeText]]) {
        /// If there's only column, don't consider this heuristic
        guard totalColumnsCount != 1 else {
            return
        }
        for i in indices {
            guard i < extractedAttributes.count else { continue }
            let attributesRect = extractedAttributes[i].rect
            self[i] = self[i].filter { $0.rect.maxX > attributesRect.maxX }
        }
    }
    
    var totalColumnsCount: Int {
        reduce(0) { $0 + $1.count }
    }
}
