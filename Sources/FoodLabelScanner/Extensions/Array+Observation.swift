import Foundation

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
    
    var isValid: Bool {
        
        let column1IsValid = columnIsValid(1)
        let column2IsValid = columnIsValid(2)
        return column1IsValid || column2IsValid
    }
    
    func columnIsValid(_ column: Int) -> Bool {
        guard let energyInKcal = value(in: column, for: .energy)?.energyAmountInCalories else {
            return false
        }
        guard let fat = amount(in: column, for: .fat) else {
            return false
        }
        guard let carb = amount(in: column, for: .carbohydrate) else {
            return false
        }
        guard let protein = amount(in: column, for: .protein) else {
            return false
        }
        
        //TODO: Play with threshold here
        let isValid = macroAndEnergyValuesAreValid(energyInKcal: energyInKcal, carb: carb, fat: fat, protein: protein)
        return isValid
    }
    
    func observation(for attribute: Attribute) -> Observation? {
        first(where: { $0.attribute == attribute })
    }
    
    func amount(in column: Int, for attribute: Attribute) -> Double? {
        value(in: column, for: attribute)?.amount
    }
    func value(in column: Int, for attribute: Attribute) -> Value? {
        if column == 1 {
            return value1(for: attribute)
        } else {
            return value2(for: attribute)
        }
    }
    
    func value1(for attribute: Attribute) -> Value? {
        observation(for: attribute)?.value1
    }

    func value2(for attribute: Attribute) -> Value? {
        observation(for: attribute)?.value2
    }
}
