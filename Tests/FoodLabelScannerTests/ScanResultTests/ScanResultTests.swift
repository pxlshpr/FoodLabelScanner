import XCTest
@testable import FoodLabelScanner

import PrepDataTypes

final class ScanResultTests: XCTestCase {
    
    func testScanResult() async throws {
//        if let path = Bundle.module.path(forResource: "6676DCB9-1769-4070-B831-CC40B428AF72", ofType: "jpg")
//        let image = UIImage(contentsOfFile: path)
        
        
        /// Get all our test cases
        ///
                
    }
}

func prepareTestCases() throws {
    let filePath = Bundle.module.url(forResource: "NutritionClassifier-Test_Data", withExtension: "zip")!
    let testDataUrl = URL.documents.appendingPathComponent("Test Data", isDirectory: true)
    
    /// Remove directory and create it again
    try FileManager.default.removeItem(at: testDataUrl)
    try FileManager.default.createDirectory(at: testDataUrl, withIntermediateDirectories: true)

    /// Unzip Test Data contents
    try Zip.unzipFile(filePath, destination: testDataUrl, overwrite: true, password: nil)
}
