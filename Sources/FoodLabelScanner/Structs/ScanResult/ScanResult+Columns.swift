import Foundation
import VisionSugar

public extension ScanResult {
    var headerTitle1_legacy: String {
        guard let headerType = headers?.header1Type else { return "Column 1" }
        return headerType.description.replacingFirstOccurrence(of: "Per ", with: "")
    }
    var headerTitle2_legacy: String {
        guard let headerType = headers?.header2Type else { return "Column 2" }
        return headerType.description.replacingFirstOccurrence(of: "Per ", with: "")
    }
    
    var headerType1: HeaderType? { headers?.header1Type }
    var headerType2: HeaderType? { headers?.header2Type }

    var headerTitle1: String {
        guard let headerType1 else {
            if let headerType2, headerType2 != .perServing {
                return "Per Serving"
            } else {
                return "Column 1"
            }
        }
        return headerType1.description
    }
    var headerTitle2: String {
        guard let headerType2 else {
            if let headerType1, headerType1 != .perServing {
                return "Per Serving"
            } else {
                return "Column 2"
            }
        }
        return headerType2.description
    }
}
