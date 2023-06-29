import VisionSugar
import Foundation

import FoodDataTypes

extension RecognizedTextSet {
    var mostAreInline: Bool {
        var attributes: [Attribute] = []
        var inlineAttributes: [Attribute] = []
        
        /// Go through all recognized texts
        for text in texts {
            guard !text.string.isSkippableRecognizedText else {
                continue
            }
            /// Each time we detect a non-mineral, non-vitamin attribute for the first time—whether inline or not—add it to the `attributes` array
            let detectedAttributes = Attribute.detect(in: text.string)
            for detectedAttribute in detectedAttributes {
                /// Ignore non-nutrient attributes and energy (because it's usually not inline)
                guard detectedAttribute.isNutrientAttribute,
                      detectedAttribute.isCoreTableNutrient,
                      detectedAttribute != .energy
                else {
                    continue
                }
                
                if !attributes.contains(detectedAttribute) {
                    attributes.append(detectedAttribute)
                }
            }
            
            /// Each time we detect an inline version of an attribute, add it to the `inlineAttributes` array
            let nutrients = text.string.nutrients
            for nutrient in nutrients {
                guard nutrient.attribute != .energy,
                      nutrient.attribute.isCoreTableNutrient
                else {
                    continue
                }

                if !inlineAttributes.contains(nutrient.attribute) {
                    inlineAttributes.append(nutrient.attribute)
                }
            }
        }
        
        let ratio = Double(inlineAttributes.count) / Double(attributes.count)
        
        //TODO: Tweak this threshold
        // print("🧮 Ratio is: \(ratio)")
        return ratio >= 0.75
    }
    
    func texts(for attribute: Attribute) -> [RecognizedText] {
        var texts: [RecognizedText] = []
        for text in texts {
            let attributes = Attribute.detect(in: text.string)
            guard attributes.contains(.energy),
                  !texts.contains(where: { $0.string == text.string } )
            else {
                continue
            }
            texts.append(text)
        }
        return texts
    }
}


