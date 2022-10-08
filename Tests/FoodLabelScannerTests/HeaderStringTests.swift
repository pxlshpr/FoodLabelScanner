import XCTest
import TabularData

@testable import FoodLabelScanner

//TODO: Remove this
final class HeaderStringTests: XCTestCase {

    let testCases: [(input: String, header: HeaderString?)] = [
        /// per100g
        ("Per 100 g", .per100),
        ("Per 100g", .per100),
        ("100g", .per100),
        ("SERVE PER 100g", .per100),
        ("Pour 100 ml", .per100),

        /// perServing(nil)
        ("Serving", .perServing(serving: nil)),
        ("Per serving", .perServing(serving: nil)),
        ("Per Serving", .perServing(serving: nil)),
        ("Par Portion", .perServing(serving: nil)),
        ("PER SERVE", .perServing(serving: nil)),
        ("Amount per serving", .perServing(serving: nil)),
        ("Amount/Serving", .perServing(serving: nil)),
        ("%DV* Amount/Serving", .perServing(serving: nil)),
        ("trition Amount Per Serving %Daily Value* Amount Per Serving", .perServing(serving: nil)),
        ("Nutrition Facts Amount/Serving %DV* Amount/Serving", .perServing(serving: nil)),

        /// perServing
        ("Per 1 pot", .perServing(serving: "1 pot")),

        /// perServingAnd100g
        ("Per Serving Per 100 ml", .perServingAnd100(serving: nil)),
        ("Par Portion Pour 100 ml", .perServingAnd100(serving: nil)),
        ("Per 40g Per 100g Values®", .perServingAnd100(serving: "40g")),
        
        /// per100gAndPerServing
        ("PER 100g 74g (2 tubes)", .per100AndPerServing(serving: "74g (2 tubes)")),
        
        /// **Deprecated Tests**
//        ("INFORMATION Per 120g Per 100g", .perServingAnd100(serving: "120g")),
//        ("Nutritional Values (Typical) Per 100 g Per serving (125 g)", .per100AndPerServing(serving: "serving (125 g)")),
    ]
    
    func testColumnHeaders() throws {
        for testCase in testCases {
            XCTAssertEqual(
                HeaderString(string: testCase.input),
                testCase.header,
                "for '\(testCase.input)'"
            )
        }
    }
}
