import SwiftSugar
import PrepDataTypes

public enum Attribute: String, CaseIterable, Codable {
    
    case tableElementNutritionFacts
    case tableElementSkippable
    
    case nutrientLabelTotal
    
    //MARK: - Serving
    case servingAmount                 /// Double
    case servingUnit                  /// NutritionUnit
    case servingUnitSize              /// String
    case servingEquivalentAmount       /// Double
    case servingEquivalentUnit        /// NutritionUnit
    case servingEquivalentUnitSize    /// String
    
    case servingsPerContainerAmount
    case servingsPerContainerName
    
    //MARK: - Header
    /// Header type for column 1 and 2, which indicates if they are a `per100g` or `perServing` column
    case headerType1
    case headerType2
    
    /// Header serving attributes which gets assigned to whichever column has the `perServing` type
    case headerServingAmount
    case headerServingUnit
    case headerServingUnitSize
    case headerServingEquivalentAmount
    case headerServingEquivalentUnit
    case headerServingEquivalentUnitSize
    
    //MARK: - Nutrient
    case energy
    
    //MARK: Core Table Nutrients
    case protein
    
    case carbohydrate
    case gluten
    case sugar
    case addedSugar
    case polyols
    case starch
    
    case dietaryFibre
    case solubleFibre
    case insolubleFibre
    
    case fat
    case saturatedFat
    case polyunsaturatedFat
    case monounsaturatedFat
    case transFat
    case cholesterol
    
    case salt
    case sodium
    
    //MARK: Additional Table Nutrients (Usually at bottom)
    case calcium
    case iron
    case potassium
    case cobalamin
    case magnesium
    case zinc
    case iodine
    case selenium
    case manganese
    case chromium
    
    case thiamin
    case folate
    case folicAcid
    case biotin
    case pantothenicAcid
    case riboflavin
    case niacin
    case vitaminA
    case vitaminC
    case vitaminD
    case vitaminB1
    case vitaminB3
    case vitaminB6
    case vitaminB2
    case vitaminB12
    case vitaminE
    case vitaminK
    case vitaminK2
    
    case taurine
    case caffeine
}

extension Attribute {
    static var vitamins: [Attribute] {
        [.vitaminA, .vitaminC, .vitaminD, .vitaminB1, .vitaminB2, .vitaminB3, .vitaminB6, .vitaminB12, .vitaminE, .vitaminK, .vitaminK2]
    }
    
    static var vitaminChemicalNames: [Attribute] {
        [.thiamin, .folate, .folicAcid, .biotin, .pantothenicAcid, .riboflavin, .niacin]
    }
    
    var isVitamin: Bool {
        Self.vitamins.contains(self)
    }

    var isVitaminChemicalName: Bool {
        Self.vitaminChemicalNames.contains(self)
    }
    
    func shouldIgnoreAttributeIfOnSameString(as attribute: Attribute) -> Bool {
        
        /// Handles edge case of misreading `Riboflavin (Vitamin B12` as `Riboflavin (Vitamin E`
        if self == .vitaminE, attribute == .riboflavin {
            return true
        }
        
        /// Handles cases where we have both `Vitamin B2` and `Riboflavin` on the same string (which are the same)
        if self == .vitaminB2, attribute == .riboflavin {
            return true
        }
        return false
    }
    
    func isSameAttribute(as attribute: Attribute) -> Bool {
        switch self {
        case .thiamin:
            return attribute == .vitaminB1
        case .vitaminB1:
            return attribute == .thiamin
        default:
            return false
        }
    }

    var isCoreTableNutrient: Bool {
        switch self {
        case .protein, .carbohydrate, .gluten, .sugar, .addedSugar, .polyols, .starch, .dietaryFibre, .solubleFibre, .insolubleFibre, .fat, .saturatedFat, .polyunsaturatedFat, .monounsaturatedFat, .transFat, .cholesterol, .salt, .sodium:
            return true
        default:
            return false
        }
    }
    
    public var conflictingAttributes: [Attribute] {
        switch self {
        case .servingUnit:
            return [.servingUnitSize]
        case .servingUnitSize:
            return [.servingUnit]
        case .servingEquivalentUnit:
            return [.servingEquivalentUnitSize]
        case .servingEquivalentUnitSize:
            return [.servingEquivalentUnit]
        case .headerServingUnit:
            return [.headerServingUnitSize]
        case .headerServingUnitSize:
            return [.headerServingUnit]
        case .headerServingEquivalentUnit:
            return [.headerServingEquivalentUnitSize]
        case .headerServingEquivalentUnitSize:
            return [.headerServingEquivalentUnit]
        default:
            return []
        }
    }
    
