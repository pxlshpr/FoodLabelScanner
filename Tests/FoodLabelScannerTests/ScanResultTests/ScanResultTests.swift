import XCTest
@testable import FoodLabelScanner

import PrepDataTypes

final class ScanResultTests: XCTestCase {
    
        
    func testScanResultFast() async throws {
        try await testScanResult(mode: .fast)
    }

    func _testScanResultComprehensive() async throws {
        try await testScanResult(mode: .comprehensive)
    }

    func testScanResult(mode: TestMode) async throws {
        print("👨🏽‍🔬 Testing ScanResult (\(mode.rawValue))")
        print("👨🏽‍🔬 〰〰〰〰〰〰〰〰〰〰〰〰〰〰〰")
        self.continueAfterFailure = true
        for testCase in testCases {
            print("👨🏽‍🔬 Testing \(testCase.id)")
            try await testScanResultTestCase(testCase, mode: mode)
        }
    }

    func testScanResultTestCase(_ testCase: TestCase, mode: TestMode) async throws {
        switch mode {
        case .fast:
            try await testScanResultTestCaseFast(testCase)
        case .comprehensive:
            try await testScanResultTestCaseComprehensive(testCase)
        }
    }
    
    func testScanResultTestCaseFast(_ testCase: TestCase) async throws {
        let actual = try await testCase.actualScanResultFromExpectedTextSet
        let expected = try testCase.expectedScanResult
        try assertEqual(actual: actual, expected: expected, id: testCase.id)
    }
    
    func testScanResultTestCaseComprehensive(_ testCase: TestCase) async throws {
    }
}

extension ScanResultTests {
    func assertEqual(actual: ScanResult, expected: ScanResult, id: String) throws {
        /// Servings
        try assertServingsEqual(actual: actual.serving, expected: expected.serving, id: id)
        
        /// Headers
        try assertHeaderTextsEqual(actual: actual.headers?.headerText1, expected: expected.headers?.headerText1, headerNumber: 1, id: id)
        try assertHeaderTextsEqual(actual: actual.headers?.headerText2, expected: expected.headers?.headerText2, headerNumber: 2, id: id)
        
        /// Nutrient rows
        try assertNutrientRowsEqual(actual: actual, expected: expected, id: id)
    }
    
    //MARK: - Servings
    func assertServingsEqual(actual: ScanResult.Serving?, expected: ScanResult.Serving?, id: String) throws {
        
        print("  👨🏽‍🔬 Asserting that Serving's are equal")
        guard let expected else {
            XCTAssertNil(actual, "\(id) – serving extra")
            print("    👨🏽‍🔬 ✓ [nil]")
            return
        }
        let actual = try XCTUnwrap(actual, "\(id) – serving missing")
        
        XCTAssertEqual(actual.amount, expected.amount, "\(id) – serving.amount ≠")
        XCTAssertEqual(actual.unit, expected.unit, "\(id) – serving.unit ≠")
        XCTAssertEqual(actual.unitName, expected.unitName, "\(id) – serving.unitName ≠")
        print("    👨🏽‍🔬 ✓ amount [\(expected.amount?.cleanAmount ?? "nil")]")
        print("    👨🏽‍🔬 ✓ unit [\(expected.unit?.description ?? "nil")]")
        print("    👨🏽‍🔬 ✓ unitName [\(expected.unitName ?? "nil")]")

        try assertServingEquivalentSizesAreEqual(
            actual: actual.equivalentSize,
            expected: expected.equivalentSize,
            id: id
        )
        try assertServingPerContainersAreEqual(
            actual: actual.perContainer,
            expected: expected.perContainer,
            id: id
        )
    }
    
    func assertServingEquivalentSizesAreEqual(actual: ScanResult.Serving.EquivalentSize?, expected: ScanResult.Serving.EquivalentSize?, id: String) throws {

        print("      👨🏽‍🔬 Asserting that Serving Equivalent Sizes are equal")
        guard let expected else {
            XCTAssertNil(actual, "\(id) – serving.equivalentSize extra")
            print("        👨🏽‍🔬 ✓ [nil]")
            return
        }
        let actual = try XCTUnwrap(actual, "\(id) – serving.equivalentSize missing")

        XCTAssertEqual(actual.amount, expected.amount, "\(id) – serving.equivalentSize.amount")
        XCTAssertEqual(actual.unit, expected.unit, "\(id) – serving.equivalentSize.unit")
        XCTAssertEqual(actual.unitName, expected.unitName, "\(id) – serving.equivalentSize.unitName")
        print("        👨🏽‍🔬 ✓ amount [\(expected.amount.cleanAmount)]")
        print("        👨🏽‍🔬 ✓ unit [\(expected.unit?.description ?? "nil")]")
        print("        👨🏽‍🔬 ✓ unitName [\(expected.unitName ?? "nil")]")
    }

