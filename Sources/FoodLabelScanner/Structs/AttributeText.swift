import SwiftUI
import VisionSugar

import PrepShared

public struct AttributeText: Codable {
    public let attribute: Attribute
    public let text: RecognizedText
    public var allTexts: [RecognizedText]
    
    init(attribute: Attribute, text: RecognizedText, allTexts: [RecognizedText] = []) {
        self.attribute = attribute
        self.text = text
        self.allTexts = allTexts
    }
    
    var allTextsRect: CGRect {
        guard let first = allTexts.first else { return .zero }
        var unionRect = first.rect
        for text in allTexts.dropFirst() {
            unionRect = unionRect.union(text.rect)
        }
        return unionRect
    }
    
    func yDistanceTo(valuesText: ValuesText) -> CGFloat {
        abs(valuesText.text.rect.midY - allTextsRect.midY)
    }
}

extension AttributeText: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(attribute)
        hasher.combine(text)
        hasher.combine(allTexts)
    }
}