    public var isHeaderAttribute: Bool {
        switch self {
        case .headerServingAmount, .headerServingUnit, .headerServingUnitSize, .headerServingEquivalentAmount, .headerServingEquivalentUnit, .headerServingEquivalentUnitSize, .headerType1, .headerType2:
            return true
        default:
            return false
        }
    }
    public var isServingAttribute: Bool {
        switch self {
        case .servingAmount, .servingUnit, .servingUnitSize, .servingEquivalentAmount, .servingEquivalentUnit, .servingEquivalentUnitSize, .servingsPerContainerName, .servingsPerContainerAmount:
            return true
        default:
            return false
        }
    }
    
    public var expectsDouble: Bool {
        switch self {
        case .servingAmount, .servingEquivalentAmount, .servingsPerContainerAmount, .headerServingAmount, .headerServingEquivalentAmount:
            return true
        default:
            return false
        }
    }
    
    public var expectsHeaderType: Bool {
        switch self {
        case .headerType1, .headerType2:
            return true
        default:
            return false
        }
    }
    public var expectsNutritionUnit: Bool {
        switch self {
        case .servingUnit, .servingEquivalentUnit, .headerServingUnit, .headerServingEquivalentUnit:
            return true
        default:
            return false
        }
    }
    
    public var expectsString: Bool {
        switch self {
        case .servingUnitSize, .servingEquivalentUnitSize, .servingsPerContainerName, .headerServingUnitSize, .headerServingEquivalentUnitSize:
            return true
        default:
            return false
        }
    }
    
    public var isTableAttribute: Bool {
        switch self {
        case .tableElementNutritionFacts, .tableElementSkippable:
            return true
        default:
            return false
        }
    }
    
    public var isLabelAttribute: Bool {
        switch self {
        case .nutrientLabelTotal:
            return true
        default:
            return false
        }
    }
    public var isNutrientAttribute: Bool {
        !isHeaderAttribute && !isServingAttribute && !isTableAttribute && !isLabelAttribute
    }

    var childrenAttributes: [Attribute] {
        Self.allCases.filter { $0.parentAttribute == self }
    }
    
    var parentAttribute: Attribute? {
        switch self {
        case .saturatedFat, .polyunsaturatedFat, .monounsaturatedFat, .transFat, .cholesterol:
            return .fat
        case .sugar, .addedSugar, .starch:
            return .carbohydrate
        case .sodium:
            return .salt
        default:
            return nil
        }
    }
    
    public func supportsUnit(_ unit: FoodLabelUnit) -> Bool {
        supportedUnits.contains(unit)
    }
    
    public var defaultUnit: FoodLabelUnit? {
        supportedUnits.first
    }
    
    var supportsMultipleColumns: Bool {
        switch self {
        case .servingsPerContainerAmount, .servingsPerContainerName:
            return false
        default:
            return true
        }
    }
    
    /// For values like `servingsPerContainerAmount` and `addedSugar` which allows extracting preceding values like the following:
    /// `40 Servings Per Container`
    /// `Includes 4g Added Sugar`
    var supportsPrecedingValue: Bool {
        switch self {
        case .servingsPerContainerAmount, .servingsPerContainerName:
            return true
        default:
            return false
        }
    }
    
