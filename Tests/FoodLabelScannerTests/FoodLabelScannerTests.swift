import XCTest
@testable import FoodLabelScanner

final class FoodLabelScannerTests: XCTestCase {
    func test() async throws {
        guard let path = Bundle.module.path(forResource: "083C5BAA-2DDA-42E5-8A6C-DCD1A3E5B7E1", ofType: "jpg"),
              let image = UIImage(contentsOfFile: path)
        else {
            XCTFail("Couldn't get image")
            return
        }

        let results = try await FoodLabelScanner(image: image).getScanResults()
    }
}
