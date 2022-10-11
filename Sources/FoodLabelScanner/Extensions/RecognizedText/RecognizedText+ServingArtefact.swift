import VisionSugar
import Foundation
import PrepUnits

extension RecognizedText {
    public var servingArtefacts: [ServingArtefact] {
        getServingArtefacts()
    }
    
    public func getServingArtefacts() -> [ServingArtefact] {
        var arrays: [[ServingArtefact]] = []
        for candidate in candidates {
            arrays.append(servingArtefacts(for: candidate))
        }
        
        /// Run heuristics if needed to select a candidate when we have multiple candidates of the recognized text
        
        /// Default is to always return the first array if none of the heuristics picked another candidate
        return arrays.first(where: { $0.count > 0 }) ?? []
    }
    
    public func servingArtefacts(for string: String) -> [ServingArtefact] {
//        let originalString = string.cleanedAttributeString
        var array: [ServingArtefact] = []
        var string = string.cleanedAttributeString
        while string.count > 0 {
            /// First check if we have a number at the start of the string
            if let numberSubstring = string.numberSubstringAtStart,
               let double = Double(fromString: numberSubstring)
            {
                string = string.replacingFirstOccurrence(of: numberSubstring, with: "").trimmingWhitespaces

                let artefact = ServingArtefact(double: double, text: self)
                array.append(artefact)
            }
            /// Otherwise if we have a unit at the start of the string
            else if let unitSubstring = string.unitSubstringAtStart,
                    let unit = FoodLabelUnit(string: unitSubstring)
            {
                string = string.replacingFirstOccurrence(of: unitSubstring, with: "").trimmingWhitespaces
                
                let artefact = ServingArtefact(unit: unit, text: self)
                array.append(artefact)
            }
            /// Finally get the next substring up to the first numeral
            else if let substring = string.substringUpToFirstNumeral
            {
                /// If it matches an attribute, create an artefact from it
//                if let attributeSubstring = string.servingAttributeSubstringAtStart,
//                   let attribute = Attribute(fromString: attributeSubstring)
                if let attribute = Attribute(fromString: substring)
                {
                    /// Save this for the heuristic later on
                    let previousArtefact = array.last
                    let previousIndex = array.count - 1
                    
                    if attribute == .servingsPerContainerAmount {
                        /// **Heuristic** If this is the `.servingsPerContainerAmount`, also try and grab the `.servingsPerContainerName` from the substring, and add that as an artefact before proceeding
                        if let containerName = string.servingsPerContainerName {
                            array.append(ServingArtefact(attribute: .servingsPerContainerName, text: self))
                            array.append(ServingArtefact(string: containerName, text: self))
                        }
                     
//                        /// If we have a double as the previous artefact, add it as the serving amount and stop searching for it
//                        if let double = previousArtefact?.double {
//
//                        }
//                        let previous = previousArtefact
                    }

                    let artefact = ServingArtefact(attribute: attribute, text: self)
                    
                    /// If this was the `.servingsPerContainerAmount` attribute,
                    ///     and we have a unit-less value before it
                    /// —use that as the amount by inserting the attribute artefact before it
                    /// —otherwise append it here in hopes that we extract it further down the line.
                    if attribute == .servingsPerContainerAmount,
                       let previousArtefact = previousArtefact,
                       previousArtefact.double != nil,
                       previousIndex >= 0
                    {
                        array.insert(artefact, at: previousIndex)
                    } else {
                        array.append(artefact)
                    }
                    
                    
//                    string = string.replacingFirstOccurrence(of: attributeSubstring, with: "").trimmingWhitespaces
                    string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
                }
                /// Otherwise, if the substring contains letters, add it as a string attribute
                else if substring.containsWords
                {
                    let artefact = ServingArtefact(string: substring, text: self)
                    array.append(artefact)
                    string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
                }
                /// Finally, we'll be ignoring any joining symbols
                else {
                    string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
                }
            } else {
                break
            }
        }
        
        /// ** Heuristic ** When we have someting like `Per Pot 116 calories`, fail the extraction by returning an empty array
        for index in array.indices {
            let artefact = array[index]
            /// If we've hit the `.servingsPerContainerAmount`, check if the artefact after the next one (which would be the actual amount `Value`) is an energy unit
            let indexAfterNext = index + 2
            if artefact.attribute == .servingsPerContainerAmount,
               indexAfterNext < array.count,
               (array[indexAfterNext].unit == .kcal || array[indexAfterNext].unit ==  .kj)
            {
                return []
            }
        }
        
        return array
    }
}

