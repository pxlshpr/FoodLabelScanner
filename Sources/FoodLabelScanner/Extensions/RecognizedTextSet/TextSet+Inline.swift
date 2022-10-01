import VisionSugar
import Foundation

extension RecognizedTextSet {
    var inlineObservations: [Observation] {
        var observations: [Observation] = []
        for text in texts {
            
            if let nutrient = text.string.nutrients.first {
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
}
