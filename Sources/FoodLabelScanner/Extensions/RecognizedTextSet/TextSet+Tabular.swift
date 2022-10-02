import Foundation
import VisionSugar

extension RecognizedTextSet {
    var tabularObservations: [Observation] {
        let attributes = columnsOfAttributes()
        let values = columnsOfValues(forAttributes: attributes)
        let grid = ExtractedGrid(attributes: attributes, values: values, textSet: self)
        return grid.observations
    }
    
    var tabularResult: ScanResult {
        let observations = tabularObservations
        return ScanResult(
            serving: observations.serving,
            nutrients: observations.nutrients,
            texts: texts
        )
    }
}