    var supportedUnits: [FoodLabelUnit] {
        switch self {
            
        case .energy:
            return [ .kcal, .kj ]
            
        case .protein, .carbohydrate, .fat, .salt:
            return [.g]
            
        case .dietaryFibre, .solubleFibre, .insolubleFibre, .saturatedFat, .polyunsaturatedFat, .monounsaturatedFat, .transFat, .sugar, .addedSugar, .gluten, .starch, .polyols:
            return [.g, .mg, .mcg]
            
        case .cholesterol, .sodium, .calcium, .iron, .potassium, .cobalamin, .vitaminA, .vitaminC, .vitaminD, .vitaminB6, .zinc, .iodine, .selenium, .magnesium, .manganese, .chromium, .thiamin, .folate, .biotin, .pantothenicAcid, .riboflavin, .niacin, .vitaminB1, .vitaminB3, .vitaminE, .vitaminK, .vitaminK2, .taurine, .caffeine, .vitaminB2:
            return [.mg, .mcg, .p, .g]
            
        case .folicAcid, .vitaminB12:
            return [.mcg, .mg, .p, .g]
            
        case .servingAmount:
            return [.cup, .g, .mcg, .mg]
            
        case .tableElementNutritionFacts, .tableElementSkippable, .nutrientLabelTotal, .servingUnit, .servingUnitSize, .servingEquivalentAmount, .servingEquivalentUnit, .servingEquivalentUnitSize, .servingsPerContainerAmount, .servingsPerContainerName, .headerType1, .headerType2, .headerServingAmount, .headerServingUnit, .headerServingUnitSize, .headerServingEquivalentAmount, .headerServingEquivalentUnit, .headerServingEquivalentUnitSize:
            return []
        }
    }
    
    func supportsServingArtefact(_ servingArtefact: ServingArtefact) -> Bool {
        switch self {
        case .servingsPerContainerName, .servingUnitSize, .servingEquivalentUnitSize:
            return servingArtefact.string != nil
        case .servingAmount, .servingEquivalentAmount, .servingsPerContainerAmount:
            return servingArtefact.double != nil
        case .servingUnit, .servingEquivalentUnit:
            return servingArtefact.unit != nil
        default:
            return false
        }
    }
    
    var supportsTotalLabel: Bool {
        switch self {
        case .fat, .carbohydrate:
            return true
        default:
            return false
        }
    }

    var nextAttributes: [Attribute]? {
        switch self {
        case .servingAmount:
            return [.servingUnit, .servingUnitSize]
        case .servingUnit, .servingUnitSize:
            return [.servingEquivalentAmount]
        case .servingEquivalentAmount:
            return [.servingEquivalentUnit, .servingEquivalentUnitSize]
        default:
            return nil
        }
    }
    
    
    
    var supportsUnitLessValues: Bool {
        switch self {
        case .servingsPerContainerAmount, .servingsPerContainerName:
            return true
        default:
            return false
        }
    }
    
    init?(fromString string: String) {
        
        let stringsToIgnorePattern = #"from fat"#
        guard !string.matchesRegex(stringsToIgnorePattern) else {
            return nil
        }
        
        var pickedAttribute: Attribute? = nil
        for attribute in Self.allCases {
            guard let regex = attribute.regex else { continue }
            if string.cleanedAttributeString.matchesRegex(regex) {
                guard pickedAttribute == nil else {
                    /// Fail strings that contain more than one match (since the order shouldn't dictate what we choose)
                    return nil
                }
                pickedAttribute = attribute
            }
        }
        if let pickedAttribute = pickedAttribute {
            self = pickedAttribute
        } else {
            return nil
        }
    }
    
    var isValueBased: Bool {
        switch self {
        case .servingAmount, .servingUnit, .servingUnitSize, .servingEquivalentAmount, .servingEquivalentUnit, .servingEquivalentUnitSize, .servingsPerContainerAmount, .servingsPerContainerName:
            return false
        default:
            return true
        }
    }}

extension Attribute {
    
    /// Detects `Attribute`s in a provided `string` in the order that they appear
    static func detect(in string: String) -> [Attribute] {
        var array: [(attribute: Attribute, positionOfMatch: Int)] = []
        
        for attribute in Self.allCases {
            guard let regex = attribute.regex else { continue }
            if let match = string.cleanedAttributeString.matches(for: regex)?.first {
//                // print("🧬 \(attribute.rawValue): \(string)")
                array.append((attribute, match.position))
            }
        }
        
        array.sort(by: { $0.positionOfMatch < $1.positionOfMatch })
        
        var filtered: [(attribute: Attribute, positionOfMatch: Int)] = []
        for i in array.indices {
            let element = array[i]
            guard !filtered.contains(where: { element.attribute.shouldIgnoreAttributeIfOnSameString(as: $0.attribute)}) else {
                continue
            }
            filtered.append(element)
        }
        return filtered.map { $0.attribute }
    }

    static func haveAttributes(in string: String) -> Bool {
        detect(in: string).count > 0
    }
    
    static func haveNutrientAttribute(in string: String) -> Bool {
        detect(in: string).contains(where: { $0.isNutrientAttribute })
    }
}

