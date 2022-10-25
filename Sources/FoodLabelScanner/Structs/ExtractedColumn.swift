import SwiftUI
import VisionSugar
import TabularData
import PrepDataTypes

struct ExtractedColumn {
    
    var rows: [ExtractedRow]
    
    init(attributesColumn: [AttributeText], valueColumns: [ValuesTextColumn], isFirstAttributeColumn: Bool) {
        var attributesColumn = attributesColumn
        
        self.rows = attributesColumn.extractedRows(using: valueColumns, isFirstAttributeColumn: isFirstAttributeColumn)
        
        insertNilValues()
    }
    
    mutating func insertNilValues() {
        for column in 0..<(self.rows.first?.valuesTexts.count ?? 0) {
            assignNilToReusedValuesTexts(forColumn: column)
        }
    }

    var dataFrame: DataFrame {
        var dataFrame = DataFrame()
        let attributeColumn = Column(name: "attribute", contents: rows.map { $0.attributeText.attribute.rawValue })
        dataFrame.append(column: attributeColumn)
        let value1Column = Column(name: "value1", contents: rows.map { $0.valuesTexts[0] })
        dataFrame.append(column: value1Column)
        
        if rows.first?.valuesTexts.count == 2 {
            let value2Column = Column(name: "value2", contents: rows.map { $0.valuesTexts[1] })
            dataFrame.append(column: value2Column)
            let ratioColumn = Column(name: "ratio", contents: rows.map { $0.ratioColumn1To2 })
            dataFrame.append(column: ratioColumn)
        }
        return dataFrame
    }
    
    var values1Rect: CGRect? {
        let valuesTexts = rows.compactMap { $0.valuesTexts.first ?? nil }
        return valuesTexts.rectOfSingleValues
    }
    var values2Rect: CGRect? {
        guard rows.first?.valuesTexts.count == 2 else { return nil }
        let valuesTexts = rows.compactMap { $0.valuesTexts[1] ?? nil }
        return valuesTexts.rectOfSingleValues
    }
    
    var columnRects: (CGRect?, CGRect?) {
        (values1Rect, values2Rect)
    }
}

extension Array where Element == ValuesText {
    
    var singleValues: [ValuesText] {
        filter { FoodLabelValue.detect(in: $0.text.string).count == 1 }
    }
    
    var rectOfSingleValues: CGRect? {
        var rect: CGRect? = nil
//        for valuesText in self {
//            /// Only use single-valued `ValuesText`s to calculate the rect
//            guard valuesText.values.count == 1 else {
//                continue
//            }
        for valuesText in singleValues {
            guard let unionRect = rect else {
                rect = valuesText.text.rect
                continue
            }
            rect = unionRect.union(valuesText.text.rect)
        }
        return rect
    }
}
extension ExtractedColumn {
    mutating func assignNilToReusedValuesTexts(forColumn column: Int) {
        var dict: [ValuesText: (attributeText: AttributeText, index: Int)] = [:]
        for i in rows.indices {
            let row = rows[i]
            guard let valuesText = row.valuesTexts[column] else { continue }
            guard let previousTuple = dict[valuesText] else {
                dict[valuesText] = (row.attributeText, i)
                continue
            }
            
            //TODO: NEXT!
            // AttributeText needs to be modified so that it can have a group of `RecognizedText` objects associated with it
            // Do this without break
            
            
            /// We've encountered the same `ValuesText` again
            
            let previousDistance = previousTuple.attributeText.yDistanceTo(valuesText: valuesText)
            let distance = row.attributeText.yDistanceTo(valuesText: valuesText)
            
            /// If the distance to its previous `attributeText` is greater than to this one, set that `ExtractedRow` to nil
            if previousDistance > distance  {
                rows[previousTuple.index].valuesTexts[column] = nil
                dict[valuesText] = (row.attributeText, i)
            } else {
                rows[i].valuesTexts[column] = nil
            }
        }
    }
}

extension Array where Element == AttributeText {

