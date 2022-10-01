import Foundation
import VisionSugar

extension RecognizedTextSet {
    
    func columnsOfValues(forAttributes attributes: [[AttributeText]]) -> [[ValuesTextColumn]] {
        var columns: [ValuesTextColumn] = []
        
        let start = CFAbsoluteTimeGetCurrent()
        
        for text in texts {

            print("1️⃣ Getting ValuesTextColumn starting from: '\(text.string)'")

            guard !text.containsServingAttribute else {
                print("1️⃣   ↪️ Contains serving attribute")
                continue
            }
            
            guard !text.containsHeaderAttribute else {
                print("1️⃣   ↪️ Contains header attribute")
                continue
            }
            
            guard let column = ValuesTextColumn(startingFrom: text, in: self) else {
                print("1️⃣   Did not get a ValuesTextColumn")
                continue
            }
            
            print("1️⃣   Got a ValuesTextColumn with: \(column.valuesTexts.count) valuesTexts")
            print("1️⃣   \(column.desc)")
            columns.append(column)
        }

        print("⏱ extracting columns took: \(CFAbsoluteTimeGetCurrent()-start)s")

        return Self.process(valuesTextColumns: columns, attributes: attributes, using: self)
    }
    
}
