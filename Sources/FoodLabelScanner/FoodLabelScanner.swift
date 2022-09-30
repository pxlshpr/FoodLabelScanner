import SwiftUI
import VisionSugar

public struct FoodLabelScanner {
    
    var image: UIImage
    var contentSize: CGSize
    
    public init(image: UIImage, contentSize: CGSize? = nil) {
        self.image = image
        self.contentSize = contentSize ?? image.size
    }
    
    public func scan() async throws -> ScanResult {
        let textSet = try await image.recognizedTextSet(for: .accurate, inContentSize: contentSize)
        
        let observations = textSet.inlineObservations
        return ScanResult(
            serving: observations.serving,
            nutrients: observations.nutrients,
            texts: ScanResult.Texts(accurate: textSet.texts, accurateWithoutLanguageCorrection: [], fast: [])
        )
    }
}

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
            let valueText = ValueText(value: value.0, text: value.1)
            let observation = Observation(attributeText: attributeText, valueText1: valueText)
            observations.append(observation)
        }
        return observations
    }
}

extension Array where Element == [RecognizedText] {
    var firstValue: (Value, RecognizedText)? {
        for column in self {
            for text in column {
                if let value = Value.detectSingleValue(in: text.string) {
                    return (value, text)
                }
            }
        }
        return nil
    }
}

extension Nutrient {
    func observation(forInlineText text: RecognizedText) -> Observation {
        let attributeText = AttributeText(attribute: attribute, text: text)
        let valueText = ValueText(value: value, text: text)
        return Observation(attributeText: attributeText, valueText1: valueText)
    }
}

extension Array where Element == Observation {
    func printDescription() {
        self.forEach { observation in
            print(observation.description)
        }
    }
}
