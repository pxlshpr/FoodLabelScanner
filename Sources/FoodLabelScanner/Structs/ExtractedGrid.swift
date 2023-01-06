import SwiftUI
import VisionSugar
import SwiftSugar
import PrepDataTypes

let RatioErrorPercentageThreshold = 17.0
let MacroOrEnergyErrorPercentageThreshold = 20.0

struct ExtractedGrid {
    
    var columns: [ExtractedColumn]
    let numberOfValues: Int
    
    init(attributes: [[AttributeText]], values: [[ValuesTextColumn]], textSet: RecognizedTextSet) {
        
        var columns: [ExtractedColumn] = []
        
        for i in attributes.indices {
            guard i < values.count else {
                //TODO: Remove all fatalErrors after testing
                self.columns = []
                self.numberOfValues = 0
                return
//                fatalError("Expected groupedColumnsOfValues to have: \(i) columns")
            }
            
            let attributesColumn = attributes[i]
            let valueColumns = values[i]
            let column = ExtractedColumn(attributesColumn: attributesColumn,
                                         valueColumns: valueColumns,
                                         isFirstAttributeColumn: i == 0)
            columns.append(column)
        }
        
        self.columns = columns
        self.numberOfValues = columns.first?.rows.first?.valuesTexts.count ?? 0

        insertMissingColumnForMultipleValuedColumns()
        
        findSingleEnergyValueIfMissing(in: textSet)
        
        removeValuesOutsideColumnRects()
        removeExtraneousValues()

        handleReusedValueTexts()

        ///**Removed as we were getting a fatal index out of bounds error here**
        //replaceNilMacroAndChildrenValuesIfZero()

        handleMultipleEnergyValuesWithinColumn()
        handleMultipleValues(using: validRatio)

        fixInvalidChildRows()
        fillInRowsWithOneMissingValue()
        fixInvalidRows()
        fixInvalidRowsContainingLessThanPrefix()

        fixSingleInvalidMacroOrEnergyRow()
        removeEmptyValues()
        removeRowsWithMultipleValues()
        removeRowsWithNotInlineValues()

        fillInMissingUnits()

        addMissingEnergyValuesIfNeededAndAvailable()
        convertMismatchedEnergyUnits()
        addMissingMacroOrEnergyValuesIfPossible()
    }
    
    var values: [[[FoodLabelValue?]]] {
        columns.map {
            $0.rows.map { $0.valuesTexts.map { $0?.values.first } }
        }
    }
    
    func row(for attribute: Attribute) -> ExtractedRow? {
        allRows.first(where: { $0.attributeText.attribute == attribute })
    }
}

extension Array where Element == Bool? {
    var onlyOneOfTwoIsTrue: Bool {
        count == 2
        && (
            (self[0] == true && self[1] != true)
            ||
            (self[0] != true && self[1] == true)
        )
    }
}

extension Array where Element == ExtractedColumn {
    mutating func modify(_ row: ExtractedRow, with newValues: (FoodLabelValue, FoodLabelValue)) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.modify(row, with: newValues)
                self[columnIndex] = column
            }
        }
    }

    mutating func modify(_ row: ExtractedRow, with newValue: FoodLabelValue) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.modify(row, with: newValue)
                self[columnIndex] = column
            }
        }
    }

    mutating func modify(_ row: ExtractedRow, with newRow: ExtractedRow) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.modify(row, with: newRow)
                self[columnIndex] = column
            }
        }
    }

    mutating func remove(_ row: ExtractedRow) {
        for columnIndex in indices {
            var column = self[columnIndex]
            if column.contains(row) {
                column.remove(row)
                self[columnIndex] = column
            }
        }
    }
    
    mutating func fillInMissingUnits() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.fillInMissingUnits()
            self[columnIndex] = column
        }
    }
    
    mutating func handleMultipleValues(using ratio: Double?) {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.handleMultipleValues(using: ratio)
            self[columnIndex] = column
        }
    }
    
    mutating func removeRowsWithMultipleValues() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.removeRowsWithMultipleValues()
            self[columnIndex] = column
        }
    }
    
    mutating func insertMissingColumnForMultipleValuedColumns() {
        for columnIndex in indices {
//            if column.
//            var column = self[columnIndex]
//            column.insertMissingColumnForMultipleValuedColumns()
//            self[columnIndex] = column
        }
    }
    
    mutating func removeRowsWithNotInlineValues() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.removeRowsWithNotInlineValues()
            self[columnIndex] = column
        }
    }
    
    mutating func handleReusedValueTexts() {
        for columnIndex in indices {
            var column = self[columnIndex]
            column.handleReusedValueTexts()
            self[columnIndex] = column
        }
    }
}
extension ExtractedColumn {
    mutating func modify(_ row: ExtractedRow, with newValues: (FoodLabelValue, FoodLabelValue)) {
        rows.modify(row, with: newValues)
    }

    mutating func modify(_ row: ExtractedRow, with newValue: FoodLabelValue) {
        rows.modify(row, with: newValue)
    }

    mutating func modify(_ row: ExtractedRow, with newRow: ExtractedRow) {
        rows.modify(row, with: newRow)
    }

    mutating func remove(_ row: ExtractedRow) {
        rows.removeAll(where: { $0.attributeText.attribute == row.attributeText.attribute })
    }
    
    func contains(_ row: ExtractedRow) -> Bool {
        rows.contains(where: { $0.attributeText.attribute == row.attributeText.attribute })
    }
 
    mutating func fillInMissingUnits() {
        rows.fillInMissingUnits()
    }
    
    mutating func removeRowsWithMultipleValues() {
        rows.removeRowsWithMultipleValues()
    }
    
    mutating func removeRowsWithNotInlineValues() {
        rows.removeAll { row in
            let attributeRect = row.attributeText.allTextsRect
            guard let value1Rect = row.valuesTexts[0]?.text.rect else {
                return false
            }
            return attributeRect.minY < value1Rect.minY
            &&
            attributeRect.minX > value1Rect.minX
        }
    }
    
    mutating func handleMultipleValues(using ratio: Double?) {
        for row in rowsWithMultipleValues {
            
            /// First see if these are multple values for successive attributes on the same line
            if attemptHandlingMultipleValuesForInlineMultipleAttributes(for: row) {
                continue
            }
            
            if attemptHandlingMultipleValuesByDistributingAcrossValues(for: row) {
                continue
            }
            
            if let ratio = ratio, attemptHandlingMultipleValuesUsingRatio(ratio, for: row) {
                continue
            }
        }
    }
    
