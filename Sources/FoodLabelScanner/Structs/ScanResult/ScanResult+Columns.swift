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
    
    var headerTitle1: String {
        guard let headerType = headers?.header1Type else { return "Column 1" }
        return headerType.description
    }
    var headerTitle2: String {
        guard let headerType = headers?.header2Type else { return "Column 2" }
        return headerType.description
    }
}