extension Attribute: Identifiable {
    public var id: RawValue { rawValue }
}

extension Attribute {
    static func attributes(in string: String) -> [Attribute] {
        for attribute in Attribute.allCases {
            guard let regex = attribute.regex else { continue }
            if string.matchesRegex(regex) {
                return [attribute]
            }
        }
        return []
    }
}


extension Attribute: CustomStringConvertible {
    public var description: String {
        switch self {
        case .tableElementNutritionFacts:
            return "Nutrition Facts"
        case .tableElementSkippable:
            return "Vitamins & Minerals"
        case .nutrientLabelTotal:
            return "Total (Nutrient Label)"
        case .servingAmount:
            return "Serving Amount"
        case .servingUnit:
            return "Serving Unit"
        case .servingUnitSize:
            return "Serving Unit Size"
        case .servingEquivalentAmount:
            return "Serving Equivalent Amount"
        case .servingEquivalentUnit:
            return "Serving Equivalent Unit"
        case .servingEquivalentUnitSize:
            return "Serving Equivalent Unit Size"
        case .servingsPerContainerAmount:
            return "Servings Per Container Amount"
        case .servingsPerContainerName:
            return "Servings Per Container Name"
        case .headerType1:
            return "Header Type 1"
        case .headerType2:
            return "Header Type 2"
        case .headerServingAmount:
            return "Header Serving Amount"
        case .headerServingUnit:
            return "Header Serving Unit"
        case .headerServingUnitSize:
            return "Header Serving Unit Name"
        case .headerServingEquivalentAmount:
            return "Header Serv.Equiv. Amount"
        case .headerServingEquivalentUnit:
            return "Header Serv.Equiv. Unit"
        case .headerServingEquivalentUnitSize:
            return "Header Serv.Equiv. Unit Name"
            
        case .energy:
            return "Energy"
        case .protein:
            return "Protein"
        case .carbohydrate:
            return "Carbohydrate"
        case .dietaryFibre:
            return "Dietary Fibre"
        case .gluten:
            return "Gluten"
        case .sugar:
            return "Total Sugars"
        case .addedSugar:
            return "Added Sugars"
        case .polyols:
            return "Polyols"
        case .starch:
            return "Starch"
        case .fat:
            return "Fat"
        case .saturatedFat:
            return "Saturated Fat"
        case .polyunsaturatedFat:
            return "Polyunsaturated Fat"
        case .monounsaturatedFat:
            return "Monounsaturated Fat"
        case .transFat:
            return "Trans Fat"
        case .cholesterol:
            return "Cholesterol"
        case .salt:
            return "Salt"
        case .sodium:
            return "Sodium"
        case .calcium:
            return "Calcium"
        case .iron:
            return "Iron"
        case .magnesium:
            return "Magnesium"
        case .cobalamin:
            return "Cobalamin"
        case .potassium:
            return "Potassium"
        case .vitaminA:
            return "Vitamin A"
        case .vitaminC:
            return "Vitamin C"
        case .vitaminD:
            return "Vitamin D"
        case .vitaminB6:
            return "Vitamin B6"
        case .vitaminB3:
            return "Vitamin B3"
            
        case .thiamin:
            return "Thiamin"
        case .riboflavin:
            return "Riboflavin"
        case .niacin:
            return "Niacin"
        case .zinc:
            return "Zinc"
        case .folate:
            return "Folate"
        case .folicAcid:
            return "Folic Acid"
        case .vitaminB1:
            return "Vitamin B1"
        case .vitaminB2:
            return "Vitamin B2"
        case .vitaminB12:
            return "Vitamin B12"
        case .solubleFibre:
            return "Soluble Fibre"
        case .insolubleFibre:
            return "Insoluble Fibre"
            
        case .iodine:
            return "Iodine"
        case .selenium:
            return "Selenium"
        case .manganese:
            return "Manganese"
        case .chromium:
            return "Chromium"
        case .biotin:
            return "Biotin"
        case .pantothenicAcid:
            return "Pantothenic Acid"
        case .vitaminE:
            return "Vitamin E"
        case .vitaminK:
            return "Vitamin K"
        case .vitaminK2:
            return "Vitamin K2"
            
        case .taurine:
            return "Taurine"
        case .caffeine:
            return "Caffeine"
        }
    }
}
