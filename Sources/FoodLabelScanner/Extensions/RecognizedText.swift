import VisionSugar
import Foundation

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
}
