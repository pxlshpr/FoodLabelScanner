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
