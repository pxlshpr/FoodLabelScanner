import XCTest
import TabularData

@testable import FoodLabelScanner

final class Playground: XCTestCase {

    func testNutrientArtefactsCrash() throws {
        /// This caused a crash (infinite recursion) before implemented fixes in it.
//        let string = "SALT-1-03-A"
//        let artefacts = string.nutrientArtefacts(textId: defaultUUID)
//        dump("\(artefacts)")
    }
}
