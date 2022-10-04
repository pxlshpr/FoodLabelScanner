import XCTest
@testable import FoodLabelScanner

import PrepUnits

final class FoodLabelScannerTests: XCTestCase {
    func test() async throws {
        guard let path = Bundle.module.path(forResource: "label10", ofType: "jpg"),
              let image = UIImage(contentsOfFile: path)
        else {
            XCTFail("Couldn't get image")
            return
        }

        let string = "Serving Size 1/2 cup (88g)"
        let values = FoodLabelValue.detect(in: string)
        print("Got: \(values)")
        let results = try await FoodLabelScanner(image: image).scan()
    }
}
