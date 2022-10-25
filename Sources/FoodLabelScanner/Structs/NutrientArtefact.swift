import Foundation
import PrepDataTypes

//TODO: Legacy Artefact
public struct NutrientArtefact {
    let textId: UUID
    let attribute: Attribute?
    let value: FoodLabelValue?
    let preposition: Preposition?
    
    init(attribute: Attribute, textId: UUID) {
        self.textId = textId
        self.attribute = attribute
        self.value = nil
        self.preposition = nil
    }
    
    init(value: FoodLabelValue, textId: UUID) {
        self.textId = textId
        self.value = value
        self.attribute = nil
        self.preposition = nil
    }
    
    init(preposition: Preposition, textId: UUID) {
        self.textId = textId
        self.preposition = preposition
        self.value = nil
        self.attribute = nil
    }
}

extension NutrientArtefact: Equatable {
    public static func ==(lhs: NutrientArtefact, rhs: NutrientArtefact) -> Bool {
        lhs.textId == rhs.textId
        && lhs.attribute == rhs.attribute
        && lhs.value == rhs.value
        && lhs.preposition == rhs.preposition
    }
}

extension NutrientArtefact: CustomStringConvertible {
    public var description: String {
        if let value = value {
            return value.description
        }
        if let attribute = attribute {
            return attribute.rawValue
        }
        if let preposition = preposition {
            return preposition.rawValue
        }
        return "nil"
    }
}
