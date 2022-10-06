import XCTest
@testable import FoodLabelScanner

import PrepUnits

final class FoodLabelScannerTests: XCTestCase {
    func test() async throws {
        guard let path = Bundle.module.path(forResource: "toblerone", ofType: "jpg"),
              let image = UIImage(contentsOfFile: path)
        else {
            XCTFail("Couldn't get image")
            return
        }

        let string = "Serving Size 1/2 cup (88g)"
        let values = FoodLabelValue.detect(in: string)
        print("Got: \(values)")
        let results = try await FoodLabelScanner(image: image).scan()
        print("🧬 Protein was: \(results.protein)")
    }
}

extension ScanResult {
    var protein: FoodLabelValue? {
        protein1
    }
    
    var protein1: FoodLabelValue? {
        nutrients.rows.first(where: { $0.attribute == .protein })?.value1
    }

    var protein2: FoodLabelValue? {
        nutrients.rows.first(where: { $0.attribute == .protein })?.value2
    }
}
