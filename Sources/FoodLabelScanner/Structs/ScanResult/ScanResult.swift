import Foundation
import VisionSugar
import PrepUnits

public struct ScanResult: Codable {
    public let id: UUID
    public let serving: Serving?
    public let nutrients: Nutrients
    public let texts: [RecognizedText]
    
    public init(id: UUID = UUID(), serving: Serving?, nutrients: Nutrients, texts: [RecognizedText]) {
        self.id = id
        self.serving = serving
        self.nutrients = nutrients
        self.texts = texts
    }
}

extension ScanResult {
    //MARK: Serving
    public struct Serving: Codable {
        //TODO: Add attribute texts for these too
        public let amountText: DoubleText?
        public let unitText: UnitText?
        public let unitNameText: StringText?
        public let equivalentSize: EquivalentSize?

        public let perContainer: PerContainer?

        public struct EquivalentSize: Codable {
            public let amountText: DoubleText
            public let unitText: UnitText?
            public let unitNameText: StringText?
            
            public init(amountText: DoubleText, unitText: UnitText?, unitNameText: StringText?) {
                self.amountText = amountText
                self.unitText = unitText
                self.unitNameText = unitNameText
            }
        }

        public struct PerContainer: Codable {
            public let amountText: DoubleText
            public let nameText: StringText?
            
            public init(amountText: DoubleText, nameText: StringText?) {
                self.amountText = amountText
                self.nameText = nameText
            }
        }
        
        public init(amountText: DoubleText?, unitText: UnitText?, unitNameText: StringText?, equivalentSize: EquivalentSize?, perContainer: PerContainer?) {
            self.amountText = amountText
            self.unitText = unitText
            self.unitNameText = unitNameText
            self.equivalentSize = equivalentSize
            self.perContainer = perContainer
        }
    }
    
    //MARK: Nutrients
    public struct Nutrients: Codable {
        public let headerText1: HeaderText?
        public let headerText2: HeaderText?
        
        public let rows: [Row]
        
        public struct Row: Codable {
            public let attributeText: AttributeText
            public let valueText1: ValueText?
            public let valueText2: ValueText?
            
            public init(attributeText: AttributeText, valueText1: ValueText?, valueText2: ValueText?) {
                self.attributeText = attributeText
                self.valueText1 = valueText1
                self.valueText2 = valueText2
            }
        }
        
        public init(headerText1: HeaderText?, headerText2: HeaderText?, rows: [Row]) {
            self.headerText1 = headerText1
            self.headerText2 = headerText2
            self.rows = rows
        }
    }
}

//MARK: - Text-based Structs

public struct ValueText: Codable {
    public var value: FoodLabelValue
    public let text: RecognizedText
    public let attributeText: RecognizedText?
    
    public init(value: FoodLabelValue, text: RecognizedText, attributeText: RecognizedText? = nil) {
        self.value = value
        self.text = text
        self.attributeText = attributeText
    }
}

public struct DoubleText: Codable {
    public let double: Double
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(double: Double, text: RecognizedText, attributeText: RecognizedText) {
        self.double = double
        self.text = text
        self.attributeText = attributeText
    }
}

public struct UnitText: Codable {
    public let unit: FoodLabelUnit
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(unit: FoodLabelUnit, text: RecognizedText, attributeText: RecognizedText) {
        self.unit = unit
        self.text = text
        self.attributeText = attributeText
    }
}

public struct StringText: Codable {
    public let string: String
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(string: String, text: RecognizedText, attributeText: RecognizedText) {
        self.string = string
        self.text = text
        self.attributeText = attributeText
    }
}

public struct HeaderText: Codable {
    public let type: HeaderType
    public let text: RecognizedText
    public let attributeText: RecognizedText
    public let serving: Serving?
    
    public struct Serving: Codable {
        public let amount: Double?
        public let unit: FoodLabelUnit?
        public let unitName: String?
        public let equivalentSize: EquivalentSize?
        
        public struct EquivalentSize: Codable {
            public let amount: Double
            public let unit: FoodLabelUnit?
            public let unitName: String?
            
            public init(amount: Double, unit: FoodLabelUnit?, unitName: String?) {
                self.amount = amount
                self.unit = unit
                self.unitName = unitName
            }
        }
        
        public init(amount: Double?, unit: FoodLabelUnit?, unitName: String?, equivalentSize: EquivalentSize?) {
            self.amount = amount
            self.unit = unit
            self.unitName = unitName
            self.equivalentSize = equivalentSize
        }
    }
    
    public init(type: HeaderType, text: RecognizedText, attributeText: RecognizedText, serving: Serving?) {
        self.type = type
        self.text = text
        self.attributeText = attributeText
        self.serving = serving
    }
}

extension ValueText: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(text)
        hasher.combine(attributeText)
    }
}

extension ValueText: CustomStringConvertible {
    public var description: String {
        value.description
    }
}
