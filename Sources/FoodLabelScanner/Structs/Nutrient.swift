import Foundation
import VisionSugar
import PrepDataTypes

struct Nutrient: Equatable {
    let attribute: Attribute
    let value: FoodLabelValue
}

extension String {
    var containsInlineNutrients: Bool {
        !nutrients.isEmpty
    }
    
    var nutrients: [Nutrient] {
        
        var nutrients: [Nutrient] = []
        var setAsideAttribute: Attribute? = nil
        var setAsideValue: FoodLabelValue? = nil
        var saveNextValue: Bool = false
        let artefacts = self.nutrientArtefacts(textId: defaultUUID)
        
        func appendNutrientWith(attribute: Attribute, value: FoodLabelValue) {
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
//            // print("Nutrients for '\(self)': \(nutrients.description)")
//        }
        
        return nutrients
    }
}

extension String {
    func nutrientArtefacts(textId id: UUID) -> [NutrientArtefact] {
        
        /// Ignore strings like `Calories from fat 70`
//        let stringsToIgnorePattern = #"calorie(|s) from"#
//        guard !matchesRegex(stringsToIgnorePattern) else {
//            return []
//        }
        
        var array: [NutrientArtefact] = []
        var string = self
        
        var isExpectingCalories: Bool = false
        
        //TODO: Use regex for these, also include ones with simple "o"
        func suffixReplace(_ incorrects: [String], with correct: String) {
            for incorrect in incorrects {
                if string.hasSuffix(incorrect) {
                    string = string.replacingLastOccurrence(of: incorrect, with: correct)
                    break
                }
            }
        }
        suffixReplace(["Og", "O g"], with: "0g")
        suffixReplace(["O%", "O %"], with: "0%")
        suffixReplace(["Omg", "O mg"], with: "0mg")
        suffixReplace(["Omcg", "O mcg"], with: "0mcg")

        
        func replace(_ incorrects: [String], with correct: String) {
            for incorrect in incorrects {
                if string == incorrect {
                    string = correct
                    break
                }
            }
        }
        replace(["O", "o"], with: "0")
        replace(["O a", "o a"], with: "0g")
        
        func occurrenceReplace(_ incorrects: [String], with correct: String) {
            for incorrect in incorrects {
                string = string.replacingOccurrences(of: incorrect, with: correct)
            }
        }
        occurrenceReplace([" O ", " o "], with: " 0 ")
        occurrenceReplace([" O% ", " o% ", " O % ", " o % "], with: " 0% ")
        occurrenceReplace([" Omg ", " O mg ", " omg ", " o mg "], with: "0mg")
        occurrenceReplace([" Omcg ", " O mcg ", " omcg ", " o mcg "], with: "0mcg")

        /// We're using this as a safeguard against infinite recursion—in case for whatever reason, the artefact
        /// extraction halts and the string stops getting modified resulting in an endless loop.
        ///
        /// This happened in an instance where we had `03-A` returning `03 A` for `valueSubstringAtStart`
        /// which was what was used in `replacingFirstOccurence(of:with:)`, which obviously never
        /// changed the string, resulting in an infinite loop that eventually crashed.
        ///
        /// That issue has been mitigated (see below) but we're also adding this ceiling for how many times
        /// this loop can run to avoid any similar unknown issues causing the infinite recursion.
        ///
        /// A number of `100` is chosen as a reasonable max because:
        /// - We're making sure we're not prematurely cutting off any normal strings from having their artefacts extracted.
        ///     (since we'd usually expect 5-10 extracts per string to be the max)
        /// - We're not encountering much overhead, and this max is only reached in the rare case that a bug is encountered.
        ///
        let MaxLoopCount = 100
        var loopCount = 0
        
        while string.count > 0, loopCount < MaxLoopCount {
            loopCount += 1

            print("loopCount: \(loopCount)")

            /// First check if we have a value at the start of the string
            if let valueSubstring = string.valueSubstringAtStart,
               /// If we do, extract it from the string and add its corresponding `Value` to the array
                var value = FoodLabelValue(fromString: valueSubstring) {
                
                /// **Heuristic** for detecting when energy is detected with the phrase "Calories", in which case we manually assign the `kcal` unit to the `Value` matched later.
                if isExpectingCalories {
                    if value.unit == nil {
                        value.unit = .kcal
                    }
                    /// Reset this once a value has been read after the energy attribute
                    isExpectingCalories = false
                }
                
                
                let beforeReplacing = string
                string = string.replacingFirstOccurrence(of: valueSubstring, with: "").trimmingWhitespaces
                
                if string == beforeReplacing {
                    /// This fixes an infinite recursion bug we had due to `valueSubstringAtStart` not always returning
                    /// the exact string that was extracted when we replace dashes. So `03-A` would be returned as `03 A`
                    /// which wouldn't get detected in the string, which causes an infinite recursion.
                    /// So we're putting in this check which replaces any whitespaces (which would be internal, since we're
                    /// trimming them in `valueSubstringAtStart`), with dashes, to try and match the previous string.
                    /// We've also got another safeguard against the infinite recursion at the while loop which caps this loop at
                    /// running no more than x times.
                    let valueSubstringWithDashes = valueSubstring.replacingSpacesWithDashes
//                    string = string.replacingFirstOccurrence(of: valueSubstringWithDashes, with: "")
                }
                
                
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

extension Nutrient {
    func observation(forInlineText text: RecognizedText) -> Observation {
        let attributeText = AttributeText(attribute: attribute, text: text)
        let valueText = ValueText(value: value, text: text)
        return Observation(attributeText: attributeText, valueText1: valueText)
    }
}

