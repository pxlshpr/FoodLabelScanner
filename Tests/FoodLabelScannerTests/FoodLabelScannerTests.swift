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
        print("🧬 vitaminA was: \(results.value(for: .vitaminA))")
        print("🧬 vitaminC was: \(results.value(for: .vitaminC))")
        print("🧬 calcium was: \(results.value(for: .calcium))")
        print("🧬 iron was: \(results.value(for: .iron))")
    }
}

extension ScanResult {
    func value(for attribute: Attribute) -> FoodLabelValue? {
        value1(for: attribute)
    }

    func value1(for attribute: Attribute) -> FoodLabelValue? {
        nutrients.rows.first(where: { $0.attribute == attribute })?.value1
    }

    func value2(for attribute: Attribute) -> FoodLabelValue? {
        nutrients.rows.first(where: { $0.attribute == attribute })?.value2
    }
}
