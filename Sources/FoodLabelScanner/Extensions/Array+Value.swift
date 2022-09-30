import Foundation

extension Array where Element == Value {
    var containsValueWithEnergyUnit: Bool {
        contains(where: { $0.hasEnergyUnit } )
    }
    
    var containsValueWithNutrientUnit: Bool {
        contains(where: { $0.hasNutrientUnit })
    }
    
    var containsReferenceEnergyValue: Bool {
        contains { $0.isReferenceEnergyValue }
    }
    var containsValueWithKjUnit: Bool {
        contains(where: { $0.unit == .kj } )
    }
    var containingUnit: [Value] {
        filter { $0.unit != nil }
    }
    var singleValueAfterRemovingPercentageValues: Value? {
        let nonPercentageValues = filter { $0.unit != .p }
        return nonPercentageValues.count == 1 ? nonPercentageValues[0] : nil
    }
    var containsValueWithKcalUnit: Bool {
        contains(where: { $0.unit == .kcal } )
    }
}
