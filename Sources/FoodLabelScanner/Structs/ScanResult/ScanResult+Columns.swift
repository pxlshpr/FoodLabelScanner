import Foundation
import VisionSugar

public extension ScanResult {

    func columnsTexts(includeAttributes: Bool = false) -> [RecognizedText] {
        var texts: [RecognizedText] = []
        texts = headerTexts
        for nutrient in nutrients.rows {
            if includeAttributes {
                texts.append(nutrient.attributeText.text)
            }
            if let text = nutrient.valueText1?.text {
                texts.append(text)
            }
            if let text = nutrient.valueText2?.text {
                texts.append(text)
            }
        }
        return texts
    }

    var columnsBoundingBox: CGRect {
        columnsTexts()
            .filter { $0.id != defaultUUID }
            .boundingBox
    }
    
    var columnsWithAttributesBoundingBox: CGRect {
        columnsTexts(includeAttributes: true)
            .filter { $0.id != defaultUUID }
            .boundingBox
    }
}