    mutating func attemptHandlingMultipleValuesUsingRatio(_ validRatio: Double, for row: ExtractedRow) -> Bool {
        guard let valuesText1 = row.valuesTexts[0], let valuesText2 = row.valuesTexts[1] else {
            return false
        }
        
        /// If we have one value in the first column, and two in the second
        if valuesText1.values.count == 1, valuesText2.values.count > 1, let value1 = valuesText1.values.first {
            
            /// Pick whichever value from `valuesText2` results in the ratio closest to `ratio`
            var closestValue: FoodLabelValue? = nil
            for value in valuesText2.values {
                guard let closest = closestValue else {
                    closestValue = value
                    continue
                }
                let closestRatio = value1.amount/closest.amount
                let ratio = value1.amount/value.amount
                if abs(ratio - validRatio) < abs(closestRatio - validRatio) {
                    closestValue = value
                }
            }
            guard let closestValue = closestValue else {
                return false
            }

            modify(row, with: (value1, closestValue))
            return true
        }

        /// If we have two values in the first column, and one in the second
        if valuesText2.values.count == 1, valuesText1.values.count > 1, let value2 = valuesText2.values.first {
            
            /// Pick whichever value from `valuesText1` results in the ratio closest to `ratio`
            var closestValue: FoodLabelValue? = nil
            for value in valuesText1.values {
                guard let closest = closestValue else {
                    closestValue = value
                    continue
                }
                let closestRatio = closest.amount/value2.amount
                let ratio = value.amount/value2.amount
                if abs(ratio - validRatio) < abs(closestRatio - validRatio) {
                    closestValue = value
                }
            }
            guard let closestValue = closestValue else {
                return false
            }

            modify(row, with: (closestValue, value2))
            return true
        }

        return false
    }

    mutating func attemptHandlingMultipleValuesByDistributingAcrossValues(for row: ExtractedRow) -> Bool {
        let valuesText: ValuesText?
        if let vt = row.valuesTexts[0] {
            valuesText = vt
        } else if let vt = row.valuesTexts[1] {
            valuesText = vt
        } else {
            valuesText = nil
        }
        
        guard let valuesText = valuesText, valuesText.values.count > 1 else {
            return false
        }
        
        modify(row, with: (valuesText.values[0], valuesText.values[1]))
        return true
    }
     
    mutating func attemptHandlingMultipleValuesForInlineMultipleAttributes(for row: ExtractedRow) -> Bool {
        /// If we have multiple values, and the next attribute shares the same attribute text as the one with multiple values, this implies we have something along the lines of `Sodium/Salt` (see case `31D0CA8B-5069-4AB3-B865-47CD1D15D879`) with inline values within the column.
        /// We handle this by keeping the first value and assigning the second value to the next row (within the same column), essentially discarding any remaining values.
        /// We currently support two inline values, but this can be extended by checking rows further down the line if we have more values.
        guard let index = indexOfRow(row),
              index < rows.count - 1,
              rows[index+1].attributeText.text == row.attributeText.text
        else {
            return false
        }
        
        /// If it's in the first column
        if !row.valuesTexts.isEmpty, let valuesText = row.valuesTexts[0] {
            let values = valuesText.values
            guard values.count > 1 else {
                return false
            }
            
            var newValuesText = valuesText
            newValuesText.values = [values[0]]
            rows[index].valuesTexts[0] = newValuesText
            
            var newValuesTextForNextRow = valuesText
            newValuesTextForNextRow.values = [values[1]]
            rows[index+1].valuesTexts[0] = newValuesTextForNextRow
        }
        /// If it's also in the second column
        if row.valuesTexts.count > 1, let valuesText = row.valuesTexts[1] {
            let values = valuesText.values
            guard values.count > 1 else {
                return false
            }
            
            var newValuesText = valuesText
            newValuesText.values = [values[0]]
            rows[index].valuesTexts[1] = newValuesText
            
            var newValuesTextForNextRow = valuesText
            newValuesTextForNextRow.values = [values[1]]
            rows[index+1].valuesTexts[1] = newValuesTextForNextRow
        }
        return true
    }
    
    mutating func handleReusedValueTexts() {
        rows.handleReusedValueTexts(using: columnRects)
    }
    
    var rowsWithMultipleValues: [ExtractedRow] {
        rows.filter { $0.containsValueTextsWithMultipleValues }
    }
    
    func indexOfRow(_ row: ExtractedRow) -> Int? {
        rows.firstIndex(where: { $0.attributeText.attribute == row.attributeText.attribute })
    }
}

extension Array where Element == ExtractedRow {
    var desc: [String] {
        map { $0.desc }
    }
    
    mutating func modify(_ rowToModify: ExtractedRow, with newValues: (FoodLabelValue, FoodLabelValue)) {
        for i in indices {
            var row = self[i]
            if row.attributeText.attribute == rowToModify.attributeText.attribute {
                row.modify(with: newValues)
                self[i] = row
            }
        }
    }

    mutating func modify(_ rowToModify: ExtractedRow, with newValue: FoodLabelValue) {
        for i in indices {
            var row = self[i]
            if row.attributeText.attribute == rowToModify.attributeText.attribute {
                row.modify(with: newValue)
                self[i] = row
            }
        }
    }

    mutating func modify(_ rowToModify: ExtractedRow, with newRow: ExtractedRow) {
        for i in indices {
            let row = self[i]
            if row.attributeText.attribute == rowToModify.attributeText.attribute {
                self[i] = newRow
            }
        }
    }

    mutating func fillInMissingUnits() {
        for i in indices {
            var row = self[i]
            row.fillInMissingUnits()
            self[i] = row
        }
    }
    
    mutating func removeRowsWithMultipleValues() {
        removeAll { $0.containsValueTextsWithMultipleValues }
    }
    
    mutating func handleReusedValueTexts(using columnRects: (CGRect?, CGRect?)) {
        for rowIndex in indices {
            var row = self[rowIndex]
            row.handleReusedValueTexts(using: columnRects)
            self[rowIndex] = row
        }
    }
    
    var allValuesTexts: [ValuesText] {
        map { row in
            row.valuesTexts.compactMap{ $0 }
        }.reduce([], +)
    }
}

extension ExtractedRow {
    
    var containsValueTextsWithMultipleValues: Bool {
        valuesTexts.contains(where: { valuesText in
            guard let valuesText = valuesText else {
                return false
            }
            return valuesText.values.count > 1
        })
    }
    mutating func fillInMissingUnits() {
        if valuesTexts.count > 0, let valuesText = valuesTexts[0], !valuesText.values.isEmpty, valuesText.values.first?.unit == nil {
            var new = valuesText
            if attributeText.attribute == .energy,
               attributeText.text.string.lowercased().contains("cal")
            {
                new.values[0].unit = .kcal
            } else {
                new.values[0].unit = attributeText.attribute.defaultUnit
            }
            valuesTexts[0] = new
        }

        if valuesTexts.count == 2, let valuesText = valuesTexts[1], !valuesText.values.isEmpty, valuesText.values.first?.unit == nil {
            var new = valuesText
            if attributeText.attribute == .energy,
               attributeText.text.string.lowercased().contains("cal")
            {
                new.values[0].unit = .kcal
            } else {
                new.values[0].unit = attributeText.attribute.defaultUnit
            }
            valuesTexts[1] = new
        }
    }
    
