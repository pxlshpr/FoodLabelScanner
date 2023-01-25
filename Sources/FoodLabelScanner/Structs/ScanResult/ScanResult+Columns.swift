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

public extension ScanResult {
    var headerTitle1_legacy: String {
        guard let headerType = headers?.header1Type else { return "Column 1" }
        return headerType.description.replacingFirstOccurrence(of: "Per ", with: "")
    }
    var headerTitle2_legacy: String {
        guard let headerType = headers?.header2Type else { return "Column 2" }
        return headerType.description.replacingFirstOccurrence(of: "Per ", with: "")
    }
    
    var headerTitle1: String {
        guard let headerType = headers?.header1Type else { return "Column 1" }
        return headerType.description
    }
    var headerTitle2: String {
        guard let headerType = headers?.header2Type else { return "Column 2" }
        return headerType.description
    }
}
