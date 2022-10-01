import Foundation
import VisionSugar

let defaultUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
let defaultText = RecognizedText(id: defaultUUID, rectString: "", boundingBoxString: "", candidates: [])

let KcalsPerGramOfFat = 8.75428571
let KcalsPerGramOfCarb = 4.0
let KcalsPerGramOfProtein = 4.0
let KcalsPerKilojule = 4.184

let ErrorPercentageThresholdEnergyCalculation = 7.5
