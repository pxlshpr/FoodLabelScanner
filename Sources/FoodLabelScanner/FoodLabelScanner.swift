import SwiftUI
import VisionSugar
import CoreMedia
import PrepDataTypes

public struct FoodLabelLiveScanner {
    
    var sampleBuffer: CMSampleBuffer

    public init(sampleBuffer: CMSampleBuffer) {
        self.sampleBuffer = sampleBuffer
    }
    
    public func scan() async throws -> ScanResult {
        let textSet = try await sampleBuffer.recognizedTextSet(for: .accurate, includeBarcodes: true)
        return textSet.scanResult
    }
}

extension RecognizedTextSet {
    public var scanResult: ScanResult {
        let servingObservations = servingObservations
        
        let inline = inlineObservations
        let tabular = tabularObservations
        
        var nutrientObservations: [Observation]
        if tabular.isPreferred(toInlineObservations: inline) {
            /// Add the tabular observations
            nutrientObservations = tabular
            
            /// ... and any inline observations the tabular algorithm might not have picked
            for observation in inlineObservations {
                if !tabular.contains(where: { $0.attribute == observation.attribute }) {
                    nutrientObservations.append(observation)
                }
            }
        } else {
            nutrientObservations = inline
        }
        var headerObservations = tabularHeaderObservations(for: tabular)
        
        headerObservations.populateMissingHeaderObservations(from: self)
        
        return ScanResult(
            serving: servingObservations.serving,
            headers: headerObservations.headers,
            nutrients: nutrientObservations.nutrients,
            texts: texts,
            barcodes: barcodes
        )
    }
}

public struct FoodLabelScanner {
    
    var image: UIImage
    var contentSize: CGSize
    
    public init(image: UIImage, contentSize: CGSize? = nil) {
        self.image = image
        self.contentSize = contentSize ?? image.size
    }
    
    public func scan() async throws -> ScanResult {
        let textSet = try await image.recognizedTextSet(for: .accurate, includeBarcodes: true)
        return textSet.scanResult
    }
    
    /**
     - [ ]  Once the `inlineTask` is finished
         - [x]  If we deem the results to be `complete` (notice we’re not using valid any longer)
             - [x]  Return the `inlineResult`
         - [ ]  If we deem the results to not be `complete`
             - [ ]  Now see if the `tabularResult` is preferred to the `inlineResult`
             - [ ]  If it is
                 - [ ]  Return the `tabularREsult`
             - [ ]  Otherwise
                 - [ ]  Otherwise, return the `inlineResult`
     */
    func getNutrientObservations(from textSet: RecognizedTextSet) -> [Observation] {
        
        let inline = textSet.inlineObservations
        
//        guard !inline.isCompleteInlineSet else {
//            // print("🥕 using inline as its complete")
//            return inline
//        }
//
//        // print("🥕 not using inline yet as the energy/macro values aren't present or don't equate")

        let tabular = textSet.tabularObservations
//        // print("🥕 using tabular indiscriminately")
//        return tabular
        
        guard tabular.isPreferred(toInlineObservations: inline) else {
            // print("🥕 using inline (\(inline.nutrientsCount) nutrients) as its preferred to tabular (\(tabular.nutrientsCount) nutrients)")
            return inline
        }
        // print("🥕 using tabular (\(tabular.nutrientsCount) nutrients) as its preferred to inline (\(inline.nutrientsCount) nutrients)")
        return tabular
    }
}

extension Array where Element == Observation {
    
    var containingBothValuesCount: Int {
        filter({ $0.valueText2 != nil }).count
    }
    
    var numberOfObservationsUsingOtherAttributeTextsAsValueTexts: Int {
        var count = 0
        for observation in self {
            guard let valueTextId = observation.valueText1?.text.id else {
                continue
            }
            /// Count observations that are using texts for their value1 that are used as the attribute text in other observations
            if self.contains(where: {
                $0.attribute != observation.attribute
                && $0.attributeText.text.id == valueTextId
            }) {
                count += 1
            }
        }
        return count
    }
    
    /**
    Determining if `tabularResult` is preferred to `inlineResult`
     */
    func isPreferred(toInlineObservations inlineObservations: [Observation]) -> Bool {

        /// First, check if inline by seeing how many valueText1 of observations (ie in the first column), are also in the attribute texts (of any observation)
        let count = numberOfObservationsUsingOtherAttributeTextsAsValueTexts
        
        return isPreferredUsingCount(toInlineObservations: inlineObservations)
    }
    
    /// Rudimentary legacy version that was incorrectly labelling single columned inline labels as tabular
    func isPreferredUsingCount(toInlineObservations inlineObservations: [Observation]) -> Bool {
        let inlineCount = Double(inlineObservations.nutrientsCount)
        let tabularCount = Double(self.nutrientsCount)
        if (inlineCount / 2.0) < tabularCount {
            return true
        } else {
            return false
        }
    }
    
    var nutrientsCount: Int {
        filter({ $0.attribute.isNutrientAttribute }).count
    }
    
    /**
     ## Determining `inlineResult` completion

     - [ ]  The `inlineResult` is deemed `complete` if
         - [x]  The energy and macro values are available and
             - [x]  They fit the energy equation within a certain acceptable threshold
         - [ ] Bring these further heuristics in if needed
            - [ ]  Have values for each of the *nutrient* attributes detected
                - [ ]  This means we need to store the set of detected attributes with each set of observations
            - [ ]  Any set of constituent observations present (like all fats; saturated, trans, etc.) have a total value that’s less than the value of their parent observations (total fats in this case) , etc)
     */
    var isCompleteInlineSet: Bool {
        guard energyAndMacrosArePresentAndEquateInFirstColumn else {
            return false
        }
        return true
    }

    
    var energyAndMacrosArePresentAndEquateInFirstColumn: Bool {
        energyAndMacrosArePresentAndEquate(inColumn: 1)
    }
    
    func energyAndMacrosArePresentAndEquate(inColumn column: Int) -> Bool {
        guard let energyInKcal = value(in: column, for: .energy)?.energyAmountInCalories else {
            return false
        }
        guard let fat = amount(in: column, for: .fat) else {
            return false
        }
        guard let carb = amount(in: column, for: .carbohydrate) else {
            return false
        }
        guard let protein = amount(in: column, for: .protein) else {
            return false
        }
        
        let isValid = macroAndEnergyValuesAreValid(
            energyInKcal: energyInKcal,
            carb: carb,
            fat: fat,
            protein: protein,
            threshold: ErrorPercentageThresholdEnergyCalculation /// tweak this threshold if needed
        )
        return isValid
    }    
}