    func extractedRowsAfterInsertingNilInSingleMissingValuesPlace(using valueColumns: [ValuesTextColumn]) -> [ExtractedRow] {
        
        /// First create the empty rows with the attributes in order
        var rows: [ExtractedRow] = map { ExtractedRow(attributeText: $0, valuesTexts: valueColumns.map { _ in nil }) }
        
        /// Then for each each column
        for columnIndex in valueColumns.indices {
            let column = valueColumns[columnIndex]
            
            /// If the count matches, simply append the values
            guard column.valuesTexts.count != rows.count else {
                column.valuesTexts.indices.forEach { rowIndex in
                    let valueText = column.valuesTexts[rowIndex]
                    if columnIndex == 0 {
                        rows[rowIndex].valuesTexts[0] = valueText
                    } else {
                        rows[rowIndex].valuesTexts[1] = valueText
                    }
                }
                continue
            }
            
            //TODO: Support multiple nil values by changing this to a count instead
            var nilAdded = false
            
            /// Otherwise, go through their values
            for rowIndex in rows.indices {
                
                let row = rows[rowIndex]
                let attributeText = row.attributeText

                if !nilAdded {
                    /// Checking that each successive item is the closest (overlapping) text
                    guard let closest = column.valuesTexts.closestValueText(to: attributeText, in: self, requiringOverlap: true),
                          rowIndex < column.valuesTexts.count,
                          closest.text.id == column.valuesTexts[rowIndex].text.id
                    else {
                        /// As soon as we reach one that fails this requirement, insert nil in its place
                        if columnIndex == 0 {
                            rows[rowIndex].valuesTexts[0] = nil
                        } else {
                            rows[rowIndex].valuesTexts[1] = nil
                        }
                        nilAdded = true
                        continue
                    }
                }
                
                let valueText = column.valuesTexts[nilAdded ? rowIndex - 1 : rowIndex]
                /// Otherwise, business as usual—keep appending the rows
                if columnIndex == 0 {
                    rows[rowIndex].valuesTexts[0] = valueText
                } else {
                    rows[rowIndex].valuesTexts[1] = valueText
                }
            }
        }
        
        return rows
    }
    
    func extractedRowsWithMissingValues(using valueColumns: [ValuesTextColumn]) -> [ExtractedRow] {
        var rows: [ExtractedRow] = []
        
        for i in indices {
            let attributeText = self[i]
            var valuesTexts: [ValuesText?] = []
            
            //TODO: Check why some test cases fail when added again?
            
            for column in valueColumns {
                
                if i == 0, attributeText.text == defaultText, let firstValuesText = column.valuesTexts.first {
                    valuesTexts.append(firstValuesText)
                    continue
                }
                
                /// Using this breaks a lot of other cases, so possibly just remove it when presetting
//                let remainingValuesTexts = column.valuesTexts.filter { !rows.allValuesTexts.contains($0) }
//                guard let closest = remainingValuesTexts.closestValueText(to: attributeText)
                guard let closest = column.valuesTexts.closestValueText(to: attributeText)
                else {
                    valuesTexts.append(nil)
                    continue
                }
                
                //TODO-NEXT: If this is column 0 and the closest value is at the row
                if let columnIndex = valueColumns.firstIndex(of: column), columnIndex == 0,
                   let closestValueIndex = column.valuesTexts.firstIndex(of: closest),
                   column.valuesTexts.count - closestValueIndex == self.count - rows.count,
                   valueColumns.count > 1,
                   let closestValue2 = valueColumns[1].valuesTexts.closestValueText(to: attributeText),
                   let closestValue2Index = valueColumns[1].valuesTexts.firstIndex(of: closestValue2),
                   valueColumns[1].valuesTexts.count - closestValue2Index == self.count - rows.count
                {
                    let remainingValues = column.valuesTexts.suffix(self.count - rows.count)
                    var valuesArray: [ValuesText] = []
                    valuesArray.append(contentsOf: remainingValues)

                    let remainingValues2: [ValuesText]?
                    var values2Array: [ValuesText]? = []

                    if valueColumns.count > 1 {
                        remainingValues2 = valueColumns[1].valuesTexts.suffix(self.count - rows.count)
                        values2Array?.append(contentsOf: remainingValues2!)
                    } else {
                        remainingValues2 = nil
                        values2Array = nil
                    }

                    let remainingAttributes = self.suffix(self.count - rows.count)
                    var attributesArray: [AttributeText] = []
                    attributesArray.append(contentsOf: remainingAttributes)

                    for i in attributesArray.indices {
                        let attributeText = attributesArray[i]
                        let value1 = valuesArray[i]
                        let value2 = values2Array?[i]
                        let row = ExtractedRow(attributeText: attributeText, valuesTexts: [value1, value2])
                        rows.append(row)
                    }
                    return rows
                }
                valuesTexts.append(closest)
            }
            let row = ExtractedRow(attributeText: attributeText, valuesTexts: valuesTexts)
            rows.append(row)
        }
        return rows
    }
    
