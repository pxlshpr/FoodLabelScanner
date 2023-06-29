import Foundation

import VisionSugar
import FoodDataTypes

extension DoubleText {
    public init(_ valueText: ValueText) {
        self.double = valueText.value.amount
        self.text = valueText.text
        self.attributeText = valueText.text
    }
    public init(_ doubleText: DoubleText) {
        self.double = doubleText.double
        self.text = doubleText.text
        self.attributeText = doubleText.text
    }
}

extension UnitText {
    public init?(_ valueText: ValueText) {
        guard let unit = valueText.value.unit else {
            return nil
        }
        self.unit = unit
        self.text = valueText.text
        self.attributeText = valueText.text
    }
    public init?(_ stringText: StringText) {
        guard let unit = FoodLabelUnit(string: stringText.string) else {
            return nil
        }
        self.unit = unit
        self.text = stringText.text
        self.attributeText = stringText.text
    }
}

public extension ScanResult {
    var containsServingAttributes: Bool {
        guard let serving = serving else { return false }
        return serving.amount != nil
        || serving.unit != nil
        || serving.unitName != nil
        || serving.equivalentSize != nil
        || serving.perContainer != nil
    }
    
    func containsAttribute(_ attribute: Attribute) -> Bool {
        switch attribute {
        case .tableElementNutritionFacts:
            return false
        case .servingAmount:
            return serving?.amount != nil
        case .servingUnit:
            return serving?.unit != nil
        case .servingUnitSize:
            return serving?.unitName != nil
        case .servingEquivalentAmount:
            return serving?.equivalentSize != nil
        case .servingEquivalentUnit:
            return serving?.equivalentSize?.unit != nil
        case .servingEquivalentUnitSize:
            return serving?.equivalentSize?.unitName != nil
        case .servingsPerContainerAmount:
            return serving?.perContainer != nil
        case .servingsPerContainerName:
            return serving?.perContainer?.name != nil
        case .headerType1:
            return headers?.headerText1 != nil
        case .headerType2:
            return headers?.headerText2 != nil
        default:
            return nutrients.rows.contains(where: { $0.attribute == attribute })
        }
    }
}

public extension ScanResult {
    var allTexts: [RecognizedText] {
        servingTexts + headerTexts + nutrientTexts
    }
    var servingTexts: [RecognizedText] {
        [
            serving?.amountText?.text,
            serving?.amountText?.attributeText,
            serving?.unitText?.text,
            serving?.unitText?.attributeText,
            serving?.unitNameText?.text,
            serving?.unitNameText?.attributeText,
            serving?.equivalentSize?.amountText.text,
            serving?.equivalentSize?.amountText.attributeText,
            serving?.equivalentSize?.unitText?.text,
            serving?.equivalentSize?.unitText?.attributeText,
            serving?.equivalentSize?.unitNameText?.text,
            serving?.equivalentSize?.unitNameText?.attributeText,
            serving?.perContainer?.amountText.text,
            serving?.perContainer?.amountText.attributeText,
            serving?.perContainer?.nameText?.text,
            serving?.perContainer?.nameText?.attributeText,
        ]
            .compactMap { $0 }
    }
    
    var headerTexts: [RecognizedText] {
        [
            headers?.headerText1?.text,
            headers?.headerText1?.attributeText,
            headers?.headerText2?.text,
            headers?.headerText2?.attributeText
        ]
            .compactMap { $0 }
    }
    
    var nutrientTexts: [RecognizedText] {
        var texts: [RecognizedText?] = []
        for row in nutrients.rows {
            texts.append(row.attributeText.text)
            texts.append(row.valueText1?.text)
            texts.append(row.valueText1?.attributeText)
            texts.append(row.valueText2?.text)
            texts.append(row.valueText2?.attributeText)
        }
        return texts.compactMap { $0 }
    }
}

public extension ScanResult {
    
    var boundingBox: CGRect {
        allTexts
            .filter { $0.boundingBox != .zero }
            .boundingBox
    }
    
    var validNutrientsRows: [Nutrients.Row] {
        nutrients.rows.filter { $0.valueText1 != nil || $0.valueText2 != nil }
    }
    
    var nutrientAttributes: [Attribute] {
        validNutrientsRows.map({ $0.attribute })
    }
    
    var nutrientsCount: Int {
        validNutrientsRows.count
    }
    
    var hasNutrients: Bool {
        !validNutrientsRows.isEmpty
    }
    
    var resultTexts: [RecognizedText] {
        nutrientAttributeTexts
    }
    
    var nutrientAttributeTexts: [RecognizedText] {
        validNutrientsRows.map { $0.attributeText.text }
    }
    