    mutating func handleReusedValueTexts(using columnRects: (CGRect?, CGRect?)) {
        guard valuesTexts.count == 2,
              let valuesText = valuesTexts[0],
              let valuesText2 = valuesTexts[1],
              let columnRect1 = columnRects.0,
              let columnRect2 = columnRects.1,
              valuesText == valuesText2
        else {
            return
        }
        
        /// We're comparing the middle of the values text to the start of each column rect (instead of their middle) to account for columns that may overlap each other. This was mainly to alleviate case `31D0CA8B-5069-4AB3-B865-47CD1D15D879`.
        let distanceToStart1 = abs(valuesText.text.rect.midX - columnRect1.minX)
        let distanceToStart2 = abs(valuesText.text.rect.midX - columnRect2.minX)

        if distanceToStart1 > distanceToStart2 {
            valuesTexts[0] = nil
        } else {
            valuesTexts[1] = nil
        }
    }

    mutating func modify(with newValues: (FoodLabelValue, FoodLabelValue)) {
        if !valuesTexts.isEmpty, let existing = valuesTexts[0] {
            var new = existing
            new.values = [newValues.0]
            valuesTexts[0] = new
        } else {
            let newValuesText = ValuesText(values: [newValues.0])
            //TODO: We're getting a index out of range (fatal) error here sometime when scanning Sardines
            valuesTexts[0] = newValuesText
        }
        
        guard valuesTexts.count > 1 else {
            return
        }
        if let existing = valuesTexts[1] {
            var new = existing
            new.values = [newValues.1]
            valuesTexts[1] = new
        } else {
            valuesTexts[1] = ValuesText(values: [newValues.1])
        }
    }

    mutating func modify(with newValue: FoodLabelValue) {
        if !valuesTexts.isEmpty, let existing = valuesTexts[0] {
            var new = existing
            new.values = [newValue]
            valuesTexts[0] = new
        } else {
            valuesTexts[0] = ValuesText(values: [newValue])
        }
    }

    var containsExtraneousValues: Bool {
        valuesTexts.contains { $0?.containsExtraneousValues == true }
    }
    
    func containsValueOutside(_ columnRects: (CGRect?, CGRect?)) -> Bool {
        if let columnRect = columnRects.0, let textRect = valuesTexts.first??.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                return true
            }
        }
        if let columnRect = columnRects.1, valuesTexts.count == 2, let textRect = valuesTexts[1]?.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                return true
            }
        }
        return false
    }
    
    func withoutValuesOutsideColumnRects(_ columnRects: (CGRect?, CGRect?)) -> ExtractedRow {
        var newRow = self
        newRow.removeValuesOutsideColumnRects(columnRects)
        return newRow
    }
    
    var withoutExtraneousValues: ExtractedRow {
        var newRow = self
        newRow.removeExtraneousValues()
        return newRow
    }
    
    mutating func removeExtraneousValues() {
        for i in valuesTexts.indices {
            guard let valueText = valuesTexts[i], valueText.containsExtraneousValues else {
                continue
            }
            var newValueText = valueText
            newValueText.removeExtraneousValues()
            valuesTexts[i] = newValueText
        }
    }
    
    mutating func removeValuesOutsideColumnRects(_ columnRects: (CGRect?, CGRect?)) {
        if let columnRect = columnRects.0, let textRect = valuesTexts.first??.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                valuesTexts[0] = nil
            }
        }
        if let columnRect = columnRects.1, valuesTexts.count == 2, let textRect = valuesTexts[1]?.text.rect {
            if !textRect.isInSameColumnAs(columnRect) {
                valuesTexts[1] = nil
            }
        }
    }
    
    var desc: String {
        var string = "\(attributeText.attribute.rawValue)"
        if let valuesText = valuesTexts.first {
            string += ": \(valuesText?.description ?? "nil")"
        }
        if valuesTexts.count == 2 {
            string += ", \(valuesTexts[1]?.description ?? "nil")"
        }
        return string
    }
}

extension CGRect {
    func isInSameColumnAs(_ rect: CGRect) -> Bool {
        let yNormalized = rectWithYValues(of: rect)
        return yNormalized.intersects(rect)
    }
}
extension ValuesText {
    mutating func removeExtraneousValues() {
        values.removeAll(where: { $0.unit == .p })
        if values.contains(where: { $0.unit != nil }) {
            values.removeAll(where: { $0.unit == nil })
        }
    }
    
    func rectNotInSameColumnAs(_ columnRect: CGRect) -> Bool {
        //😵‍💫
        false
    }
    
    var containsExtraneousValues: Bool {
        values.contains(where: { $0.unit == .p })
        ||
        (
            values.contains(where: { $0.unit != nil })
            &&
            values.contains(where: { $0.unit == nil })
        )
    }
}

extension ExtractedGrid {

    mutating func remove(_ row: ExtractedRow) {
        columns.remove(row)
    }
    
    mutating func modify(_ row: ExtractedRow, withNewValues newValues: (FoodLabelValue, FoodLabelValue)) {
        // print("2️⃣ Correct row: \(row.attributeText.attribute) with: \(newValues.0.description) and \(newValues.1.description)")
        columns.modify(row, with: newValues)
        // print("2️⃣ done.")
    }

    mutating func modify(_ row: ExtractedRow, withNewValue newValue: FoodLabelValue) {
        columns.modify(row, with: newValue)
    }

    mutating func modify(_ row: ExtractedRow, with newRow: ExtractedRow) {
        columns.modify(row, with: newRow)
    }

    mutating func addMissingEnergyValuesIfNeededAndAvailable() {
        guard row(for: .energy) == nil else {
            return
        }
        //TODO: Do this when a test case requires us to
    }
    
