import SwiftUI
import VisionSugar
import PrepShared

extension ValuesText {
    var containsLessThanPrefix: Bool {
        text.string.lowercased().contains("less than")
    }
}
struct ExtractedRow {
    let attributeText: AttributeText
    var valuesTexts: [ValuesText?]
    
    var firstValue: FoodLabelValue? {
        valuesTexts.first??.values.first
    }
    
    var ratioColumn1To2: Double? {
        guard valuesTexts.count == 2,
              let valuesText1 = valuesTexts[0],
              let valuesText2 = valuesTexts[1],
              !valuesText1.containsLessThanPrefix,
              !valuesText2.containsLessThanPrefix,
              let amount1 = valuesText1.values.first?.amount,
              let amount2 = valuesText2.values.first?.amount,
              amount2 != 0
        else {
            return nil
        }
        return amount1/amount2
    }
    
    var valuesTextsContainLessThanPrefix: Bool {
        guard valuesTexts.count == 2,
              let valuesText1 = valuesTexts[0],
              let valuesText2 = valuesTexts[1]
        else {
            return false
        }
        return valuesText1.containsLessThanPrefix || valuesText2.containsLessThanPrefix
    }
    
    var hasNilValues: Bool {
        valuesTexts.allSatisfy({ $0 == nil })
    }
    
    var hasOneMissingValue: Bool {
        singleMissingValueIndex != nil
    }
    
    var hasMismatchedUnits: Bool {
        guard let value1 = value1, let value2 = value2 else {
            return false
        }
        return value1.unit != value2.unit
    }
    
    var value1: FoodLabelValue? {
        guard valuesTexts.count > 0 else { return nil }
        return valuesTexts[0]?.values.first
    }
    var value2: FoodLabelValue? {
        guard valuesTexts.count > 1 else { return nil }
        return valuesTexts[1]?.values.first
    }

    var singleMissingValueIndex: Int? {
        guard valuesTexts.count == 2 else { return nil }
        if valuesTexts[0] != nil && valuesTexts[1] == nil {
            return 1
        }
        if valuesTexts[1] != nil && valuesTexts[0] == nil {
            return 0
        }
        return nil
    }
    
    var hasZeroValues: Bool {
        valuesTexts.allSatisfy({ $0?.values.first?.amount == 0 })
    }
    
    func isValidChild(of parentRow: ExtractedRow) -> Bool {
        if let amount = value1?.amountInGramsIfWithUnit, let parentAmount = parentRow.value1?.amountInGramsIfWithUnit {
            guard amount <= parentAmount else {
                return false
            }
        }
        
        if let amount = value2?.amountInGramsIfWithUnit, let parentAmount = parentRow.value2?.amountInGramsIfWithUnit {
            guard amount <= parentAmount else {
                return false
            }
        }
        
        return true
    }
}

extension FoodLabelValue {
    var amountInGramsIfWithUnit: Double? {
        switch unit {
        case .mcg:
            return amount * 0.000001
        case .mg:
            return amount * 0.001
        case .g:
            return amount
        default:
            return amount
        }
    }
}

extension Array where Element == ExtractedRow {
    var missingMacroOrEnergyAttribute: Attribute? {
        if let missingMacroAttribute = missingMacroAttribute {
            return missingMacroAttribute
        }
        if !containsRowWithValues(for: .energy),
           containsRowWithValues(for: .carbohydrate),
           containsRowWithValues(for: .fat),
           containsRowWithValues(for: .protein) {
            return .energy
        }
        return nil
    }
    
    var missingMacroAttribute: Attribute? {
        guard containsRowWithValues(for: .energy) else {
            return nil
        }
        if containsRowWithValues(for: .carbohydrate),
           containsRowWithValues(for: .fat),
           !containsRowWithValues(for: .protein) {
            return .protein
        }
        if !containsRowWithValues(for: .carbohydrate),
           containsRowWithValues(for: .fat),
           containsRowWithValues(for: .protein) {
            return .carbohydrate
        }
        if containsRowWithValues(for: .carbohydrate),
           !containsRowWithValues(for: .fat),
           containsRowWithValues(for: .protein) {
            return .fat
        }
        return nil
    }
    
    func containsRowWithValues(for attribute: Attribute) -> Bool {
        contains(where: {
            $0.attributeText.attribute == attribute
            && $0.valuesTexts.contains { valuesText in valuesText != nil }
        })
    }
    
    func row(for attribute: Attribute) -> ExtractedRow? {
        first(where: { $0.attributeText.attribute == attribute })
    }
}

extension ExtractedRow {
    var observation: Observation {
        let valueText1 = valuesTexts.count > 0 ? valuesTexts[0]?.valueText : nil
        let valueText2 = valuesTexts.count > 1 ? valuesTexts[1]?.valueText : nil
        return Observation(attributeText: attributeText,
                    valueText1: valueText1,
                    valueText2: valueText2)
    }
}

extension ValuesText {
    var valueText: ValueText? {
        guard let firstValue = values.first else { return nil }
        return ValueText(value: firstValue, text: text)
    }
}