    var nutrientValueTexts: [RecognizedText] {
        validNutrientsRows.map { $0.attributeText.text }
    }
    
    func amount(for attribute: Attribute) -> Double? {
        nutrients.rows.first(where: { $0.attribute == attribute })?.value1?.amount
    }
    
    func countOfHowManyNutrientsMatchAmounts(in dict: [Attribute : (Double, Int)]) -> Int {
        var count = 0
        for attribute in dict.keys {
            guard let amount = amount(for: attribute) else { continue }
            if amount == dict[attribute]?.0 {
                count += 1
            }
        }
        return count
    }
    
}

public extension Attribute {
    var micro: Micro? {
        Micro.allCases.first(where: { $0.attribute == self })
    }
}

public extension Micro {
    var attribute: Attribute? {
        switch self {
        case .saturatedFat:
            return .saturatedFat
        case .monounsaturatedFat:
            return .monounsaturatedFat
        case .polyunsaturatedFat:
            return .polyunsaturatedFat
        case .transFat:
            return .transFat
        case .cholesterol:
            return .cholesterol
        case .dietaryFiber:
            return .dietaryFibre
        case .solubleFiber:
            return .solubleFibre
        case .insolubleFiber:
            return .insolubleFibre
        case .sugars:
            return .sugar
        case .addedSugars:
            return .addedSugar
        case .calcium:
            return .calcium
        case .chromium:
            return .chromium
        case .iodine:
            return .iodine
        case .iron:
            return .iron
        case .magnesium:
            return .magnesium
        case .manganese:
            return .manganese
        case .potassium:
            return .potassium
        case .selenium:
            return .selenium
        case .sodium:
            return .sodium
        case .zinc:
            return .zinc
        case .vitaminA:
            return .vitaminA
        case .vitaminB6_pyridoxine:
            return .vitaminB6
        case .vitaminB12_cobalamin:
            return .vitaminB12
        case .vitaminC_ascorbicAcid:
            return .vitaminC
        case .vitaminD_calciferol:
            return .vitaminD
        case .vitaminE:
            return .vitaminE
        case .vitaminK1_phylloquinone:
            return .vitaminK
        case .vitaminB7_biotin:
            return .biotin
        case .vitaminB9_folate:
            return .folate
        case .vitaminB3_niacin:
            return .niacin
        case .vitaminB5_pantothenicAcid:
            return .pantothenicAcid
        case .vitaminB2_riboflavin:
            return .riboflavin
        case .vitaminB1_thiamine:
            return .thiamin
        case .vitaminB9_folicAcid:
            return .folicAcid
        case .vitaminK2_menaquinone:
            return .vitaminK2
        case .caffeine:
            return .caffeine
        case .taurine:
            return .taurine
        case .polyols:
            return .polyols
        case .gluten:
            return .gluten
        case .starch:
            return .starch
        case .salt:
            return .salt
            
        case .phosphorus:
            return .phosphorus
            
        /// No support (yet) for remaining ones, add entry into `Attribute` First
            
        default:
            return nil
        }
    }
}

public extension ScanResult {

    func nutrientsTexts(includeAttributes: Bool = false) -> [RecognizedText] {
        var texts: [RecognizedText] = []
        texts = headerTexts
        for nutrient in nutrients.rows {
            /// Only use nutrients that have at least one value
            guard nutrient.valueText1 != nil || nutrient.valueText2 != nil else {
                continue
            }
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

    func nutrientsBoundingBox(includeAttributes: Bool) -> CGRect {
        nutrientsTexts(includeAttributes: includeAttributes)
            .filter { $0.id != defaultUUID }
            .boundingBox
    }
}

public extension ScanResult {
    var textsWithFoodLabelValues: [RecognizedText] {
        texts.filter { $0.hasFoodLabelValues }
    }

    var textsWithoutFoodLabelValues: [RecognizedText] {
        texts.filter { !$0.hasFoodLabelValues }
    }
}

import VisionSugar

public extension RecognizedText {
    
    /**
     Returns the first detected `FoodLabelValue` in the string and all its candidates, if present.
     */
    var firstFoodLabelValue: FoodLabelValue? {
        string.detectedValues.first ?? (candidates.first(where: { !$0.detectedValues.isEmpty }))?.detectedValues.first
    }
    
    /**
     Returns true if the string or any of the other candidates contains `FoodLabelValues` in them.
     */
    var hasFoodLabelValues: Bool {
        !string.detectedValues.isEmpty
        || candidates.contains(where: { !$0.detectedValues.isEmpty })
    }
}

