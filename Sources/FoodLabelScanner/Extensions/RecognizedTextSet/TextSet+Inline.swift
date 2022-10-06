import VisionSugar
import Foundation

extension RecognizedTextSet {
    var inlineObservations: [Observation] {
        var observations: [Observation] = []
        for text in texts {
            
            /// First get all the nutrients for each of the candidates
            let candidateNutrients = text.candidates.compactMap { $0.nutrients.first }
            
            if let nutrient = candidateNutrients.bestCandidate {
                observations.append(nutrient.observation(forInlineText: text))
                continue
            }
            
            guard let attribute = Attribute.detect(in: text.string).first, attribute.isNutrientAttribute else {
                continue
            }

            let inlineTextsColumns = texts.inlineTextColumns(as: text, allowOverlapping: true)
            guard !inlineTextsColumns.isEmpty, let value = inlineTextsColumns.firstValue else {
                continue
            }
            
            let attributeText = AttributeText(attribute: attribute, text: text)
            let valueText = ValueText(value: value.0, text: value.1, attributeText: text)
            let observation = Observation(attributeText: attributeText, valueText1: valueText)
            observations.append(observation)
        }
        return observations
    }
    
    var inlineResult: ScanResult {
        let observations = inlineObservations
        return ScanResult(
            serving: observations.serving,
            nutrients: observations.nutrients,
            texts: texts
        )
    }
}

extension Array where Element == Nutrient {
    /**
     Returns the best candidate from an array of possible candidates for a text.
     
     For instance—if we have ["60", "6g"] for the attribute of "Saturated Fat"—we'll pick "6g" over "60" because it
        - has a unit that is compatible with that attribute
    */
    var bestCandidate: Nutrient? {
        for candidate in self {
            if let unit = candidate.value.unit, candidate.attribute.supportsUnit(unit) {
                return candidate
            }
        }
        /// If we didn't find any with compatible units—simply return the first element in this array
        return first
    }
}
