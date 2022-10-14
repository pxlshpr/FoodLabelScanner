import XCTest
@testable import FoodLabelScanner

import PrepUnits

final class FoodLabelScannerTests: XCTestCase {
    func test() async throws {
        guard let path = Bundle.module.path(forResource: "philly_cheese", ofType: "jpg"),
              let image = UIImage(contentsOfFile: path)
        else {
            XCTFail("Couldn't get image")
            return
        }

        let scanResult = try await FoodLabelScanner(image: image).scan()
        print(scanResult.summaryDescription(withEmojiPrefix: "🧬"))
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
