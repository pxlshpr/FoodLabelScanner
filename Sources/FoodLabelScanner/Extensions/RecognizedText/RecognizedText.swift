import VisionSugar
import Foundation
import PrepShared

extension RecognizedText {
    var isValueBasedAttribute: Bool {
        attribute?.isValueBased ?? false
    }
    
    var attribute: Attribute? {
        for classifierClass in Attribute.allCases {
            guard let regex = classifierClass.regex else { continue }
            if string.matchesRegex(regex) {
                return classifierClass
            }
        }
        return nil
    }
    
    var containsValue: Bool {
        string.matchesRegex(#"[0-9]+[.,]*[0-9]*[ ]*(mg|ug|g|kj|kcal)"#)
    }
    
    var containsPercentage: Bool {
        string.matchesRegex(#"[0-9]+[.,]*[0-9]*[ ]*%"#)
    }
    
    var containsEnergyValue: Bool {
        
        let values = FoodLabelValue.detect(in: self.string)
        return values.contains(where: { $0.hasEnergyUnit })
    }
    
    var containsServingAttribute: Bool {
        servingArtefacts.contains(where: {
            guard let attribute = $0.attribute else {
                return false
            }
            return attribute.isServingAttribute
        })
    }

    var containsHeaderAttribute: Bool {
//        //TODO: Make this more general purpose
//        /// This is currently only targeting the header strings in `21AB8151-540A-41A9-BAB2-8674FD3A46E7`, as its not needed by any other case—but make this more general purpose after adding all test cases to make sure that previous ones pass.
//        var headerStrings = [
//            "Per Serving Per 100 ml",
//            "Par Portion Pour 100 ml",
//        ]
//        return headerStrings.contains(string)
        
        return string.containsHeaderAttribute
    }
}

extension String {
    var containsHeaderAttribute: Bool {
        let regexes = [
            "per 100[ ]?ml",
            "pour 100[ ]?ml",
            "per 100[ ]?g"
        ]
        for regex in regexes {
            if matchesRegex(regex) {
                return true
            }
        }
        return false
    }
}
