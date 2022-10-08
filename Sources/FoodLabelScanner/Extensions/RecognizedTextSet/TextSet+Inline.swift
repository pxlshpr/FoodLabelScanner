import VisionSugar
import Foundation

extension RecognizedText {
    /// Goes through all the detected nutrients in each of the candidate strings—and uniquely adds them to an array in a dictionary storing them against their attributes.
    var nutrientCandidates: [Attribute: [Nutrient]] {
        let strings = self.candidates
        var candidates: [Attribute: [Nutrient]] = [:]
        
        for string in strings {
            for nutrient in string.nutrients {
                var nutrients = candidates[nutrient.attribute] ?? []
                guard !nutrients.contains(nutrient) else { continue }
                nutrients.append(nutrient)
                candidates[nutrient.attribute] = nutrients
            }
        }
        return candidates
    }
}

extension Dictionary where Key == Attribute, Value == [Nutrient] {
    /// Returns an array of the best candidates from each set of nutrients (for each attribute)
    var bestCandidateNutrients: [Nutrient] {
        var candidates: [Nutrient] = []
        for key in keys {
            guard let candidate = self[key]?.bestCandidate else {
                continue
            }
            candidates.append(candidate)
        }
        return candidates
    }
}

extension RecognizedTextSet {
    var inlineObservations: [Observation] {
        var observations: [Observation] = []
        for text in texts {
            
            /// First get all the nutrients for each of the candidates
            let nutrientCandidates = text.nutrientCandidates.bestCandidateNutrients
            if !nutrientCandidates.isEmpty {
                for nutrient in nutrientCandidates {
                    observations.append(nutrient.observation(forInlineText: text))
                }
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
