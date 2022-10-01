import Foundation

extension Double {
    init?(fromString string: String) {

        var string = string
            .replacingOccurrences(of: ":", with: ".") /// Fix Vision errors of misreading decimal places as `:`
        
        if string.matchesRegex(NumberRegex.usingCommaAsDecimalPlace) {
            string = string.replacingOccurrences(of: ",", with: ".")
        } else {
            /// It's been used as a thousand separator in that case
            string = string.replacingOccurrences(of: ",", with: "")
        }
        
        let groups = string.capturedGroups(using: NumberRegex.isFraction)
        if groups.count == 2,
            let numerator = Double(groups[0]),
            let denominator = Double(groups[1]),
            denominator != 0
        {
            self = numerator/denominator
            return
        }
        
        /// Now replace fraction characters with their `Double` counterparts
        if let amount = UnicodeFractions[string] {
            self = amount
            return
        }
        
        if string.hasSuffix("/") {
            string = string.replacingLastOccurrence(of: "/", with: "")
        }
        
        guard let amount = Double(string) else {
            return nil
        }
        self = amount
    }
}

let UnicodeFractions: [String: Double] = [
    "½": 1.0/2.0,
    "⅓": 1.0/3.0,
    "¼": 1.0/4.0,
    "⅕": 1.0/5.0,
    "⅙": 1.0/6.0,
    "⅐": 1.0/7.0,
    "⅛": 1.0/8.0,
    "⅑": 1.0/9.0,
    "⅒": 1.0/10.0,
    "⅔": 2.0/3.0,
    "⅖": 2.0/5.0,
    "¾": 3.0/4.0,
    "⅗": 3.0/5.0,
    "⅜": 3.0/8.0,
    "⅘": 4.0/5.0,
    "⅚": 5.0/6.0,
    "⅞": 7.0/8.0,
]
