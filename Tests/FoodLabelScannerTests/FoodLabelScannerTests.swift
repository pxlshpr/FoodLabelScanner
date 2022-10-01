import XCTest
@testable import FoodLabelScanner

final class FoodLabelScannerTests: XCTestCase {
    func test() async throws {
        guard let path = Bundle.module.path(forResource: "label10", ofType: "jpg"),
              let image = UIImage(contentsOfFile: path)
        else {
            XCTFail("Couldn't get image")
            return
        }

        let results = try await FoodLabelScanner(image: image).scan()
    }
}
