import Foundation
import VisionSugar

let defaultUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
let defaultText = RecognizedText(id: defaultUUID, rectString: "", boundingBoxString: "", candidates: [])

public let KcalsPerGramOfFat = 8.75428571
public let KcalsPerGramOfCarb = 4.0
public let KcalsPerGramOfProtein = 4.0
public let KcalsPerKilojule = 4.184

public let ErrorPercentageThresholdEnergyCalculation = 7.5