    func assertServingPerContainersAreEqual(actual: ScanResult.Serving.PerContainer?, expected: ScanResult.Serving.PerContainer?, id: String) throws {

        print("      👨🏽‍🔬 Asserting that Serving Per Containers are equal")
        guard let expected else {
            XCTAssertNil(actual, "\(id) – serving.perContainer extra")
            print("        👨🏽‍🔬 ✓ [nil]")
            return
        }
        let actual = try XCTUnwrap(actual, "\(id) – serving.perContainer missing")

        XCTAssertEqual(actual.amount, expected.amount, "\(id) – serving.perContainer.amount")
        XCTAssertEqual(actual.name, expected.name, "\(id) – serving.perContainer.name")
        print("        👨🏽‍🔬 ✓ amount [\(expected.amount.cleanAmount)]")
        print("        👨🏽‍🔬 ✓ unit [\(expected.name ?? "nil")]")
    }
    
    //MARK: - Headers
    
    func assertHeaderTextsEqual(actual: HeaderText?, expected: HeaderText?, headerNumber i: Int, id: String) throws {
        print("  👨🏽‍🔬 Asserting that Header \(i)'s are equal")
        guard let expected else {
            XCTAssertNil(actual, "\(id) – headerText\(i) extra")
            print("    👨🏽‍🔬 ✓ [nil]")
            return
        }
        let actual = try XCTUnwrap(actual, "\(id) – headerText\(i) missing")
        
        XCTAssertEqual(actual.type, expected.type, "\(id) – headerText\(i).type ≠")
        print("    👨🏽‍🔬 ✓ [\(expected.type.description)]")

        try assertHeaderServingsEqual(
            actual: actual.serving,
            expected: expected.serving,
            headerNumber: i,
            id: id
        )
    }
    
    func assertHeaderServingsEqual(actual: HeaderText.Serving?, expected: HeaderText.Serving?, headerNumber i: Int, id: String) throws {
        print("      👨🏽‍🔬 Asserting that Header \(i) Servings are equal")
        guard let expected else {
            XCTAssertNil(actual, "\(id) – headerText\(i).serving extra")
            print("        👨🏽‍🔬 ✓ [nil]")
            return
        }
        let actual = try XCTUnwrap(actual, "\(id) – headerText\(i).serving missing")
        XCTAssertEqual(actual.amount, expected.amount, "\(id) – headerText\(i).serving.amount")
        XCTAssertEqual(actual.unit, expected.unit, "\(id) – headerText\(i).serving.unit")
        XCTAssertEqual(actual.unitName, expected.unitName, "\(id) – headerText\(i).serving.unitName")
        print("        👨🏽‍🔬 ✓ amount [\(expected.amount?.cleanAmount ?? "nil")]")
        print("        👨🏽‍🔬 ✓ unit [\(expected.unit?.description ?? "nil")]")
        print("        👨🏽‍🔬 ✓ unitName [\(expected.unitName ?? "nil")]")

        try assertHeaderServingEquivalentSizesEqual(
            actual: actual.equivalentSize,
            expected: expected.equivalentSize,
            headerNumber: i,
            id: id
        )
    }
    
    func assertHeaderServingEquivalentSizesEqual(actual: HeaderText.Serving.EquivalentSize?, expected: HeaderText.Serving.EquivalentSize?, headerNumber i: Int, id: String) throws {
        print("          👨🏽‍🔬 Asserting that Header \(i) Serving Equivalent Sizes are equal")
        guard let expected else {
            XCTAssertNil(actual, "\(id) – headerText\(i).serving.equivalentSize extra")
            print("            👨🏽‍🔬 ✓ [nil]")
            return
        }
        let actual = try XCTUnwrap(actual, "\(id) – headerText\(i).serving.equivalentSize missing")

        XCTAssertEqual(actual.amount, expected.amount, "\(id) – headerText\(i).serving.equivalentSize.amount")
        XCTAssertEqual(actual.unit, expected.unit, "\(id) – headerText\(i).serving.equivalentSize.unit")
        XCTAssertEqual(actual.unitName, expected.unitName, "\(id) – headerText\(i).serving.equivalentSize.unitName")
        print("            👨🏽‍🔬 ✓ amount [\(expected.amount.cleanAmount)]")
        print("            👨🏽‍🔬 ✓ unit [\(expected.unit?.description ?? "nil")]")
        print("            👨🏽‍🔬 ✓ unitName [\(expected.unitName ?? "nil")]")
    }
    
