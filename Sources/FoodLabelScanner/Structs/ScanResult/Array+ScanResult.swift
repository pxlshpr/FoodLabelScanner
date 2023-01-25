import SwiftSugar
import PrepDataTypes

public extension ScanResult {
    
    func containsValue(for attribute: Attribute, at column: Int) -> Bool {
        nutrients.rows.contains { row in
            row.attribute == attribute
            && ( column == 1 ? row.value1 != nil : row.value2 != nil )
        }
    }
    
    var bestColumn: Int {
        columnWithTheMostNutrients ?? columnWithLargerValues
    }
    
    var columnWithLargerValues: Int {
        var isLargerCount1 = 0
        var isLargerCount2 = 0
        for row in nutrients.rows {
            guard let value1 = row.value1, let value2 = row.value2 else {
                continue
            }
            if value1.amount > value2.amount { isLargerCount1 += 1 }
            if value2.amount > value1.amount { isLargerCount2 += 1 }
        }
        return isLargerCount1 > isLargerCount2 ? 1 : 2
    }

    /**
     Returns the column number with the most number of non-nil nutrients.
     
     Remember that the column numbers aren't 0-based, so they start at 1.
     Returns `nil` if they are both equal.
     */
    var columnWithTheMostNutrients: Int? {
        let count1 = nutrientsCount(column: 1)
        let count2 = nutrientsCount(column: 2)
        guard count1 != count2 else { return nil }
        return count1 > count2 ? 1 : 2
    }
    
    /**
     Returns the number of non-nil nutrients in the column specified.
     
     Remember that the column numbers aren't 0-based, so they start at 1.
     */
    func nutrientsCount(column: Int) -> Int {
        nutrients.rows.filter({
            column == 1 ? $0.value1 != nil : $0.value2 != nil
        }).count
    }
    
    /**
     Returns true if the header types between both match (when present).
     
     Empty headers don't disqualify a ScanResult set for compatibility.
     */
    func hasCompatibleHeadersWith(_ other: ScanResult) -> Bool {
        hasCompatibleHeader1With(other)
        && hasCompatibleHeader2With(other)
    }
    
    /**
     Only returns `false` if we have both headers and they don't match.
     
     Will return `true` if either or both sides are empty.
     */
    func hasCompatibleHeader1With(_ other: ScanResult) -> Bool {
        guard let header1Type = headers?.header1Type,
              let otherHeader1Type = other.headers?.header1Type
        else {
            return true
        }
        return header1Type == otherHeader1Type
    }

    /**
     Only returns `false` if we have both headers and they don't match.
     
     Will return `true` if either or both sides are empty.
     */
    func hasCompatibleHeader2With(_ other: ScanResult) -> Bool {
        guard let header2Type = headers?.header2Type,
              let otherHeader2Type = other.headers?.header2Type
        else {
            return true
        }
        return header2Type == otherHeader2Type
    }

    /**
     Returns the number of nutrients in this `ScanResult`.
     
     Only rows with at least one value are counted.
     */
    var nutrientCount: Int {
        nutrients.rows.filter({ $0.value1 != nil || $0.value2 != nil }).count
    }
    
    /// Returns true if tabular—which is determined by any of the nutrient rows having a non-nil `value2`
    var isTabular: Bool {
        self.nutrients.rows.contains(where: { $0.value2 != nil })
    }
    
    var columnCount: Int {
        if isTabular { return 2 }
        if nutrientCount > 0 { return 1 }
        return 0
//        isTabular ? 2 : 1
    }
}
