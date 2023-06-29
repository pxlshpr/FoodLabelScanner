import SwiftUI
import VisionSugar
import FoodDataTypes

//TODO: Remove any used ones
//MARK: [[AttributeText]]

extension Array where Element == [AttributeText] {
    var smallestCount: Int {
        sorted(by: { $0.count < $1.count })
            .first?.count ?? 0
    }
    
    var maximumNumberOfValueColumns: Int {
        count * 2
    }
}

//MARK: [[[Value?]]]

extension Array where Element == [[FoodLabelValue?]] {
    var valuesGroupDescription: String {
        var description = "{"
        for group in self {
            description += "("
            for column in group {
                description += "["
                for value in column {
                    if let value = value {
                        description += "\(value.description), "
                    } else {
                        description += "nil, "
                    }
                }
                description = description.replacingLastOccurrence(of: ", ", with: "")
                description += "]"
            }
            description += ")"
        }
        description += "}"
        return description
    }
}

//MARK: [ValueText]
extension Array where Element == ValueText {
    var minX: CGFloat? {
        map { $0.text.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.text.rect.maxX }.sorted(by: { $0 > $1 }).first
    }
    var shortestText: RecognizedText? {
        map { $0.text }.shortestText
    }

    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.value.hasEnergyUnit })
    }
    
    var containsTwoEnergyValues: Bool {
        contains(where: { $0.value.unit == .kj })
        &&
        contains(where: { $0.value.unit == .kcal })
    }
    
    var averageMidX: CGFloat {
        guard count > 0 else { return 0 }
        let sum = self.reduce(0, { $0 + $1.text.rect.midX })
        return sum / Double(count)
    }
}

//MARK: [[ValueText]]

extension Array where Element == [ValueText] {
    /// Use `midX` of shortest text, checking if it lies within the shortest text of any column in each group
    func belongsTo(_ group: [[[ValueText]]]) -> Bool {
        guard let midX = self.compactMap({ $0.first?.text }).midXOfShortestText,
              let shortestText = group.shortestText
        else {
            return false
        }
        
        return midX >= shortestText.rect.minX && midX <= shortestText.rect.maxX
    }

    //TODO-NEXT: Remove
    mutating func removeValueTextRowsAboveEnergyValue() {
        guard let index = indexOfFirstEnergyValue else { return }
        removeFirst(index)
    }
    
    //TODO-NEXT: Remove
    var hasValueTextsAboveEnergyValue: Bool {
        /// Return false if we didn't detect an energy value
        guard let index = indexOfFirstEnergyValue else { return false }
        /// Return true if its not the first element
        return index != 0
    }

    //TODO-NEXT: Remove
    var indexOfFirstEnergyValue: Int? {
        for i in indices {
            if self[i].containsValueWithEnergyUnit {
                return i
            }
        }
        return nil
    }
    
    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.containsValueWithEnergyUnit })
    }
    
    var strings: [[String]] {
        map { $0.map { $0.value.description } }
    }
}

//MARK: [[[ValueText]]]

extension Array where Element == [[ValueText]] {
    //TODO-NEXT: Remove
    var shortestText: RecognizedText? {
        let shortestTexts = compactMap { $0.compactMap { $0.first?.text }.shortestText }
        return shortestTexts.sorted(by: { $0.rect.width < $1.rect.width }).first
    }
}

//MARK: [[[[ValueText]]]]

extension Array where Element == [[[ValueText]]] {
    var desc: [[[[String]]]] {
        map { $0.map { $0.map { $0.map { $0.description } } } }
    }
}

//MARK: [RecognizedText]

/// Column
extension Array where Element == RecognizedText {
    
    var minX: CGFloat? {
        map { $0.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.rect.maxX }.sorted(by: { $0 > $1 }).first
    }
    var allElementsContainNutrientAttributes: Bool {
        allSatisfy { $0.string.containsNutrientAttributes }
    }
    
    var allElementsArePercentageValues: Bool {
        allSatisfy { $0.string.isPercentageValue }
    }
    
    func containsTextsFrom(_ array: [RecognizedText]) -> Bool {
        contains { array.contains($0) }
    }
    
    var strings: [String] {
        map { $0.string }
    }
    
    /// Use `midX` of shortest text, checking if it lies within the shortest text of any column in each group
    func belongsTo(_ group: [[RecognizedText]]) -> Bool {
        guard let midX = self.midXOfShortestText,
              let shortestText = group.shortestText
        else {
            return false
        }
        
        return midX >= shortestText.rect.minX && midX <= shortestText.rect.maxX
    }
    
    //TODO-NEXT: Remove
    var midXOfShortestText: CGFloat? {
        shortestText?.rect.midX
    }
    
    var shortestText: RecognizedText? {
        sorted(by: { $0.rect.width < $1.rect.width }).first
    }

    mutating func removeTextsAboveEnergyValue() {
        guard let index = indexOfFirstEnergyValue else { return }
        removeFirst(index)
    }
    