    mutating func extractedRows(using valueColumns: [ValuesTextColumn], isFirstAttributeColumn: Bool) -> [ExtractedRow] {
        
        var rows: [ExtractedRow] = []
        var valueColumns = valueColumns
        
        /// Special case where we may have only 1 value missing. If either side is short by just 1 value from the attribute count (**possibly increase this and handle greater missing values later**)—then go through the column(s) that's short until we hit the first value that's not inline with an the expected attribute—and insert nil there, and then continue adding the rest.
        if valueColumns.hasSingleColumnMissingOnlyOneValue(forAttributeCount: self.count),
           !containsManuallyAddedAttributeTexts
        {
            return rows + extractedRowsAfterInsertingNilInSingleMissingValuesPlace(using: valueColumns)
        }
        
        //TODO: Clean this up
        /// If the first set of values contain energy values and we seem to have missed creating an attribute for it (possibly due to a typo such as in `3EDD65E5-6363-42E3-8358-21A520ED21CC`, then manually insert a `AttributeText` for it so that it's correctly assigned
        if isFirstAttributeColumn, !contains(.energy),
           let energyValuesTexts = valueColumns.firstSetOfValuesTextsContainingEnergy
        {
            let attributeText = AttributeText(attribute: .energy, text: defaultText)
//            self.insert(attributeText, at: 0)
            let energyRow = ExtractedRow(attributeText: attributeText, valuesTexts: energyValuesTexts)
            rows.append(energyRow)
            valueColumns.removeFirstSetOfValues()
            
            /// Try this again after removing first set of values from the value column
            //TODO: Clean this up
            if valueColumns.hasSingleColumnMissingOnlyOneValue(forAttributeCount: self.count),
               !containsManuallyAddedAttributeTexts
            {
                return rows + extractedRowsAfterInsertingNilInSingleMissingValuesPlace(using: valueColumns)
            }
        }
        
        /// If we have a common count and it matches the count of attributes, go ahead and map them 1-1
        if let commonCount = valueColumns.commonCount, commonCount == self.count {
            return rows + indices.map { i in
                ExtractedRow(attributeText: self[i],
                             valuesTexts: valueColumns.map { $0.valuesTexts[i] }
                )
            }
        }
        
        /// As a fallback—map rows to attributes based on how in-line they are
        return rows + extractedRowsWithMissingValues(using: valueColumns)
    }
    
    var containsManuallyAddedAttributeTexts: Bool {
        contains(where: { $0.text.id == defaultText.id })
    }
}


extension Array where Element == ValuesTextColumn {
    
    /// This heuristic only works when not more than one column has 1 value missing
    func hasSingleColumnMissingOnlyOneValue(forAttributeCount count: Int) -> Bool {
        guard self.count == 2 else {
            return first?.valuesTexts.count == count - 1
        }
        
        return (
            (self[0].valuesTexts.count == count
            &&
             self[1].valuesTexts.count == count - 1
            )
            ||
            (self[1].valuesTexts.count == count
            &&
             self[0].valuesTexts.count == count - 1
            )
        )
    }
    
    var commonCount: Int? {
        var count: Int? = nil
        for column in self {
            guard let currentCount = count else {
                count = column.valuesTexts.count
                continue
            }
            guard currentCount == column.valuesTexts.count else {
                return nil
            }
        }
        return count
    }
}
