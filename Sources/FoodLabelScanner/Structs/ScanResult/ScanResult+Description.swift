import Foundation

public extension ScanResult {
    var summaryDescription: String {
        summaryDescription(withEmojiPrefix: "")
    }
    
    func summaryDescription(withEmojiPrefix emoji: String) -> String {
"""
\(nutrientsDescription(withEmojiPrefix: emoji))
\(emoji) -------------------
"""
    }
    
    func nutrientsDescription(withEmojiPrefix emoji: String) -> String {
        nutrients.rows.reduce("") { partialResult, row in
            partialResult + "\(emoji) " + row.description + "\n"
        }
    }
}

extension ScanResult.Nutrients.Row {
    /**
     "Energy: 4 kcal, 250 kcal"
     "Energy: nil"
     "Energy: nil, 4 kcal"
     "Energy: 4 kcal"
     */
    var description: String {
        "\(attribute.description): \(valuesDescription)"
    }
    
    var valuesDescription: String {
        if let value1 {
            if let value2 {
                return "\(value1.description), \(value2.description)"
            } else {
                return value1.description
            }
        } else if let value2 {
            return "nil, \(value2.description)"
        } else {
            return "nil"
        }
    }
}

