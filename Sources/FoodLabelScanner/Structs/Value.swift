import Foundation

public struct Value: Codable {
    public let amount: Double
    public var unit: NutritionUnit?
    
    init?(fromString string: String) {
        
        /// Special cases
        let str = string.trimmingWhitespaces.lowercased()
        if str == "nil" || str == "not detected" {
            self.amount = 0
//            self.unit = .g
            return
        } else if str == "trace" {
            self.amount = 0.08
            self.unit = .g
//            self.unit = .g
            return
        }
        
        let groups = string.capturedGroups(using: Regex.fromString, allowCapturingEntireString: true)
        guard groups.count > 1 else {
            return nil
        }
        
        var cleanedAmount = groups[1]
            .replacingOccurrences(of: ":", with: ".") /// Fix Vision errors of misreading decimal places as `:`
        
        /// Special case when we misread something like `0.8 ug` as `08 ug`
        if let singleDigitPrefixedByZero = cleanedAmount.firstCapturedGroup(using: #"^0([0-9])$"#) {
            cleanedAmount = "0.\(singleDigitPrefixedByZero)"
        }
        
        if cleanedAmount.matchesRegex(NumberRegex.usingCommaAsDecimalPlace) {
            cleanedAmount = cleanedAmount.replacingOccurrences(of: ",", with: ".")
        } else {
            /// It's been used as a thousand separator in that case
            cleanedAmount = cleanedAmount.replacingOccurrences(of: ",", with: "")
        }
        
        guard let amount = Double(cleanedAmount) else {
            return nil
        }
        self.amount = amount
        if groups.count == 3 {
            guard let unit = NutritionUnit(string: groups[2].lowercased().trimmingWhitespaces) else {
                return nil
            }
            self.unit = unit
        } else {
            self.unit = nil
        }
    }
    
    public init(amount: Double, unit: NutritionUnit? = nil) {
        self.amount = amount
        self.unit = unit
    }
    
    struct Regex {
        static let units = NutritionUnit.allUnits.map { #"[ ]*\#($0)"# }.joined(separator: "|")
        static let number = #"[0-9]+[0-9.:,]*"#
        static let atStartOfString = #"^(?:(\#(number)(?:(?:\#(units)(?: |\)|$))| |$)*(?: |\)|\/|$))|nil(?: |$)|trace(?: |$))"#
        static let atStartOfString_legacy2 = #"^(?:(\#(number)(?:(?:\#(units)(?: |\)|$))| |$))|nil(?: |$)|trace(?: |$))"#
        static let atStartOfString_legacy1 = #"^(\#(number)(?:(?:\#(units)(?: |\)|$))| |$))"#
        static let fromString = #"^(\#(number))(?:(\#(units)(?: |\)|$))| |\/|$)"#
        
        //TODO: Remove this
        static let standardPattern =
        #"^(?:[^0-9.:]*(?: |\()|^\/?)([0-9.:]+)[ ]*(\#(units))+(?: .*|\).*$|\/?$)$"#
    }
    
    static var DisqualifyingTexts: [String] = [
        "contributes to a daily diet",
        "daily value",
        "produced for",
        "keep frozen",
        "best before",
        "ingredients"
//        "of which"
    ]
    
    var hasEnergyUnit: Bool {
        guard let unit = unit else { return false }
        return unit.isEnergy
    }
    
    var hasNutrientUnit: Bool {
        guard let unit = unit else { return false }
        return unit.isNutrientUnit
    }
    
    var isReferenceEnergyValue: Bool {
        if amount == 8400, unit == .kj {
            return true
        }
        if amount == 2000, unit == .kcal {
            return true
        }
        return false
    }
}

extension Value {
    
    ///Prioritises value with unit if only 1 is found, otherwise returning the first value
    public static func detectSingleValue(in string: String) -> Value? {
        let values = Self.detect(in: string)
        if values.containingUnit.count == 1 {
            return values.containingUnit.first
        } else {
            return values.first
        }
    }

    public static func detect(in string: String) -> [Value] {
        detect(in: string, withPositions: false).map { $0.0 }
    }
    
