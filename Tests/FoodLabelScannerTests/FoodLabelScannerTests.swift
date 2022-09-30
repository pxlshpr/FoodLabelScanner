import XCTest
@testable import FoodLabelScanner

final class FoodLabelScannerTests: XCTestCase {
    func test() throws {
        guard let path = Bundle.module.path(forResource: "083C5BAA-2DDA-42E5-8A6C-DCD1A3E5B7E1", ofType: "jpg") else {
//            XCTFail("Couldn't get path for \"\(testCaseFileType.fileName(for: testCase))\" for testCaseFileType: \(testCaseFileType.rawValue)")
            return
        }
        XCTAssertEqual("HI", "H")
    }
}
