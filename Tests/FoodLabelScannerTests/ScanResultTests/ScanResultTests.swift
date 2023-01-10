import XCTest
@testable import FoodLabelScanner

import PrepDataTypes

final class ScanResultTests: XCTestCase {
    
    
    func testScanResult() async throws {
        for testCase in testCases {
            let expectedScanResult = try testCase.expectedScanResult
            print("We have \(expectedScanResult.nutrients.rows.count) nutrients to check")
            
            let expectedTextSet = try testCase.expectedTextSet
            print("We have \(expectedTextSet.texts.count) texts")
            
            let image = try testCase.image
            print("We have an image of dimensions: \(image.size)")
        }
        
    }
}
