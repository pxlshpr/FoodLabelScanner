import Foundation
import VisionSugar
import PrepDataTypes

public struct ServingArtefact {
    public let text: RecognizedText
    public let attribute: Attribute?
    public let double: Double?
    public let string: String?
    public let unit: FoodLabelUnit?
    
    init(attribute: Attribute, text: RecognizedText) {
        self.text = text
        self.attribute = attribute
        self.double = nil
        self.string = nil
        self.unit = nil
    }
    
    init(double: Double, text: RecognizedText) {
        self.text = text
        self.double = double
        self.attribute = nil
        self.string = nil
        self.unit = nil
    }
    
    init(string: String, text: RecognizedText) {
        self.text = text
        self.string = string
        self.double = nil
        self.attribute = nil
        self.unit = nil
    }
    
    init(unit: FoodLabelUnit, text: RecognizedText) {
        self.text = text
        self.unit = unit
        self.string = nil
        self.double = nil
        self.attribute = nil
    }
}

extension ServingArtefact: Equatable {
    public static func ==(lhs: ServingArtefact, rhs: ServingArtefact) -> Bool {
        lhs.text == rhs.text
        && lhs.attribute == rhs.attribute
        && lhs.double == rhs.double
        && lhs.string == rhs.string
        && lhs.unit == rhs.unit
    }
}

extension ServingArtefact: CustomStringConvertible {
    public var description: String {
        if let attribute = attribute {
            return ".\(attribute.rawValue)"
        }
        if let double = double {
            return "#\(double.clean)"
        }
        if let string = string {
            return "\(string)"
        }
        if let unit = unit {
            return ".\(unit.description)"
        }
        return "nil"
    }
}
