import SwiftUI
import VisionSugar
import CoreMedia
import PrepUnits

public struct FoodLabelScanner {
    
    var image: UIImage
    var contentSize: CGSize
    
    public init(image: UIImage, contentSize: CGSize? = nil) {
        self.image = image
        self.contentSize = contentSize ?? image.size
    }
    
    public func scan() async throws -> ScanResult {
        let textSet = try await image.recognizedTextSet(for: .accurate, inContentSize: contentSize)
        
        let nutrientObservations = getNutrientObservations(from: textSet)
        let servingObservations = textSet.servingObservations
        return ScanResult(
            serving: servingObservations.serving,
            nutrients: nutrientObservations.nutrients,
            texts: textSet.texts
        )
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
        
        guard !inline.isCompleteInlineSet else {
            print("🥕 using inline as its complete")
            return inline
        }

        print("🥕 not using inline yet as the energy/macro values aren't present or don't equate")

        let tabular = textSet.tabularObservations
//        print("🥕 using tabular indiscriminately")
//        return tabular
        
        guard tabular.isPreferred(to: inline) else {
            print("🥕 using inline (\(inline.nutrientsCount) nutrients) as its preferred to tabular (\(tabular.nutrientsCount) nutrients)")
            return inline
        }
        print("🥕 using tabular (\(tabular.nutrientsCount) nutrients) as its preferred to inline (\(inline.nutrientsCount) nutrients)")
        return tabular
    }
}

extension Array where Element == Observation {
    
    /**
     ## Determining if `tabularResult` is preferred to `inlineResult`

     - [x]  The `tabularResult` is deemed `preferred` if
         - [x]  It has the same or more number of observations than the `inlineResult`
     */
    func isPreferred(to observations: [Observation]) -> Bool {
        self.nutrientsCount >= observations.nutrientsCount
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
