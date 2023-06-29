import Foundation
import VisionSugar
import FoodDataTypes

let CurrentRevision = 1

public struct ScanResult: Hashable, Codable {
    public let id: UUID
    public let serving: Serving?
    public let headers: Headers?
    public let nutrients: Nutrients
    public let texts: [RecognizedText]
    public let barcodes: [RecognizedBarcode]
    public let revision: Int?
    public let classifier: Classifier?
    
    public init(id: UUID = UUID(), serving: Serving?, headers: Headers?, nutrients: Nutrients, texts: [RecognizedText], barcodes: [RecognizedBarcode], classifier: Classifier?) {
        self.id = id
        self.serving = serving
        self.headers = headers
        self.nutrients = nutrients
        self.texts = texts
        self.barcodes = barcodes
        self.revision = CurrentRevision
        self.classifier = classifier
    }
}

extension ScanResult {
    //MARK: Serving
    public struct Serving: Hashable, Codable {
        //TODO: Add attribute texts for these too
        public let amountText: DoubleText?
        public let unitText: UnitText?
        public let unitNameText: StringText?
        public let equivalentSize: EquivalentSize?

        public let perContainer: PerContainer?

        public struct EquivalentSize: Hashable, Codable {
            public let amountText: DoubleText
            public let unitText: UnitText?
            public let unitNameText: StringText?
            
            public init(amountText: DoubleText, unitText: UnitText?, unitNameText: StringText?) {
                self.amountText = amountText
                self.unitText = unitText
                self.unitNameText = unitNameText
            }
        }

        public struct PerContainer: Hashable, Codable {
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
    
    public struct Headers: Hashable, Codable {
        public let headerText1: HeaderText?
        public let headerText2: HeaderText?
        
        public init(headerText1: HeaderText?, headerText2: HeaderText?) {
            self.headerText1 = headerText1
            self.headerText2 = headerText2
        }
    }
    
    //MARK: Nutrients
    public struct Nutrients: Hashable, Codable {
        
        public let rows: [Row]
        
        public struct Row: Hashable, Codable {
            public let attributeText: AttributeText
            public let valueText1: ValueText?
            public let valueText2: ValueText?
            
            public init(attributeText: AttributeText, valueText1: ValueText?, valueText2: ValueText?) {
                self.attributeText = attributeText
                self.valueText1 = valueText1
                self.valueText2 = valueText2
            }
        }
        
        public init(rows: [Row]) {
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

public struct DoubleText: Hashable, Codable {
    public let double: Double
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(double: Double, text: RecognizedText, attributeText: RecognizedText) {
        self.double = double
        self.text = text
        self.attributeText = attributeText
    }
}

public struct UnitText: Hashable, Codable {
    public let unit: FoodLabelUnit
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(unit: FoodLabelUnit, text: RecognizedText, attributeText: RecognizedText) {
        self.unit = unit
        self.text = text
        self.attributeText = attributeText
    }
}

public struct StringText: Hashable, Codable {
    public let string: String
    public let text: RecognizedText
    public let attributeText: RecognizedText
    
    public init(string: String, text: RecognizedText, attributeText: RecognizedText) {
        self.string = string
        self.text = text
        self.attributeText = attributeText
    }
}

public struct HeaderText: Hashable, Codable {
    public let type: HeaderType
    public let text: RecognizedText
    public let attributeText: RecognizedText
    public let serving: Serving?
    
    public struct Serving: Hashable, Codable {
        public let amount: Double?
        public let unit: FoodLabelUnit?
        public let unitName: String?
        public let equivalentSize: EquivalentSize?
        
        public struct EquivalentSize: Hashable, Codable {
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

//MARK: - Convenience

extension Array where Element == ScanResult.Nutrients.Row {
    func contains(attribute: Attribute) -> Bool {
        contains(where: { $0.attribute == attribute })
    }
    
    func row(forAttribute attribute: Attribute) -> ScanResult.Nutrients.Row? {
        first(where: { $0.attribute == attribute })
    }
}

//MARK: - Description

extension ScanResult.Serving: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unitText {
            unitString = " \(unitText.unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitNameText {
            unitNameString = " \(unitNameText.string)"
        } else {
            unitNameString = ""
        }
        let amountString: String
        if let amountText {
            amountString = amountText.double.cleanAmount
        } else {
            amountString = ""
        }
        return "\(amountString)\(unitString)\(unitNameString)"
    }
}

extension ScanResult.Serving.EquivalentSize: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unitText {
            unitString = " \(unitText.unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitNameText {
            unitNameString = " \(unitNameText.string)"
        } else {
            unitNameString = ""
        }
        return "\(amount.cleanAmount)\(unitString)\(unitNameString)"
    }
}

extension ScanResult.Serving.PerContainer: CustomStringConvertible {
    public var description: String {
        let nameString: String
        if let nameText {
            nameString = " \(nameText.string)"
        } else {
            nameString = ""
        }
        return "\(amountText.double.cleanAmount)\(nameString)"
    }
}

extension HeaderText.Serving: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unit {
            unitString = " \(unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitName {
            unitNameString = " \(unitName)"
        } else {
            unitNameString = ""
        }
        let amountString: String
        if let amount {
            amountString = amount.cleanAmount
        } else {
            amountString = ""
        }
        return "\(amountString)\(unitString)\(unitNameString)"
    }
}

extension HeaderText.Serving.EquivalentSize: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unit {
            unitString = " \(unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitName {
            unitNameString = " \(unitName)"
        } else {
            unitNameString = ""
        }
        return "\(amount.cleanAmount)\(unitString)\(unitNameString)"
    }
}
