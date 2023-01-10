import Foundation
import FoodLabelScanner
import VisionSugar
import UIKit

var testCases: [TestCase] {
    guard let urls = Bundle.module.urls(forResourcesWithExtension: nil, subdirectory: "Test Cases") else {
        fatalError("Couldn't get test case urls")
    }
    return urls.map { TestCase(url: $0) }
}

struct TestCase {
    let url: URL
    
    var expectedScanResult: ScanResult {
        get throws {
            let data = try dataForFile(named: "scanResult", withExtension: "json")
            return try JSONDecoder().decode(ScanResult.self, from: data)
        }
    }
    
    var expectedTextSet: RecognizedTextSet {
        get throws {
            let data = try dataForFile(named: "textSet", withExtension: "json")
            return try JSONDecoder().decode(RecognizedTextSet.self, from: data)
        }
    }
    
    var actualScanResultFromActualTextSet: ScanResult {
        get async throws {
            let textSet = try await self.actualTextSet
            return textSet.scanResult
        }
    }

    var actualScanResultFromExpectedTextSet: ScanResult {
        get async throws {
            let textSet = try self.expectedTextSet
            return textSet.scanResult
        }
    }

    var actualTextSet: RecognizedTextSet {
        get async throws {
            let image = try self.image
            return try await image.recognizedTextSet(for: .accurate, includeBarcodes: true)
        }
    }
    
    var image: UIImage {
        get throws {
            let data = try dataForFile(named: "image", withExtension: "png")
            guard let image = UIImage(data: data) else {
                throw ScanResultTestError.couldNotLoadImage
            }
            return image
        }
    }
    
    //MARK: Convenience
    
    func dataForFile(named name: String, withExtension ext: String) throws -> Data {
        guard let scanResultFile = Bundle.module.url(
            forResource: name,
            withExtension: ext,
            subdirectory: subdirectory
        ) else {
            fatalError("Couldn't get \(name).\(ext) for: \(id)")
        }
        return try Data(contentsOf: scanResultFile)
    }

    var id: String {
        url.lastPathComponent
    }
    var subdirectory: String {
        "Test Cases/\(id)"
    }
}

enum ScanResultTestError: Error {
    case couldNotLoadImage
}