    mutating func addMissingMacroOrEnergyValuesIfPossible() {
        guard let missingAttribute = allRows.missingMacroOrEnergyAttribute else {
            return
        }
        
        switch missingAttribute {
        case .energy:
            guard let amount1 = calculateAmount(for: .energy, in: 0) else {
                return
            }
            let attributeText = AttributeText(attribute: .energy, text: defaultText)
            let valuesText1 = ValuesText(values: [FoodLabelValue(amount: amount1.roundedNutrientAmount, unit: .kcal)])
            if numberOfValues == 2 {
                guard let amount2 = calculateAmount(for: .energy, in: 1) else {
                    return
                }
                let valuesText2 = ValuesText(values: [FoodLabelValue(amount: amount2.roundedNutrientAmount, unit: .g)])
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1, valuesText2])
                columns[0].rows.insert(row, at: 0)
            } else {
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1])
                columns[0].rows.insert(row, at: 0)
            }
        case .carbohydrate:
            guard let amount1 = calculateAmount(for: .carbohydrate, in: 0) else {
                return
            }
            let attributeText = AttributeText(attribute: .carbohydrate, text: defaultText)
            let valuesText1 = ValuesText(values: [FoodLabelValue(amount: amount1.roundedNutrientAmount, unit: .g)])
            if numberOfValues == 2 {
                guard let amount2 = calculateAmount(for: .carbohydrate, in: 1) else {
                    return
                }
                let valuesText2 = ValuesText(values: [FoodLabelValue(amount: amount2.roundedNutrientAmount, unit: .g)])
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1, valuesText2])
                columns[0].rows.append(row)
            } else {
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1])
                columns[0].rows.append(row)
            }
        case .protein:
            guard let amount1 = calculateAmount(for: .protein, in: 0) else {
                return
            }
            let attributeText = AttributeText(attribute: .protein, text: defaultText)
            let valuesText1 = ValuesText(values: [FoodLabelValue(amount: amount1.roundedNutrientAmount, unit: .g)])
            if numberOfValues == 2 {
                guard let amount2 = calculateAmount(for: .protein, in: 1) else {
                    return
                }
                let valuesText2 = ValuesText(values: [FoodLabelValue(amount: amount2.roundedNutrientAmount, unit: .g)])
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1, valuesText2])
                columns[0].rows.append(row)
            } else {
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1])
                columns[0].rows.append(row)
            }
        case .fat:
            guard let amount1 = calculateAmount(for: .fat, in: 0) else {
                return
            }
            let attributeText = AttributeText(attribute: .fat, text: defaultText)
            let valuesText1 = ValuesText(values: [FoodLabelValue(amount: amount1.roundedNutrientAmount, unit: .g)])
            if numberOfValues == 2 {
                guard let amount2 = calculateAmount(for: .fat, in: 1) else {
                    return
                }
                let valuesText2 = ValuesText(values: [FoodLabelValue(amount: amount2.roundedNutrientAmount, unit: .g)])
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1, valuesText2])
                columns[0].rows.append(row)
            } else {
                let row = ExtractedRow(attributeText: attributeText, valuesTexts: [valuesText1])
                columns[0].rows.append(row)
            }
        default:
            return
        }
    }
    
    mutating func convertMismatchedEnergyUnits() {
        guard let row = row(for: .energy), row.hasMismatchedUnits,
              let value1 = row.value1, let value2 = row.value2
        else {
            return
        }
        
        if value1.unit == .kj, value2.unit == .kcal {
            /// Convert unit2 to kj
//            let newValue2 = FoodLabelValue(amount: value2.amount * KcalsPerKilojule, unit: .kj)
            let newValue2 = FoodLabelValue(amount: EnergyUnit.kcal.convert(value2.amount, to: .kJ), unit: .kj)
            modify(row, withNewValues: (value1, newValue2))
        } else if value1.unit == .kcal, value2.unit == .kj {
            /// Convert unit1 to kj
//            let newValue1 = FoodLabelValue(amount: value1.amount * KcalsPerKilojule, unit: .kj)
            let newValue1 = FoodLabelValue(amount: EnergyUnit.kcal.convert(value1.amount, to: .kJ), unit: .kj)
            modify(row, withNewValues: (newValue1, value2))
        }
    }
    
    mutating func fillInMissingUnits() {
        columns.fillInMissingUnits()
    }

    mutating func handleMultipleValues(using ratio: Double?) {
        columns.handleMultipleValues(using: ratio)
    }
    
    mutating func handleMultipleEnergyValuesWithinColumn() {
        /// if we have 1 column, with two values—pick the larger value assuing it to be kJ
        guard numberOfValues == 1,
              let energyRow = row(for: .energy),
              let values = energyRow.valuesTexts[0]?.values,
              /// Only check that the first two values alone are unitless and pick the larger value between them, to support cases where artefacts of other languages may be read in as incorrect values
              values.count > 1,
              values[0].unit == nil,
              values[1].unit == nil,
              let valuesText = energyRow.valuesTexts[0]
        else {
            return
        }

        let amount1 = values[0].amount
        let amount2 = values[1].amount

        let kjAmount = max(amount1, amount2)
        var newValuesText = valuesText
        newValuesText.values = [FoodLabelValue(amount: kjAmount, unit: .kj)]
        var newRow = energyRow
        newRow.valuesTexts = [newValuesText]
        modify(energyRow, with: newRow)
    }
    
    mutating func handleReusedValueTexts() {
        columns.handleReusedValueTexts()
    }
    
    mutating func removeRowsWithMultipleValues() {
        columns.removeRowsWithMultipleValues()
    }

    mutating func insertMissingColumnForMultipleValuedColumns() {
        columns.insertMissingColumnForMultipleValuedColumns()
    }
    
    mutating func removeRowsWithNotInlineValues() {
        columns.removeRowsWithNotInlineValues()
    }
    
    mutating func fillInRowsWithOneMissingValue() {
        guard let validRatio = validRatio else {
            return
        }
        
        /// For each row with one missing value
        /// Use the `validRatio` to fill in the missing value
        for row in rowsWithOneMissingValue {
            guard let missingIndex = row.singleMissingValueIndex else {
                continue
            }
            if missingIndex == 1 {
                guard let value = row.valuesTexts[0]?.values.first else {
                    continue
                }
                let amount = (value.amount / validRatio).roundedNutrientAmount
                modify(row, withNewValues: (value, FoodLabelValue(amount: amount, unit: value.unit)))
            }
            else if missingIndex == 0 {
                guard let value = row.valuesTexts[1]?.values.first else {
                    continue
                }
                let amount = (value.amount * validRatio).roundedNutrientAmount
                modify(row, withNewValues: (FoodLabelValue(amount: amount, unit: value.unit), value))
            }
        }
    }
    
    func amountFor(_ attribute: Attribute, at index: Int) -> Double? {
        allRows.valueFor(attribute, valueIndex: index)?.amount
    }
    
    func energyInKcal(at index: Int) -> Double? {
        guard let energyValue = allRows.valueFor(.energy, valueIndex: index) else {
            return nil
        }
        if energyValue.unit == .kj {
            return EnergyUnit.kJ.convert(energyValue.amount, to: .kcal)
//            return energyValue.amount / KcalsPerKilojule
        } else {
            return energyValue.amount
        }
    }

    func calculateValue(for attribute: Attribute, in index: Int) -> FoodLabelValue? {
        guard let amount = calculateAmount(for: attribute, in: index) else {
            return nil
        }
        let validValue = allRows.valueFor(attribute, valueIndex: index == 0 ? 1 : 0)
        let unit: FoodLabelUnit
        if let validUnit = validValue?.unit {
            unit = validUnit
        } else {
            unit = attribute == .energy ? .kj : .g
        }
        
        let value: Double
        if attribute == .energy && unit == .kj {
            value = EnergyUnit.kJ.convert(amount, to: .kcal).rounded(toPlaces: 0)
//            return FoodLabelValue(amount: (amount * KcalsPerKilojule).rounded(toPlaces: 0), unit: unit)
        } else {
            value = amount.roundedNutrientAmount
//            return FoodLabelValue(amount: amount.roundedNutrientAmount, unit: unit)
        }
        return FoodLabelValue(amount: value, unit: unit)
    }
    
    func calculateAmount(for attribute: Attribute, in index: Int) -> Double? {
        // print("2️⃣ Calculate \(attribute) in column \(index)")
//        guard allRows.containsAllMacrosAndEnergy else {
//            return nil
//        }
        
        switch attribute {
        case .carbohydrate:
            guard let fat = amountFor(.fat, at: index),
                  let protein = amountFor(.protein, at: index),
                  let energy = energyInKcal(at: index) else {
                return nil
            }
            return (energy - (protein * KcalsPerGramOfProtein) - (fat * KcalsPerGramOfFat)) / KcalsPerGramOfCarb
            
        case .fat:
            guard let carb = amountFor(.carbohydrate, at: index),
                  let protein = amountFor(.protein, at: index),
                  let energy = energyInKcal(at: index) else {
                return nil
            }
            return (energy - (protein * KcalsPerGramOfProtein) - (carb * KcalsPerGramOfCarb)) / KcalsPerGramOfFat
            
        case .protein:
            guard let fat = amountFor(.fat, at: index),
                  let carb = amountFor(.carbohydrate, at: index),
                  let energy = energyInKcal(at: index) else {
                return nil
            }
            return (energy - (carb * KcalsPerGramOfCarb) - (fat * KcalsPerGramOfFat)) / KcalsPerGramOfProtein

        case .energy:
            guard let fat = amountFor(.fat, at: index),
                  let carb = amountFor(.carbohydrate, at: index),
                  let protein = amountFor(.protein, at: index) else {
                return nil
            }
            return (carb * KcalsPerGramOfCarb) + (fat * KcalsPerGramOfFat) + (protein * KcalsPerGramOfProtein)

        default:
            return nil
        }
    }

    mutating func fixSingleInvalidMacroOrEnergyRow() {
        if macrosValidities.count == 1 {
            fixSingleInvalidMacroOrEnergyRowForOneValue()
        } else {
            fixSingleInvalidMacroOrEnergyRowForTwoValues()
        }
    }

    mutating func replaceNilMacroAndChildrenValuesIfZero() {
        guard let missingAttribute = allRows.missingMacroAttribute,
              let energyValue = row(for: .energy)?.firstValue,
              let missingRow = row(for: missingAttribute),
              missingRow.value1 == nil,
              missingRow.value2 == nil
        else {
            return
        }
        
        var energy = energyValue.amount
        if energyValue.unit == .kj {
            energy = EnergyUnit.kJ.convert(energy, to: .kcal)
//            energy = energy / KcalsPerKilojule
        }

        let isValid: Bool
        switch missingAttribute {
        case .carbohydrate:
            guard let fat = row(for: .fat)?.firstValue?.amount,
                  let protein = row(for: .protein)?.firstValue?.amount else {
                return
            }
            isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: 0, fat: fat, protein: protein)
        case .fat:
            guard let carb = row(for: .carbohydrate)?.firstValue?.amount,
                  let protein = row(for: .protein)?.firstValue?.amount else {
                return
            }
            isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: carb, fat: 0, protein: protein)
        case .protein:
            guard let carb = row(for: .carbohydrate)?.firstValue?.amount,
                  let fat = row(for: .fat)?.firstValue?.amount else {
                return
            }
            isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: carb, fat: fat, protein: 0)
        default:
            isValid = false
        }
        
        guard isValid else { return }
        
        let zeroValue = FoodLabelValue(amount: 0, unit: .g)
        modify(missingRow, withNewValues: (zeroValue, zeroValue))
        
        for childAttribute in missingAttribute.childrenAttributes {
            if let childRow = row(for: childAttribute),
               childRow.value1 == nil,
               childRow.value2 == nil {
                modify(childRow, withNewValues: (zeroValue, zeroValue))
            }
        }
    }

    mutating func fixSingleInvalidMacroOrEnergyRowForOneValue() {
        guard macrosValidities.first == false,
              allRows.containsAllMacrosAndEnergy,
              let macroAndEnergyRows = allMacroAndEnergyRows,
              let energyValue = row(for: .energy)?.firstValue,
              let carb = row(for: .carbohydrate)?.firstValue?.amount,
              let fat = row(for: .fat)?.firstValue?.amount,
              let protein = row(for: .protein)?.firstValue?.amount
        else {
            return
        }
        
        var energy = energyValue.amount
        if energyValue.unit == .kj {
            energy = EnergyUnit.kJ.convert(energy, to: .kcal)
//            energy = energy / KcalsPerKilojule
        }

        //TODO: We might be able to improve this (albeit expensively) by going through all combinations of alternate values for each of the macro and energy rows to find one that works—in which case we would need to modify all the rows that require picking an alternate
        /// For each macro and energy row
        for row in macroAndEnergyRows {
            guard let valuesText = row.valuesTexts.first, let valuesText = valuesText else {
                continue
            }
            
            let attribute = row.attributeText.attribute
            
            for value in valuesText.alternateValues {
                
                var amount = value.amount
                if attribute == .energy, value.unit == .kj {
                    amount = EnergyUnit.kJ.convert(amount, to: .kcal)
//                    amount = amount / KcalsPerKilojule
                }
                
                let isValid: Bool
                switch attribute {
                case .energy:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: amount, carb: carb, fat: fat, protein: protein)
                case .carbohydrate:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: amount, fat: fat, protein: protein)
                case .fat:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: carb, fat: amount, protein: protein)
                case .protein:
                    isValid = macroAndEnergyValuesAreValid(energyInKcal: energy, carb: carb, fat: fat, protein: amount)
                default:
                    isValid = false
                }
                if isValid {
                    modify(row, withNewValue: value)
                    return
                }
            }
        }
        
   }

    mutating func fixSingleInvalidMacroOrEnergyRowForTwoValues() {
        let start = CFAbsoluteTimeGetCurrent()
        /// Check `macrosValidities` to see if we have two values where one is true
        /// Then check the validity of rows to determine if we have only one of the 3 variables that's invalid
        guard macrosValidities.onlyOneOfTwoIsTrue,
              allRows.containsAllMacrosAndEnergy,
              invalidMacroAndEnergyRows.count == 1,
              let invalidRow = invalidMacroAndEnergyRows.first
        else {
            return
        }
        
        let attribute = invalidRow.attributeText.attribute
        
        if (macrosValidities[0] == true && macrosValidities[1] != true) {
            guard let validValue = allRows.valueFor(attribute, valueIndex: 0) else {
                // print("2️⃣ ⚠️ Error getting valid value for: \(attribute) in column 1")
                return
            }
            guard let calculatedValue = calculateValue(for: attribute, in: 1) else {
                // print("2️⃣ ⚠️ Error getting calculated value for: \(attribute) in column 1")
                return
            }
            modify(invalidRow, withNewValues: (validValue, calculatedValue))
        }
        else if (macrosValidities[0] != true && macrosValidities[1] == true) {
            guard let validValue = allRows.valueFor(attribute, valueIndex: 1) else {
                // print("2️⃣ ⚠️ Error getting valid value for: \(attribute) in column 2")
                return
            }
            guard let calculatedValue = calculateValue(for: attribute, in: 0) else {
                // print("2️⃣ ⚠️ Error getting calculated value for: \(attribute) in column 2")
                return
            }
            modify(invalidRow, withNewValues: (calculatedValue, validValue))
        }
        // print("took: \(CFAbsoluteTimeGetCurrent()-start)s")
        // print("We here")
        /// If that's the case, then use the equation to determine that value and fill it in
    }
    
    /// Remove all rows that are empty (containing all nil values)
    mutating func removeEmptyValues() {
        for row in emptyRows {
            remove(row)
        }
    }
    
    mutating func removeValuesOutsideColumnRects() {
        for column in columns {
            for row in column.rows {
                if row.containsValueOutside(column.columnRects) {
                    modify(row, with: row.withoutValuesOutsideColumnRects(column.columnRects))
                }
            }
        }
    }
    
    mutating func findSingleEnergyValueIfMissing(in textSet: RecognizedTextSet) {
        guard numberOfValues == 1,
              let row = row(for: .energy),
              row.valuesTexts[0] == nil,
              let energyValuesText = findNextEnergyValuesText(nextTo: row.attributeText.text, in: textSet),
              let energyValue = energyValuesText.values.first
        else {
            return
        }
        
        /// Only continue If we have all the macro rows and the value fits within the error range of the calculate value
        guard let calculatedEnergy = calculateAmount(for: .energy, in: 0) else {
            return
        }
        
        var energyInCalories = calculatedEnergy
        let isKj = energyValue.unit == .kj || (energyValue.unit == nil && !row.attributeText.text.string.matchesRegex("calories"))
        var valuesTextWithUnit = energyValuesText
        if isKj {
            energyInCalories = energyInCalories * 4.184
        } else {
            valuesTextWithUnit.values = [FoodLabelValue(amount: energyValue.amount, unit: .kcal)]
        }
        let errorPercentage = (abs(energyValue.amount - energyInCalories) / energyInCalories) * 100.0
        guard errorPercentage <= ErrorPercentageThresholdEnergyCalculation else {
            return
        }
        
        let newRow = ExtractedRow(attributeText: row.attributeText, valuesTexts: [valuesTextWithUnit])
        modify(row, with: newRow)
    }
    
    func findNextEnergyValuesText(nextTo text: RecognizedText, in textSet: RecognizedTextSet) -> ValuesText? {
        guard let nextText = textSet.texts.textsOnSameRow(as: text, preceding: false, includeSearchText: false, allowsOverlap: true).first,
              let nextValue = FoodLabelValue.detect(in: nextText.string).first,
              (nextValue.hasEnergyUnit || nextValue.unit == nil)
        else {
            return nil
        }
        return ValuesText(nextText)
    }
    
    mutating func removeExtraneousValues() {
        for row in allRows {
            if row.containsExtraneousValues {
                modify(row, with: row.withoutExtraneousValues)
            }
        }
    }
    
    mutating func fixInvalidRows() {
        guard let validRatio = validRatio else {
            return
        }
        let invalidRows = invalidRows(using: validRatio)
        for row in invalidRows {
            correct(row, for: validRatio)
        }
    }
    
    mutating func fixInvalidChildRows() {
        for row in invalidChildRows {
            correctChildRow(row)
        }
    }
    
    var greaterValueIndex: Int? {
        guard let row = validRows.first,
              row.valuesTexts.count == 2,
              let value1 = row.valuesTexts[0]?.values.first,
              let value2 = row.valuesTexts[1]?.values.first
        else {
            return nil
        }
        return value1.amount > value2.amount ? 0 : 1
    }
    
    var validRows: [ExtractedRow] {
        allRows.filter { row in
            !invalidRows.contains(where: { invalidRow in
                invalidRow.attributeText.attribute == row.attributeText.attribute
            })
        }
    }

    mutating func fixInvalidRowsContainingLessThanPrefix() {
        guard let validRatio = validRatio, let greaterValueIndex = greaterValueIndex else {
            return
        }
        let invalidRowsWithLessThanPrefix = invalidRows(using: validRatio, containingLessThanPrefix: true)
        for row in invalidRowsWithLessThanPrefix {
            correctRowContainingLessThanPrefix(row, for: validRatio, usingGreaterValueIndex: greaterValueIndex)
        }
    }

    mutating func correctRowContainingLessThanPrefix(_ row: ExtractedRow, for validRatio: Double, usingGreaterValueIndex greaterValueIndex: Int) {
        guard let value1 = row.valuesTexts[0]?.values.first, let value2 = row.valuesTexts[1]?.values.first else {
            return
        }

        if greaterValueIndex == 0 {
            let amount = (value1.amount / validRatio).roundedNutrientAmount
            modify(row, withNewValues: (value1, FoodLabelValue(amount: amount, unit: value1.unit)))
        }
        else if greaterValueIndex == 1 {
            let amount = (value1.amount * validRatio).roundedNutrientAmount
            modify(row, withNewValues: (FoodLabelValue(amount: amount, unit: value2.unit), value2))
        }
    }
    
    mutating func correctChildRow(_ childRow: ExtractedRow) {
        guard let parentAttribute = childRow.attributeText.attribute.parentAttribute,
            let parentRow = row(for: parentAttribute) else {
            return
        }
        
        var validValue1: FoodLabelValue? = nil
        var validValue2: FoodLabelValue? = nil
        
        if let parentValue = parentRow.value1,
           let childValue = childRow.value1,
           let childAmount = childValue.amountInGramsIfWithUnit,
           let parentAmount = parentValue.amountInGramsIfWithUnit,
           childAmount > parentAmount,
           let alternateValue1s = childRow.valuesTexts[0]?.alternateValues
        {
            for altValue in alternateValue1s {
                guard let altAmount = altValue.amountInGramsIfWithUnit else {
                    continue
                }
                if altAmount <= parentAmount {
                    validValue1 = altValue
                    break
                }
            }
        }
        
        if let parentValue = parentRow.value2,
           let childValue = childRow.value2,
           let childAmount = childValue.amountInGramsIfWithUnit,
           let parentAmount = parentValue.amountInGramsIfWithUnit,
           childAmount > parentAmount,
           let alternateValues = childRow.valuesTexts[1]?.alternateValues
        {
            for altValue in alternateValues {
                guard let altAmount = altValue.amountInGramsIfWithUnit else {
                    continue
                }
                if altAmount <= parentAmount {
                    validValue2 = altValue
                    break
                }
            }
        }
        
        var newRow = childRow
        var valuesTexts = childRow.valuesTexts
        if let validValue1 = validValue1 {
            var valuesText = valuesTexts[0]
            valuesText?.values = [validValue1]
            valuesTexts[0] = valuesText
        }
        if let validValue2 = validValue2 {
            var valuesText = valuesTexts[1]
            valuesText?.values = [validValue2]
            valuesTexts[1] = valuesText
        }
        newRow.valuesTexts = valuesTexts
        modify(childRow, with: newRow)
    }
    
    mutating func correct(_ row: ExtractedRow, for validRatio: Double) {
        guard row.attributeText.attribute != .energy else {
            //TODO: instead of this, provide all rows to correctionMadeUsingAlternativeValues so that alternative energy values may also be selected as long as they also fit in the equation (within the error threshold)
            return
        }

        // print("3️⃣ Correcting: \(row.desc)")

        guard !correctionMadeUsingAlternativeValues(row, for: validRatio) else {
            // print("3️⃣ Correction was made using alternative values for: \(row.desc)")
            return
        }
        
        //TODO: Write this when needed
        guard !correctionMadeUsingParentNutrientHeuristics(row, for: validRatio) else {
            // print("3️⃣ Correction was made using parent nutrient heuristics for: \(row.desc)")
            return
        }
        
        // print("3️⃣ We weren't able to correct: \(row.desc)")
    }

    mutating func correctionMadeUsingParentNutrientHeuristics(_ row: ExtractedRow, for validRatio: Double) -> Bool {
        //TODO: Bring this in when needed—but keep in mind that this will make previous cases fail  where we have values taken directly from nutrition labels that don't actually have correctly scaled values
        return false
    }

    mutating func correctionMadeUsingAlternativeValues(_ row: ExtractedRow, for validRatio: Double) -> Bool {
        guard row.valuesTexts.count == 2 else {
            return false
        }
        /// Try and use the alternative text candidates to see if one satisfies the ratio requirement (of being within an error margin of it)
        guard let valuesText1 = row.valuesTexts[0], let valuesText2 = row.valuesTexts[1],
              let value1 = valuesText1.values.first, let value2 = valuesText2.values.first
        else {
            return false
        }
        
        let currentRatio = value1.amount/value2.amount
        
        var closestAltValue1: FoodLabelValue? = nil
        var closestAltValue2: FoodLabelValue? = nil
        
        for c1 in valuesText1.alternateStrings {
            for c2 in valuesText2.alternateStrings {
                
                guard let altValue1 = FoodLabelValue.detectSingleValue(in: c1),
                      let altValue2 = FoodLabelValue.detectSingleValue(in: c2),
                      altValue2.amount != 0 else {
                    continue
                }

                let ratio = altValue1.amount/altValue2.amount
                
                /// If it satisfies the threshold, return this immediately
                if ratio.errorPercentage(with: validRatio) <= RatioErrorPercentageThreshold {
                    modify(row, withNewValues: (altValue1, altValue2))
                    return true
                }
                
                
                /// Otherwise, if the ratio is closer to the valid ratio than the current one (and substantailly different from it—to account for cases where `0.07/0.01 == 6.999999999999` and `0.7/0.1 = 7.000000000001`
                guard abs(ratio - validRatio) < abs(currentRatio - validRatio),
                      abs(ratio - currentRatio) > 0.01
                else {
                    continue
                }
                
                /// Keep storing the closest alt values to return once we've run through all of them
                if let closest1 = closestAltValue1, let closest2 = closestAltValue2 {
                    let closestRatio = closest1.amount/closest2.amount
                    if abs(ratio - validRatio) < abs(closestRatio - validRatio) {
                        closestAltValue1 = altValue1
                        closestAltValue2 = altValue2
                    }
                } else {
                    closestAltValue1 = altValue1
                    closestAltValue2 = altValue2
                }
            }
        }
        
        if let closestAltValue1 = closestAltValue1, let closestAltValue2 = closestAltValue2 {
            modify(row, withNewValues: (closestAltValue1, closestAltValue2))
            return true
        } else {
            return false
        }
//        return false
    }

    
    var allRows: [ExtractedRow] {
        columns.map { $0.rows }.reduce([], +)
    }
    
    var invalidRows: [ExtractedRow] {
        guard let validRatio = validRatio else {
            return []
        }
        return invalidRows(using: validRatio)
    }
    
    var rowsWithOneMissingValue: [ExtractedRow] {
        allRows.filter { $0.hasOneMissingValue }
    }
    
    var allMacroAndEnergyRows: [ExtractedRow]? {
        guard allRows.containsAllMacrosAndEnergy else { return nil }
        return allRows.filter { $0.attributeText.attribute.isEnergyOrMacro }
    }

    var allMacroRows: [ExtractedRow]? {
        guard allRows.containsAllMacros else { return nil }
        return allRows.filter { $0.attributeText.attribute.isMacro }
    }

    var invalidMacroAndEnergyRows: [ExtractedRow] {
        invalidRows(threshold: MacroOrEnergyErrorPercentageThreshold)
            .filter { $0.attributeText.attribute.isEnergyOrMacro }
            .filter { $0.ratioColumn1To2 != 0 }
            .filter { $0.valuesTexts.count == 2 && $0.valuesTexts[1]?.values.first?.amount != 0 }
    }
    
    var emptyRows: [ExtractedRow] {
        allRows.filter { $0.hasNilValues }
    }
    
    var invalidChildRows: [ExtractedRow] {
        allRows.filter {
            guard let parentAttribute = $0.attributeText.attribute.parentAttribute,
                  let parentRow = allRows.row(for: parentAttribute)
            else {
                return false
            }
            
            return !$0.isValidChild(of: parentRow)
        }
    }
    
    func invalidRows(using validRatio: Double? = nil, threshold: Double = RatioErrorPercentageThreshold, containingLessThanPrefix: Bool = false) -> [ExtractedRow] {
        guard let validRatio = validRatio ?? self.validRatio else {
            return []
        }
        
        return allRows.filter {
            /// Do not consider rows with completely nil or zero values as invalid
            guard !$0.hasNilValues, !$0.hasZeroValues else {
                return false
            }
            
            if containingLessThanPrefix {
                guard $0.valuesTextsContainLessThanPrefix else {
                    return false
                }
            }
                    
            /// Consider anything else without a ratio as invalid (implying that one side is `nil`)
            guard let ratio = $0.ratioColumn1To2 else {
                return true
            }
            
            /// Consider a row invalid if its ratio has a difference from the validRatio greater than the error threshold
            let errorPercentage = ratio.errorPercentage(with: validRatio)
            return errorPercentage > threshold
        }
    }
    
    /**
     Determine this by either:
     -[X]  Getting the modal value in the array of ratios (rounded to 1 decimal place), and then getting the average of all the actual ratios
     -[ ]  Using the header texts if that's not available or using the header texts in the array to find the ratio
     */
    var validRatio: Double? {
        guard let mode = allRatiosOfColumn1To2.modalAverage(consideringNumberOfPlaces: 1) else {
            return allRatiosOfColumn1To2.modalAverage(consideringNumberOfPlaces: 0)
        }
        return mode
    }
    
    var allRatiosOfColumn1To2: [Double] {
        columns.map { $0.rows.compactMap { $0.ratioColumn1To2 } }.reduce([], +)
    }

    var macrosValidities: [Bool?] {
        var validities: [Bool?] = []
        
        var rows: [ExtractedRow] = []
        for column in columns {
            rows.append(contentsOf: column.rows.filter({
                $0.attributeText.attribute.isEnergyOrMacro
            }))
        }
        guard rows.containsAllMacrosAndEnergy else {
            return Array(repeating: nil, count: numberOfValues)
        }
        
        /// Now that we've confirmed that all macros and energy rows are present
        for i in  0..<numberOfValues {
            guard let energy = rows.valueFor(.energy, valueIndex: i),
                  let carb = rows.valueFor(.carbohydrate, valueIndex: i),
                  let fat = rows.valueFor(.fat, valueIndex: i),
                  let protein = rows.valueFor(.protein, valueIndex: i) else {
                validities.append(nil)
                continue
            }

            //TODO: Use macroAndEnergyValuesAreValid(energyInKcal: Double, carb: Double, fat: Double, protein: Double) instead, after running tests
            //TODO: Replace coefficients with precise values from constants such as KcalsPerGramOfFat
            //TODO: Use the constant we have for 4.184 (KcalsPerKilojule) making sure we've named in correctly while we're at it—should'nt it be KjPerKcal
            var calculatedEnergy = (carb.amount * 4) + (protein.amount * 4) + (fat.amount * 9)
            if energy.unit == .kj || energy.unit == nil {
                calculatedEnergy = calculatedEnergy * 4.184
            }
            let errorPercentage = (abs(energy.amount - calculatedEnergy) / calculatedEnergy) * 100.0
            if errorPercentage <= ErrorPercentageThresholdEnergyCalculation {
                validities.append(true)
            } else {
                validities.append(false)
            }
        }
        
        return validities
    }

}

