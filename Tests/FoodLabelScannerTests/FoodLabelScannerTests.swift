import XCTest
@testable import FoodLabelScanner

final class FoodLabelScannerTests: XCTestCase {
    func test() async throws {
        guard let path = Bundle.module.path(forResource: "81942184-145C-4858-884A-8A76B9BD6498", ofType: "jpg"),
              let image = UIImage(contentsOfFile: path)
        else {
            XCTFail("Couldn't get image")
            return
        }

        let results = try await FoodLabelScanner(image: image).scan()
    }
}
