import Foundation

import PrepShared
import VisionSugar

public extension ScanResult {
    
    func extractedNutrientsForColumn(
        _ column: Int,
        includeSingleColumnValues singles: Bool = false,
        ignoring attributesToIgnore: [Attribute]
    ) -> [ExtractedNutrient] {
        var extractedNutrients: [ExtractedNutrient] = nutrients.rows.compactMap({ row in
            
            guard !attributesToIgnore.contains(row.attribute) else {
                print("⛏ Ignoring \(row.attribute.description) since we've already extracted it")
                return nil
            }
            
            var value: FoodLabelValue? = nil
            let valueText: RecognizedText?
            /// If the column doesn't have a value, pick the opposite one if it exists,
            /// so that we're always returning nutrients with a value in 1 column
            if column == 1 {
                value = row.value1 ?? (singles ? row.value2 : nil)
                valueText = row.valueText1?.text ?? (singles ? row.valueText2?.text : nil)
            } else {
                value = row.value2 ?? (singles ? row.value1 : nil)
                valueText = row.valueText2?.text ?? (singles ? row.valueText1?.text : nil)
            }
            
            value?.correctUnit(for: row.attribute)
            return ExtractedNutrient(
                attribute: row.attribute,
                attributeText: row.attributeText.text,
                isConfirmed: false,
                value: value,
                valueText: valueText
            )
        })
        
        /// Remove any value-less attributes that lie outside the bounding box of nutrients
        let boundingBox = nutrientsBoundingBox(includeAttributes: true)
        extractedNutrients = extractedNutrients.filter { extractedNutrient in
            guard extractedNutrient.valueText == nil,
                  let attributeText = extractedNutrient.attributeText
            else { return true }
            return boundingBox.contains(attributeText.boundingBox)
        }
        
        /// Sort everything by ascending `minY` of their attribute's text
        extractedNutrients.sort {
            guard let rect1 = $0.attributeText?.rect, let rect2 = $1.attributeText?.rect else {
                return false
            }
            return rect1.minY < rect2.minY
        }
        
        /// Ensure that energy is always at the top
        let energy: ExtractedNutrient
        if let energyIndex = extractedNutrients.firstIndex(where: { $0.attribute == .energy }) {
            energy = extractedNutrients.remove(at: energyIndex)
        } else {
            energy = ExtractedNutrient(attribute: .energy)
        }
        if !attributesToIgnore.contains(.energy) {
            extractedNutrients.insert(energy, at: 0)
        }
        
        /// Add any missing macros (to ensure they're all always present)
        for macro in Macro.allCases {
            guard !extractedNutrients.contains(where: { $0.attribute.macro == macro }) else {
                continue
            }
            if !attributesToIgnore.contains(macro.attribute) {
                extractedNutrients.append(.init(attribute: macro.attribute))
            }
        }

        return extractedNutrients
    }
}