extension ValuesText {
    /// For the first value only
    var alternateStrings: [String] {
        guard let value = values.first else { return [] }
        if let altValueWithDecimalPlace = value.amount.insertingDecimalPlaceBetweenTwoDigitNumber {
            return text.candidates + [altValueWithDecimalPlace.clean]
        } else {
            return text.candidates
        }
    }
}

extension Double {
    var insertingDecimalPlaceBetweenTwoDigitNumber: Double? {
        guard self < 100, isInteger else { return nil }
        var string = "\(Int(self))"
        string.insert(".", at: string.index(string.startIndex, offsetBy: 1))
        return Double(string)
    }
    
    var isInteger: Bool {
        floor(self) == self
    }
}

extension Array where Element == ExtractedRow {
    
    func valueFor(_ attribute: Attribute, valueIndex: Int) -> FoodLabelValue? {
//        first(where: { $0.attributeText.attribute == attribute })?.valuesTexts[valueIndex]?.values.first
        guard let valueTexts = first(where: { $0.attributeText.attribute == attribute })?.valuesTexts,
              valueIndex < valueTexts.count else {
            return nil
        }
        return valueTexts[valueIndex]?.values.first
    }
    
    var containsAllMacrosAndEnergy: Bool {
        filter({ $0.attributeText.attribute.isEnergyOrMacro }).count == 4
    }
    