extension String {
    
    public var servingArtefacts: [ServingArtefact] {
//        let originalString = string.cleanedAttributeString
        var array: [ServingArtefact] = []
        var string = cleanedAttributeString
        while string.count > 0 {
            /// First check if we have a number at the start of the string
            if let numberSubstring = numberSubstringAtStart,
               let double = Double(fromString: numberSubstring)
            {
                string = string.replacingFirstOccurrence(of: numberSubstring, with: "").trimmingWhitespaces

                let artefact = ServingArtefact(double: double, text: defaultText)
                array.append(artefact)
            }
            /// Otherwise if we have a unit at the start of the string
            else if let unitSubstring = string.unitSubstringAtStart,
                    let unit = FoodLabelUnit(string: unitSubstring)
            {
                string = string.replacingFirstOccurrence(of: unitSubstring, with: "").trimmingWhitespaces
                
                let artefact = ServingArtefact(unit: unit, text: defaultText)
                array.append(artefact)
            }
            /// Finally get the next substring up to the first numeral
            else if let substring = string.substringUpToFirstNumeral
            {
                /// If it matches an attribute, create an artefact from it
//                if let attributeSubstring = string.servingAttributeSubstringAtStart,
//                   let attribute = Attribute(fromString: attributeSubstring)
                if let attribute = Attribute(fromString: substring)
                {
                    /// Save this for the heuristic later on
                    let previousArtefact = array.last
                    let previousIndex = array.count - 1
                    
                    if attribute == .servingsPerContainerAmount {
                        /// **Heuristic** If this is the `.servingsPerContainerAmount`, also try and grab the `.servingsPerContainerName` from the substring, and add that as an artefact before proceeding
                        if let containerName = string.servingsPerContainerName {
                            array.append(ServingArtefact(attribute: .servingsPerContainerName, text: defaultText))
                            array.append(ServingArtefact(string: containerName, text: defaultText))
                        }
                     
//                        /// If we have a double as the previous artefact, add it as the serving amount and stop searching for it
//                        if let double = previousArtefact?.double {
//
//                        }
//                        let previous = previousArtefact
                    }

                    let artefact = ServingArtefact(attribute: attribute, text: defaultText)
                    
                    /// If this was the `.servingsPerContainerAmount` attribute,
                    ///     and we have a unit-less value before it
                    /// —use that as the amount by inserting the attribute artefact before it
                    /// —otherwise append it here in hopes that we extract it further down the line.
                    if attribute == .servingsPerContainerAmount,
                       let previousArtefact = previousArtefact,
                       previousArtefact.double != nil,
                       previousIndex >= 0
                    {
                        array.insert(artefact, at: previousIndex)
                    } else {
                        array.append(artefact)
                    }
                    
                    
//                    string = string.replacingFirstOccurrence(of: attributeSubstring, with: "").trimmingWhitespaces
                    string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
                }
                /// Otherwise, if the substring contains letters, add it as a string attribute
                else if substring.containsWords
                {
                    let artefact = ServingArtefact(string: substring, text: defaultText)
                    array.append(artefact)
                    string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
                }
                /// Finally, we'll be ignoring any joining symbols
                else {
                    string = string.replacingFirstOccurrence(of: substring, with: "").trimmingWhitespaces
                }
            } else {
                break
            }
        }
        
        /// ** Heuristic ** When we have someting like `Per Pot 116 calories`, fail the extraction by returning an empty array
        for index in array.indices {
            let artefact = array[index]
            /// If we've hit the `.servingsPerContainerAmount`, check if the artefact after the next one (which would be the actual amount `Value`) is an energy unit
            let indexAfterNext = index + 2
            if artefact.attribute == .servingsPerContainerAmount,
               indexAfterNext < array.count,
               (array[indexAfterNext].unit == .kcal || array[indexAfterNext].unit ==  .kj)
            {
                return []
            }
        }
        
        return array
    }
}
