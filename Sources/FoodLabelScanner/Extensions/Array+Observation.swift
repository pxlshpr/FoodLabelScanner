import Foundation
import PrepUnits

extension Array where Element == Observation {
   
    var serving: ScanResult.Serving? {
        nil
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