    var containsAllMacros: Bool {
        filter { $0.attributeText.attribute.isMacro }.count == 3
    }
}

extension Attribute {
    var isMacro: Bool {
        self == .carbohydrate
        || self == .fat
        || self == .protein
    }
    
    var isEnergyOrMacro: Bool {
        self == .energy
        || isMacro
    }
}

extension Double {
    func errorPercentage(with double: Double) -> Double {
        let difference = abs(self - double)
        return (difference/self) * 100.0
    }
    
    var roundedNutrientAmount: Double {
        if self < 0.02 {
            return self.rounded(toPlaces: 3)
        } else {
            return self.rounded(toPlaces: 2)
        }
    }
}

extension CGFloat {
    var roundedNutrientAmount: CGFloat {
        Double(self).roundedNutrientAmount
    }
}

extension Array where Element == Double {

    func modalAverage(consideringNumberOfPlaces places: Int) -> Double? {
        
        /// For each value in array
        /// Get value rounded off to `places` places
        var dict: [Double: [Double]] = [:]
        for double in self {
            let rounded = double.rounded(toPlaces: places)
            guard let array = dict[rounded] else {
                dict[rounded] = [double]
                continue
            }
            dict[rounded] = array + [double]
        }
        
        var modes: [(roundedValue: Double, values: [Double])] = []
        for (rounded, values) in dict {
            /// If we don't already have a mode, add this
            guard let count = modes.first?.values.count else {
                modes = [(rounded, values)]
                continue
            }
            /// Ignore any set of values that appears less than any of the modes we have so far
            guard values.count >= count else {
                continue
            }
            
            if values.count > count {
                /// If this pair of values exceeds in frequency as the current mode(s), replace them
                modes = [(rounded, values)]
            } else {
                /// If not, that means it equals in frequency, so add this to the array
                modes.append((rounded, values))
            }
        }
        
        /// Make sure we have exactly one mode before returning it
        guard modes.count == 1, let mode = modes.first else {
            return nil
        }
        
        return mode.values.average
    }
}

extension Array where Element: BinaryInteger {

    /// The average value of all the items in the array
    var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}

extension Array where Element: BinaryFloatingPoint {

    /// The average value of all the items in the array
    var average: Double {
        if self.isEmpty {
            return 0.0
        } else {
            let sum = self.reduce(0, +)
            return Double(sum) / Double(self.count)
        }
    }

}

extension ExtractedGrid {

    var observations: [Observation] {
        var observations: [Observation] = []
        for column in columns {
            for row in column.rows {
                observations.append(row.observation)
            }
        }
        return observations
    }
}

/// Make this global
func macroAndEnergyValuesAreValid(energyInKcal: Double, carb: Double, fat: Double, protein: Double, threshold: Double = ErrorPercentageThresholdEnergyCalculation) -> Bool {
    let calculatedEnergy = (carb * KcalsPerGramOfCarb) + (protein * KcalsPerGramOfProtein) + (fat * KcalsPerGramOfFat)
    let errorPercentage = (abs(energyInKcal - calculatedEnergy) / calculatedEnergy) * 100.0
    return errorPercentage <= threshold
}
