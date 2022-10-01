import Foundation
import VisionSugar

public struct ScanResultSet: Codable {
    public let inline: ScanResult
    public let tabular: ScanResult
    public let texts: [RecognizedText]
}

public struct ScanResult: Codable {
    public let id: UUID
    public let serving: Serving?
    public let nutrients: Nutrients
    
    init(id: UUID = UUID(), serving: Serving?, nutrients: Nutrients) {
        self.id = id
        self.serving = serving
        self.nutrients = nutrients
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
        }

        public struct PerContainer: Codable {
            public let amountText: DoubleText
            public let nameText: StringText?
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
        }
    }
}

//MARK: - Text-based Structs

public struct ValueText: Codable {
    public var value: Value
    public let text: RecognizedText
    public let attributeText: RecognizedText?
    
    init(value: Value, text: RecognizedText, attributeText: RecognizedText? = nil) {
        self.value = value
        self.text = text
        self.attributeText = attributeText
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
    public let unit: NutritionUnit
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(unit: NutritionUnit, text: RecognizedText, attributeText: RecognizedText) {
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
        public let unit: NutritionUnit?
        public let unitName: String?
        public let equivalentSize: EquivalentSize?
        
        public struct EquivalentSize: Codable {
            public let amount: Double
            public let unit: NutritionUnit?
            public let unitName: String?
        }
    }
}
