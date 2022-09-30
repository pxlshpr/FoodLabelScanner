import Foundation
import VisionSugar

struct Nutrient {
    let attribute: Attribute
    let value: Value
}

extension String {
    var containsInlineNutrients: Bool {
        !nutrients.isEmpty
    }
    
    var nutrients: [Nutrient] {
        
        var nutrients: [Nutrient] = []
        var setAsideAttribute: Attribute? = nil
        var setAsideValue: Value? = nil
        var saveNextValue: Bool = false
        let artefacts = self.nutrientArtefacts(textId: defaultUUID)
        
        func appendNutrientWith(attribute: Attribute, value: Value) {
            nutrients.append(Nutrient(attribute: attribute, value: value))
            setAsideAttribute = nil
            setAsideValue = nil
        }

        for i in artefacts.indices {
            
            let artefact = artefacts[i]
            
            if artefact.isIncludesPreposition {
                saveNextValue = true
            }
            
            /// If we encounter an `Attribute`
            if let attribute = artefact.attribute, attribute.isNutrientAttribute {
                if let value = setAsideValue {
                    /// … and we have a `Value` set aside, add the `Nutrient`
                    appendNutrientWith(attribute: attribute, value: value)
                } else if attribute == .addedSugar,
                          artefact == artefacts.last,
                          i > 0,
                          let value = artefacts[i-1].value
                {
                    /// … (**Heuristic**) and this is the last artefact with the previous one being a value
                    appendNutrientWith(attribute: attribute, value: value)
                } else {
                    /// otherwise, set the `Attribute` aside
                    setAsideAttribute = attribute
                }
            }
            /// If we encounter a `Value`
            else if let value = artefact.value {
                if let attribute = setAsideAttribute {
                    /// … and have an `Attribute` set aside, add the `Nutrient`
                    appendNutrientWith(attribute: attribute, value: value)
                } else if saveNextValue {
                    /// … otherwise, if we've set the `saveNextValue` flag, set the `Value` aside and reset the flag
                    setAsideValue = value
                    saveNextValue = false
                }
            }
        }
        
//        if !nutrients.isEmpty {
//            print("Nutrients for '\(self)': \(nutrients.description)")
//        }
        
        return nutrients
    }
}

extension String {
    func nutrientArtefacts(textId id: UUID) -> [NutrientArtefact] {
        
        var array: [NutrientArtefact] = []
        var string = self
        
        var isExpectingCalories: Bool = false
        
        /// ** Heuristic ** if string is simply a capital O `O`, treat it as a 0
        if string == "O" {
            string = "0"
        }
        if string.hasSuffix("Omg") {
            string = string.replacingLastOccurrence(of: "Omg", with: "0mg")
        }
        if string.hasSuffix("Omcg") {
            string = string.replacingLastOccurrence(of: "Omcg", with: "0mcg")
        }
        
        while string.count > 0 {
            /// First check if we have a value at the start of the string
            if let valueSubstring = string.valueSubstringAtStart,
               /// If we do, extract it from the string and add its corresponding `Value` to the array
                var value = Value(fromString: valueSubstring) {
                
                /// **Heuristic** for detecting when energy is detected with the phrase "Calories", in which case we manually assign the `kcal` unit to the `Value` matched later.
                if isExpectingCalories {
                    if value.unit == nil {
                        value.unit = .kcal
                    }
                    /// Reset this once a value has been read after the energy attribute
                    isExpectingCalories = false
                }
                
                string = string.replacingFirstOccurrence(of: valueSubstring, with: "").trimmingWhitespaces
                
                let artefact = NutrientArtefact(value: value, textId: id)
                array.append(artefact)

            /// Otherwise, get the string component up to and including the next numeral
            } else if let substring = string.substringUpToFirstNumeral {
                
                /// Check if it matches any prepositions or attributes (currently picks prepositions over attributes for the entire substring)
                if let attribute = Attribute(fromString: substring) {
                    let artefact = NutrientArtefact(attribute: attribute, textId: id)
                    array.append(artefact)
                    
                    /// Reset this whenever a new attribute is reached
                    isExpectingCalories = false

                    /// **Heuristic** for detecting when energy is detected with the phrase "Calories", in which case we manually assign the `kcal` unit to the `Value` matched later.
                    if attribute == .energy && substring.matchesRegex(Attribute.Regex.calories) {
                        isExpectingCalories = true
                    }
                    
                } else  if let preposition = Preposition(fromString: substring) {
                    let artefact = NutrientArtefact(preposition: preposition, textId: id)
                    array.append(artefact)
                }
//                } else if let attribute = Attribute(fromString: substring) {
//                    let artefact = Artefact(attribute: attribute, textId: id)
//                    array.append(artefact)
//                }
                string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
            } else {
                break
            }
        }
        return array
    }
}

extension Nutrient: CustomStringConvertible {
    var description: String {
        "\(attribute.rawValue): \(value.description)"
    }
}

extension NutrientArtefact {
    var isIncludesPreposition: Bool {
        guard let preposition = preposition else {
            return false
        }
        return preposition == .includes
    }
}

let defaultUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
let defaultText = RecognizedText(id: defaultUUID, rectString: "", boundingBoxString: "", candidates: [])
