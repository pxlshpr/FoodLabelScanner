import Foundation

struct Observation {
    var attributeText: AttributeText
    var valueText1: ValueText?
    var valueText2: ValueText?
    var doubleText: DoubleText?
    var stringText: StringText?
    
    var attribute: Attribute { attributeText.attribute }
    var value1: Value? { valueText1?.value }
    var value2: Value? { valueText2?.value }
    var double: Double? { doubleText?.double }
    var string: String? { stringText?.string }
}

extension Observation {
    init?(attributeText: AttributeText, servingArtefact: ServingArtefact) {
        guard attributeText.attribute.supportsServingArtefact(servingArtefact) else {
            return nil
        }
        self.attributeText = attributeText
        self.valueText1 = nil
        self.valueText2 = nil
        if let unit = servingArtefact.unit {
            self.stringText = StringText(
                string: unit.description,
                text: servingArtefact.text,
                attributeText: attributeText.text
            )
        } else if let string = servingArtefact.string {
            self.stringText = StringText(
                string: string.cleanedUnitString,
                text: servingArtefact.text,
                attributeText: attributeText.text
            )
        } else {
            self.stringText = nil
        }
        if let double = servingArtefact.double {
            self.doubleText = DoubleText(
                double: double,
                text: servingArtefact.text,
                attributeText: attributeText.text
            )
        } else {
            self.doubleText = nil
        }
    }
}

extension Observation: CustomStringConvertible {
    var description: String {
        let suffix: String
        if value1 != nil || value2 != nil {
            suffix = "\(value1?.description ?? "") • \(value2?.description ?? "")"
        } else if let double = double {
            suffix = "#\(double)"
        } else if let string = string {
            suffix = string
        } else {
            suffix = "(nil)"
        }
        return ".\(attribute.rawValue): \(suffix)"
    }
}
