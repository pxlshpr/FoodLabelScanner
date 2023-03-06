import XCTest
import TabularData

@testable import FoodLabelScanner

final class CrashTests: XCTestCase {

    func testNutrientArtefactsCrash() throws {
        let string = "SALT-1-03-A"
//        let string = "protein"
        let artefacts = string.nutrientArtefacts(textId: defaultUUID)
        dump("\(artefacts)")
    }
}