    /// Detects `Value`s in a provided `string` in the order that they appear
    static func detect(in string: String, withPositions: Bool) -> [(Value, Int)] {
        
        var string = string
        /// Add regex to check if we have "Not detected" or "nil" and replace with 0 (no unit)
//        if string.matchesRegex("(not detected|nil)") {
//            return [(Value(amount: 0), 0), (Value(amount: 0), 1)]
//        }
//
//        /// Or if we have "trace" replace it with 0.05 (no unit)
//        if string.matchesRegex("(trace)") {
//            return [(Value(amount: 0.05), 0)]
//        }
        
        /// Invalidates strings like `20 g = 3`
        if string.matchesRegex(#"[0-9]+[ ]*[A-z]*[ ]*=[ ]*[0-9]+"#) {
            return []
        }
        
        /// Invalidates strings like `5 x 3`
        if string.matchesRegex(#"[0-9]+[ ]*x[ ]*[0-9]+"#) {
            return []
        }

        for disqualifyingText in Value.DisqualifyingTexts {
            guard !(string.lowercased().contains(disqualifyingText)) else {
                return []
            }
        }
        
        if string.hasSuffix("Omg") {
            string = string.replacingLastOccurrence(of: "Omg", with: "0mg")
        }
        if string.hasSuffix("Omcg") {
            string = string.replacingLastOccurrence(of: "Omcg", with: "0mcg")
        }

        /// If we encouner strings such as `(%5 (A pall clues )) a` — which is usually how daily values in arabic is read—don't extract values from it
//        guard !string.matchesRegex("%[0-9]+") else {
//            return []
//        }
        
        var array: [(value: Value, positionOfMatch: Int)] = []
//        print("🔢      👁 detecting values in: \(string)")

        let specialValuesArray = [
            "(?<!not detected )(?:not detected)",
            "(?:not detected)(?! not detected )",
            "nil",
            "trace"
        ]
        let specialValues = #"(\#(specialValuesArray.joined(separator: "|")))"#
        let regex = #"(?:([0-9]+[0-9.,]*[ ]*(?:\#(Value.Regex.units)|)(?:[^A-z0-9]|]|$))|\#(specialValues))"#
//        let regex = #"(?:([^A-z]|^)([0-9]+[0-9.,]*[ ]*(?:\#(Value.Regex.units)|)(?:[^A-z0-9]|]|$))|\#(specialValues))"#
        if let matches = matches(for: regex, in: string), !matches.isEmpty {
            
            for match in matches {
                guard let value = Value(fromString: match.string) else {
//                    print("🔢      👁   - '\(match.string)' @ \(match.position): ⚠️ Couldn't get value")
                    continue
                }
//                print("🔢      👁   - '\(match.string)' @ \(match.position): \(value.description)")
                array.append((value, match.position))
            }
        }
        
        array.sort(by: { $0.positionOfMatch < $1.positionOfMatch })
        return array
    }
    
    static func haveValues(in string: String) -> Bool {
        detect(in: string).count > 0
    }
}

extension Value: Equatable {
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        lhs.amount == rhs.amount &&
        lhs.unit == rhs.unit
    }
}

extension Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(amount)
        hasher.combine(unit)
    }
}

extension Value: CustomStringConvertible {
    public var description: String {
        if let unit = unit {
            return "\(amount) \(unit.description)"
        } else {
            return "\(amount)"
        }
    }
}

//TODO: Move this
struct NumberRegex {
    /// Recognizes number in a string using comma as decimal place (matches `39,3` and `2,05` but not `2,000` or `1,2,3`)
//    static let usingCommaAsDecimalPlace = #"^[0-9]*,[0-9][0-9]?([^0-9]|$)"#
    static let usingCommaAsDecimalPlace = #"^[0-9]*,[0-9][0-9]*([^0-9]|$)"#
    static let isFraction = #"^([0-9]+)\/([0-9]+)"#
}



extension Value {
    var energyAmountInCalories: Double {
        if let unit = unit, unit == .kj {
            return amount / KcalsPerKilojule
        } else {
            return amount
        }
    }
}
