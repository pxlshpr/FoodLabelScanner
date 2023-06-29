import XCTest
import TabularData

import FoodDataTypes

@testable import FoodLabelScanner

final class String_AttributeTests: XCTestCase {

    let testCases: [(input: String, attribute: Attribute?)] = [
        
        ("fat", .fat),
        ("fat 25", .fat),

        /// Fails cases like "Calories from fat"
        ("from fat 25", nil),
    ]
    
    func testStringAttributes() throws {
        for testCase in testCases {
            XCTAssertEqual(
                Attribute(fromString: testCase.input),
                testCase.attribute,
                "for '\(testCase.input)'"
            )
        }
    }
}
