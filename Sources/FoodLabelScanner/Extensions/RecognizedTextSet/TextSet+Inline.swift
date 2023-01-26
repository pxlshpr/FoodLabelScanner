import VisionSugar
import Foundation
import OrderedCollections

extension RecognizedText {
    /// Goes through all the detected nutrients in each of the candidate strings—and uniquely adds them to an array in a dictionary storing them against their attributes.
    var nutrientCandidates: OrderedDictionary<Attribute, [Nutrient]> {
        let strings = self.candidates
//        var candidates: [Attribute: [Nutrient]] = [:]
        var candidates: OrderedDictionary<Attribute, [Nutrient]> = [:]

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

extension OrderedDictionary where Key == Attribute, Value == [Nutrient] {
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
                    guard !observations.contains(attribute: nutrient.attribute) else { continue }
                    observations.append(nutrient.observation(forInlineText: text))
                }
                continue
            }
            
            guard let attribute = Attribute.detect(in: text.string).first,
                  attribute.isNutrientAttribute,
                  !observations.contains(attribute: attribute)
            else {
                continue
            }

            let attributeText = AttributeText(attribute: attribute, text: text)

            let inlineTextsColumns = texts.inlineTextColumns(as: text, allowOverlapping: true)
            guard !inlineTextsColumns.isEmpty, let tuple = inlineTextsColumns.firstValue else {
                /// Add the `Attribute` even if we failed to get a value, so that it appears in the Extractor's UI
                observations.append(Observation(attributeText: attributeText))
                continue
            }
            
            let correctedValue = tuple.0.withCorrectUnit(for: attributeText)
            let valueText = ValueText(value: correctedValue, text: tuple.1, attributeText: text)
            let observation = Observation(attributeText: attributeText, valueText1: valueText)
            observations.append(observation)
        }
        return observations
    }    
}

import PrepDataTypes

extension FoodLabelValue {
    
    /// This is to mitigate the uncaptured error where sometimes a inline text of "Calories 150" will be set as `150 kJ`.
    /// This shouldn't be the case since it clearly says "Calories" and there's no `kJ` to be read anyway.
    ///
    /// Once we've discovered why this happens, and **we're sure** that this error doesn't occur without this, remove this heuristic.
    /// *What we're doing here* – We're basically checking the string of the attribute if this is energy, and if it contains "calor", we then
    /// force the value's unit to be `.kcal`
    ///
    /// **NOTE: We could capture this by logging instances where we detect this energy string
    /// with an incorrectly detected kJ unit**
    func withCorrectUnit(for attributeText: AttributeText) -> FoodLabelValue {
        if attributeText.text.string.lowercased().contains("calor") {
            return FoodLabelValue(amount: self.amount, unit: .kcal)
        }
        
        return self
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
