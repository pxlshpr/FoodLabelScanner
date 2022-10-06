import Foundation
import PrepUnits

extension Observation {
    var unitText: UnitText? {
        guard let stringText,
              let unit = FoodLabelUnit(string: stringText.string)
        else {
            return nil
        }
        return UnitText(unit: unit,
                        text: stringText.text,
                        attributeText: stringText.attributeText)
    }
}

/// Serving helpers
extension Array where Element == Observation {
    var servingAmount: DoubleText? {
        observation(for: .servingAmount)?.doubleText
    }
    
    var servingUnit: UnitText? {
        observation(for: .servingUnit)?.unitText
    }
    
    var servingUnitName: StringText? {
        observation(for: .servingUnitSize)?.stringText
    }
    
    var servingEquivalentAmount: DoubleText? {
        observation(for: .servingEquivalentAmount)?.doubleText
    }
    
    var servingEquivalentUnit: UnitText? {
        observation(for: .servingEquivalentUnit)?.unitText
    }
    
    var servingEquivalentUnitName: StringText? {
        observation(for: .servingEquivalentUnitSize)?.stringText
    }
    
    var servingEquivalentSize: ScanResult.Serving.EquivalentSize? {
        guard let servingEquivalentAmount else { return nil }
        return ScanResult.Serving.EquivalentSize(
            amountText: servingEquivalentAmount,
            unitText: servingEquivalentUnit,
            unitNameText: servingEquivalentUnitName
        )
    }
    
    var servingPerContainerAmount: DoubleText? {
        observation(for: .servingsPerContainerAmount)?.doubleText
    }
    
    var servingPerContainerName: StringText? {
        observation(for: .servingsPerContainerName)?.stringText
    }
    
    var servingPerContainer: ScanResult.Serving.PerContainer? {
        guard let servingPerContainerAmount else { return nil }
        return ScanResult.Serving.PerContainer(
            amountText: servingPerContainerAmount,
            nameText: servingPerContainerName
        )
    }
}

extension Array where Element == Observation {
   
    var serving: ScanResult.Serving? {
        ScanResult.Serving(
            amountText: servingAmount,
            unitText: servingUnit,
            unitNameText: servingUnitName,
            equivalentSize: servingEquivalentSize,
            perContainer: servingPerContainer
        )
    }
    
    var nutrients: ScanResult.Nutrients {
        ScanResult.Nutrients(
            headerText1: headerText1,
            headerText2: headerText2,
            rows: rows
        )
    }
    
    var headerText1: HeaderText? {
        nil
    }
    
    var headerText2: HeaderText? {
        nil
    }
    
    var rows: [ScanResult.Nutrients.Row] {
        nutrientObservations.map {
            ScanResult.Nutrients.Row(
                attributeText: $0.attributeText,
                valueText1: $0.valueText1,
                valueText2: $0.valueText2
            )
        }
    }
    
    //MARK: - Helpers
    
    var nutrientObservations: [Observation] {
        filter { $0.attributeText.attribute.isNutrientAttribute }
    }
}

extension Array where Element == Observation {
    func observation(for attribute: Attribute) -> Observation? {
        first(where: { $0.attribute == attribute })
    }
    
    func amount(in column: Int, for attribute: Attribute) -> Double? {
        value(in: column, for: attribute)?.amount
    }
    func value(in column: Int, for attribute: Attribute) -> FoodLabelValue? {
        if column == 1 {
            return value1(for: attribute)
        } else {
            return value2(for: attribute)
        }
    }
    
    func value1(for attribute: Attribute) -> FoodLabelValue? {
        observation(for: attribute)?.value1
    }

    func value2(for attribute: Attribute) -> FoodLabelValue? {
        observation(for: attribute)?.value2
    }
}