    //MARK: - Nutrients

    func assertNutrientRowsEqual(actual: ScanResult, expected: ScanResult, id: String) throws {
        print("  👨🏽‍🔬 Asserting that Nutrients are equal")
        for expectedRow in expected.nutrients.rows {
            let actualRow = actual.nutrients.rows.row(forAttribute: expectedRow.attribute)
            XCTAssertNotNil(actualRow, "\(id) – \(expectedRow.attribute) missing")
            
            guard let actualRow else { continue }
            XCTAssertEqual(actualRow.value1, expectedRow.value1, "\(id) – \(expectedRow.attribute) value1 ≠")
            XCTAssertEqual(actualRow.value2, expectedRow.value2, "\(id) – \(expectedRow.attribute) value2 ≠")
            print("    👨🏽‍🔬 ✓ \(expectedRow.attribute.description) [\(expectedRow.valuesDescription)]")
        }
        
        for actualRow in actual.nutrients.rows {
            XCTAssertTrue(
                expected.nutrients.rows.contains(attribute: actualRow.attribute),
                "\(id) – \(actualRow.attribute) extra"
            )
        }
    }
}

extension ScanResult.Serving: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unitText {
            unitString = " \(unitText.unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitNameText {
            unitNameString = " \(unitNameText.string)"
        } else {
            unitNameString = ""
        }
        let amountString: String
        if let amountText {
            amountString = amountText.double.cleanAmount
        } else {
            amountString = ""
        }
        return "\(amountString)\(unitString)\(unitNameString)"
    }
}

extension ScanResult.Serving.EquivalentSize: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unitText {
            unitString = " \(unitText.unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitNameText {
            unitNameString = " \(unitNameText.string)"
        } else {
            unitNameString = ""
        }
        return "\(amount.cleanAmount)\(unitString)\(unitNameString)"
    }
}

extension ScanResult.Serving.PerContainer: CustomStringConvertible {
    public var description: String {
        let nameString: String
        if let nameText {
            nameString = " \(nameText.string)"
        } else {
            nameString = ""
        }
        return "\(amountText.double.cleanAmount)\(nameString)"
    }
}

extension HeaderText.Serving: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unit {
            unitString = " \(unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitName {
            unitNameString = " \(unitName)"
        } else {
            unitNameString = ""
        }
        let amountString: String
        if let amount {
            amountString = amount.cleanAmount
        } else {
            amountString = ""
        }
        return "\(amountString)\(unitString)\(unitNameString)"
    }
}

extension HeaderText.Serving.EquivalentSize: CustomStringConvertible {
    public var description: String {
        let unitString: String
        if let unit {
            unitString = " \(unit.description)"
        } else {
            unitString = ""
        }
        let unitNameString: String
        if let unitName {
            unitNameString = " \(unitName)"
        } else {
            unitNameString = ""
        }
        return "\(amount.cleanAmount)\(unitString)\(unitNameString)"
    }
}

extension Array where Element == ScanResult.Nutrients.Row {
    func contains(attribute: Attribute) -> Bool {
        contains(where: { $0.attribute == attribute })
    }
    
    func row(forAttribute attribute: Attribute) -> ScanResult.Nutrients.Row? {
        first(where: { $0.attribute == attribute })
    }
}


enum TestMode: String {
    /// Uses the `RecognizedTextSet` included with the test case, skipping the steps of loading the image and recognizing its texts.
    /// This would however, not pick up potential changes in the text-recognition step (which may behind the scenes, and also differ between device and simulator)
    case fast
    
    /// Starts with the image, recognizes its texts and then compares the actual and expected scan results.
    /// Also surfaces any changes between the actual and expected `RecognizedTextSet`.
    case comprehensive
}
