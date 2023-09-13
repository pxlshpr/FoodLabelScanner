import XCTest
import TabularData
import PrepShared

@testable import FoodLabelScanner

func n(_ attribute: Attribute, _ amount: Double, _ unit: FoodLabelUnit? = nil) -> ScannerNutrient {
    ScannerNutrient(attribute: attribute, value: FoodLabelValue(amount: amount, unit: unit))
}

final class String_NutrientsTests: XCTestCase {

    let testCases: [(input: String, nutrients: [ScannerNutrient])] = [
        
        ("Total Fat 3g", [n(.fat, 3, .g)]),
        ("Calories 150", [n(.energy, 150, .kcal)]),
        ("Calories 150 Calories from Fat 25", [n(.energy, 150, .kcal)]),

    ]
    
    func testStringNutrients() throws {
        for testCase in testCases {
            XCTAssertEqual(
                testCase.input.nutrients,
                testCase.nutrients,
                "for '\(testCase.input)'"
            )
        }
    }
}
