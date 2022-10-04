import Foundation
import PrepUnits

extension DoubleText {
    public init(_ valueText: ValueText) {
        self.double = valueText.value.amount
        self.text = valueText.text
        self.attributeText = valueText.text
    }
    public init(_ doubleText: DoubleText) {
        self.double = doubleText.double
        self.text = doubleText.text
        self.attributeText = doubleText.text
    }
}

extension UnitText {
    public init?(_ valueText: ValueText) {
        guard let unit = valueText.value.unit else {
            return nil
        }
        self.unit = unit
        self.text = valueText.text
        self.attributeText = valueText.text
    }
    public init?(_ stringText: StringText) {
        guard let unit = FoodLabelUnit(string: stringText.string) else {
            return nil
        }
        self.unit = unit
        self.text = stringText.text
        self.attributeText = stringText.text
    }
}

public extension ScanResult {
    var containsServingAttributes: Bool {
        guard let serving = serving else { return false }
        return serving.amount != nil
        || serving.unit != nil
        || serving.unitName != nil
        || serving.equivalentSize != nil
        || serving.perContainer != nil
    }
    
    func containsAttribute(_ attribute: Attribute) -> Bool {
        switch attribute {
        case .tableElementNutritionFacts:
            return false
        case .servingAmount:
            return serving?.amount != nil
        case .servingUnit:
            return serving?.unit != nil
        case .servingUnitSize:
            return serving?.unitName != nil
        case .servingEquivalentAmount:
            return serving?.equivalentSize != nil
        case .servingEquivalentUnit:
            return serving?.equivalentSize?.unit != nil
        case .servingEquivalentUnitSize:
            return serving?.equivalentSize?.unitName != nil
        case .servingsPerContainerAmount:
            return serving?.perContainer != nil
        case .servingsPerContainerName:
            return serving?.perContainer?.name != nil
        case .headerType1:
            return nutrients.headerText1 != nil
        case .headerType2:
            return nutrients.headerText2 != nil
        default:
            return nutrients.rows.contains(where: { $0.attribute == attribute })
        }
    }
}