    var indexOfFirstEnergyValue: Int? {
        for i in indices {
            if self[i].containsEnergyValue {
                return i
            }
        }
        return nil
    }
    
    var hasTextsAboveEnergyValue: Bool {
        /// Return false if we didn't detect an energy value
        guard let index = indexOfFirstEnergyValue else { return false }
        /// Return true if its not the first element
        return index != 0
    }
    
    var attributeTexts: [RecognizedText] {
        filter { $0.string.containsNutrientAttributes }
    }
    
    var inlineAttributeTexts: [RecognizedText] {
        filter { $0.string.containsInlineNutrients }
    }
}

//MARK: [[RecognizedText]]

extension Array where Element == [RecognizedText] {
    
    //TODO: Legacy, to be removed, replaced with ValuesTextColumn
    func extractValueTextsInSameColumn(as recognizedText: RecognizedText,
                                       preceding: Bool = false,
                                       ignoreSingularPercentValues: Bool = true) -> [[ValueText]]
    {
        //TODO: Rewrite this by removing first!
        //Also create test cases for it starting with spicy chips
        let texts = first!.filter {
            $0.isInSameColumnAs(recognizedText)
            && (preceding ? $0.rect.maxY < recognizedText.rect.maxY : $0.rect.minY > recognizedText.rect.minY)
        }.sorted {
            preceding ? $0.rect.minY > $1.rect.minY : $0.rect.minY < $1.rect.minY
        }
        
        /// Now go through the texts
        var valueTexts: [[ValueText]] = []
        var discarded: [RecognizedText] = []
        for text in texts {
            
            guard !discarded.contains(text) else {
                continue
            }
            
            /// Get texts on same row arrange by their `minX` values
            let textsOnSameRow = texts.filter {
                ($0.rect.minY < text.rect.maxY
                && $0.rect.maxY > text.rect.minY
                && $0.rect.maxX < text.rect.minX)
                || $0 == text
            }.sorted {
                $0.rect.minX < $1.rect.minX
            }
            
            guard let pickedText = textsOnSameRow.first,
                  !discarded.contains(pickedText)
            else {
                continue
            }
            discarded.append(contentsOf: textsOnSameRow)
            
            let values = FoodLabelValue.detect(in: pickedText.string)
            /// End the loop if any non-value, non-skippable texts are encountered
            guard values.count > 0 || text.string.isSkippableValueElement else {
                continue
            }
            
            /// Stop if a second energy value is encountered, only after a non-energy value has been added—as this usually indicates the bottom of the table where strings containing the representative diet (stating something like `2000 kcal diet`) are found.
            if valueTexts.containsValueWithEnergyUnit, values.containsValueWithEnergyUnit,
               let last = valueTexts.last, last.contains(where: { !$0.value.hasEnergyUnit }) {
                break
            }

            /// Discard any singular % values
            if values.count == 1, let first = values.first {
                guard first.unit != .p else {
                    continue
                }
            }
            
            valueTexts.append(
                values.map {
                    ValueText(value: $0, text: pickedText)
                }
            )
        }
        
        return valueTexts
    }
    
    var strings: [[String]] {
        map { $0.strings }
    }
    
    var shortestText: RecognizedText? {
        let shortestTexts = compactMap { $0.shortestText }
        return shortestTexts.sorted(by: { $0.rect.width < $1.rect.width }).first
    }
}

//MARK: [[[RecognizedText]]]

/// Array of Groups
extension Array where Element == [[RecognizedText]] {
    var strings: [[[String]]] {
        map { $0.strings }
    }
}

//MARK: [AttributeText]

extension Array where Element == AttributeText {
    var minX: CGFloat? {
        map { $0.text.rect.minX }.sorted(by: { $0 < $1 }).first
    }
    var maxX: CGFloat? {
        map { $0.text.rect.maxX }.sorted(by: { $0 > $1 }).first
    }
    
    var shortestText: RecognizedText? {
        map { $0.text }.shortestText
    }
    
    var averageMidX: CGFloat {
        guard count > 0 else { return 0 }
        let sum = self.reduce(0, { $0 + $1.text.rect.midX })
        return sum / Double(count)
    }
    
    var attributeDescription: String {
        map{ $0.attribute }.description
    }
    
    func contains(_ attribute: Attribute) -> Bool {
        contains(where: { $0.attribute == attribute })
    }
    
    func containsAnyAttributeIn(_ array: [AttributeText]) -> Bool {
        contains(where: { array.map({$0.attribute}).contains($0.attribute) })
    }
    
    var rect_legacy: CGRect {
        guard let first = self.first else { return .zero }
        var unionRect = first.text.rect
        for attributeText in self.dropFirst() {
            unionRect = unionRect.union(attributeText.text.rect)
        }
        return unionRect
    }

    var rect: CGRect {
        let attributesWithoutValues = self.filter { FoodLabelValue.detect(in: $0.text.string).count == 0 }
        guard let first = attributesWithoutValues.first else { return .zero }
        var unionRect = first.text.rect
        for attributeText in attributesWithoutValues.dropFirst() {
            unionRect = unionRect.union(attributeText.text.rect)
        }
        return unionRect
    }

}

