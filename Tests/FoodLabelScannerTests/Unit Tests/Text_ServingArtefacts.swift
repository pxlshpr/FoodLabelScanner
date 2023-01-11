import XCTest
import TabularData
import PrepDataTypes
import VisionSugar

@testable import FoodLabelScanner

final class Text_ServingArtefacts: XCTestCase {
    
    static let testCases: [
        (text: RecognizedText, servingArtefacts: [ServingArtefact])
    ] = [
        (pouch, [
            ServingArtefact(double: 1, text: defaultText),
            ServingArtefact(string: "pouch (", text: defaultText),
            ServingArtefact(double: 74, text: defaultText),
            ServingArtefact(unit: .g, text: defaultText)
        ]),
        (pouch2, [
            ServingArtefact(double: 1, text: defaultText),
            ServingArtefact(string: "pouch (", text: defaultText),
            ServingArtefact(double: 74, text: defaultText),
            ServingArtefact(unit: .g, text: defaultText)
        ])
    ]
    
    func testStringAttributes() throws {
        for testCase in Self.testCases {
            let actual = testCase.text.servingArtefacts
            let expected = testCase.servingArtefacts
            
            XCTAssertEqual(actual.indices, expected.indices)
            for i in actual.indices {
                let actualArtefact = actual[i]
                let expectedArtefact = expected[i]
                XCTAssertTrue(
                    actualArtefact.matches(expectedArtefact),
                    "Actual artefact: \(actualArtefact) does not match expected: \(expectedArtefact)"
                )
            }
        }
    }
    
    static let pouch = RecognizedText(
        id: defaultUUID,
        rectString: "",
        boundingBoxString: nil,
        candidates: [
            "1 Pouch (749)",
            "1-Pouch (749)",
            "1 Pouch (74g)",
            "1-Pouch (74g)",
            "1Pouch (749)"
        ]
    )

    static let pouch2 = RecognizedText(
        id: defaultUUID,
        rectString: "",
        boundingBoxString: nil,
        candidates: [
            "1 Pouch (74 9)",
            "1-Pouch (74 9)",
            "1 Pouch (74 g)",
            "1-Pouch (74 g)",
            "1Pouch (74 9)"
        ]
    )

}

extension ServingArtefact {
    func matches(_ other: ServingArtefact) -> Bool {
        if let attribute {
            guard let otherAttribute = other.attribute,
                  attribute == otherAttribute
            else {
                return false
            }
        }
        if let double {
            guard let otherDouble = other.double,
                  double == otherDouble
            else {
                return false
            }
        }
        if let string {
            guard let otherString = other.string,
                  string == otherString
            else {
                return false
            }
        }
        if let unit {
            guard let otherUnit = other.unit,
                  unit == otherUnit
            else {
                return false
            }
        }
        return true
    }
}
