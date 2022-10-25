import Foundation
import PrepDataTypes

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
    var headers: ScanResult.Headers? {
        ScanResult.Headers(
            headerText1: headerText1,
            headerText2: headerText2
        )
    }
    
    var headerStringText1: StringText? {
        observation(for: .headerType1)?.stringText
    }

    var headerStringText2: StringText? {
        observation(for: .headerType2)?.stringText
    }

    var headerType1: HeaderType? {
        guard let stringText = headerStringText1 else { return nil }
        return HeaderType(rawValue: stringText.string)
    }
    
    var headerType2: HeaderType? {
        guard let stringText = headerStringText2 else { return nil }
        return HeaderType(rawValue: stringText.string)
    }
    
    var headerServingAmount: Double? {
        observation(for: .headerServingAmount)?.double
    }

    var headerServingUnit: FoodLabelUnit? {
        observation(for: .headerServingUnit)?.unitText?.unit
    }

    var headerServingUnitName: String? {
        observation(for: .headerServingUnitSize)?.string
    }
    
    var headerServingEquivalentAmount: Double? {
        observation(for: .headerServingEquivalentAmount)?.double
    }
    var headerServingEquivalentUnit: FoodLabelUnit? {
        observation(for: .headerServingEquivalentUnit)?.unitText?.unit
    }
    var headerServingEquivalentUnitName: String? {
        observation(for: .headerServingEquivalentUnitSize)?.string
    }
    
    var headerServingEquivalentSize: HeaderText.Serving.EquivalentSize? {
        guard let headerServingEquivalentAmount else { return nil }
        return HeaderText.Serving.EquivalentSize(
            amount: headerServingEquivalentAmount,
            unit: headerServingEquivalentUnit,
            unitName: headerServingEquivalentUnitName
        )
    }

    var headerServing: HeaderText.Serving? {
        guard (
            headerServingAmount != nil
            || headerServingUnit != nil
            || headerServingUnitName != nil
            || headerServingEquivalentSize != nil
        ) else {
            return nil
        }
        return HeaderText.Serving(
            amount: headerServingAmount,
            unit: headerServingUnit,
            unitName: headerServingUnitName,
            equivalentSize: headerServingEquivalentSize
        )
    }
    
    var headerText1: HeaderText? {
        guard let headerStringText1, let headerType1 else { return nil }
        let serving = headerType1 == .perServing ? headerServing : nil
        return HeaderText(
            type: headerType1,
            text: headerStringText1.text,
            attributeText: headerStringText1.attributeText,
            serving: serving
        )
    }
    
    var headerText2: HeaderText? {
        guard let headerStringText2, let headerType2 else { return nil }
        let serving = headerType2 == .perServing ? headerServing : nil
        return HeaderText(
            type: headerType2,
            text: headerStringText2.text,
            attributeText: headerStringText2.attributeText,
            serving: serving
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
            rows: rows
        )
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