//MARK: [[AttributeText]]
extension Array where Element == [AttributeText] {
    
    var attributeDescription: String {
        map { $0.map { $0.attribute } }.description
    }
    
    func containsArrayWithAnAttributeFrom(_ arrayToCheck: [AttributeText]) -> Bool {
        for array in self {
            if array.containsAnyAttributeIn(arrayToCheck) {
                return true
            }
        }
        return false
    }
    
    func indexOfSuperset(of array: [AttributeText]) -> Int? {
        let arrayAsSet = Set(array.map { $0.attribute })
        for i in indices {
            let set = Set(self[i].map { $0.attribute })
            if arrayAsSet.isSubset(of: set) {
                return i
            }
        }
        return nil
    }
    
    func indexOfSubset(of array: [AttributeText]) -> Int? {
        let arrayAsSet = Set(array.map { $0.attribute })
        for i in indices {
            let set = Set(self[i].map { $0.attribute })
            if set.isSubset(of: arrayAsSet) {
                return i
            }
        }
        return nil
    }

    func indexOfArrayContainingAnyAttribute(in arrayToCheck: [AttributeText]) -> Int? {
        for i in indices {
            let array = self[i]
            if array.contains(where: { arrayElement in
                arrayToCheck.contains { arrayToCheckElement in
                    arrayToCheckElement.attribute == arrayElement.attribute
                }
            }) {
                return i
            }
        }
        return nil
    }
}

extension Array where Element == [AttributeText] {
    func contains(_ attribute: Attribute) -> Bool {
        contains { array in
            array.contains {
                $0.attribute == attribute
            }
        }
    }
}

extension Array where Element == RecognizedText {
    func filterColumn(of recognizedText: RecognizedText, preceding: Bool = false) -> [RecognizedText] {
        let unfilteredColumn = filter {
            !$0.string.isEmpty
            && $0.isInSameColumnAs(recognizedText)
            && (preceding ? $0.rect.maxY < recognizedText.rect.maxY : $0.rect.minY > recognizedText.rect.minY)
        }.sorted {
            $0.rect.minY < $1.rect.minY
        }
        
        return unfilteredColumn
    }
}

extension Array where Element == [RecognizedText] {
    var firstValue: (FoodLabelValue, RecognizedText)? {
        for column in self {
            for text in column {
                if let value = text.firstValue {
                    return (value, text)
                }
            }
        }
        return nil
    }
}

extension RecognizedText {
    var firstValue: FoodLabelValue? {
        for candidate in candidates {
            if let value = FoodLabelValue.detectSingleValue(in: candidate) {
                return value
            }
        }
        return nil
    }
}

extension Array where Element == Observation {
    func printDescription() {
        self.forEach { observation in
             print(observation.description)
        }
    }
}

extension Array where Element == [AttributeText] {
    
    var attributes: [[Attribute]] {
        map { $0.map { $0.attribute } }
    }
    
    func attributeText(for attribute: Attribute) -> AttributeText? {
        for column in self {
            for attributeText in column {
                if attributeText.attribute == .energy {
                    return attributeText
                }
            }
        }
        return nil
    }
    
    //TODO: Write tests for these
    var bottomAttributeText: AttributeText? {
        let columns = self
        var bottom: AttributeText? = nil
        for column in columns {
            for attributeText in column {
                guard let bottomAttributeText = bottom else {
                    bottom = attributeText
                    continue
                }
                if attributeText.text.rect.maxY > bottomAttributeText.text.rect.maxY {
                    bottom = attributeText
                }
            }
        }
        return bottom
    }
    
    var topAttributeText: AttributeText? {
        let columns = self
        var top: AttributeText? = nil
        for column in columns {
            for attributeText in column {
                guard let topAttributeText = top else {
                    top = attributeText
                    continue
                }
                if attributeText.text.rect.minY < topAttributeText.text.rect.minY {
                    top = attributeText
                }
            }
        }
        return top
    }
    
    var energyAttributeText: AttributeText? {
        for column in self {
            for attributeText in column {
                if attributeText.attribute == .energy {
                    return attributeText
                }
            }
        }
        return nil
    }
    
    /// Returns true if any of the columns of Attributes contain the specified rect completely
    func contains(rect: CGRect) -> Bool {
        for columnRect in columnRects {
            if let ratio = rect.ratioOfIntersection(with: columnRect), ratio > 0.9 {
                return true
            }
        }
        return false
    }
    
    func overlapsVertically(with rect: CGRect) -> Bool {
        for attributeTextColumn in self {
            guard let first = attributeTextColumn.first, let last = attributeTextColumn.last else {
                continue
            }
            if rect.minY < last.text.rect.midY && rect.maxY > first.text.rect.maxY {
                return true
            }
        }
        return false
    }
    
    var columnRects: [CGRect] {
        self.map {
            $0.rect
        }
    }
}
