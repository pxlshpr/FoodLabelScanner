import Foundation

enum Preposition: String, CaseIterable {
    case referenceIntakePer
    case referenceIntake
    case requiredDietaryIntake
    case includes
    case per
    
    var regex: String {
        switch self {
        case .per:
            return #"(^| )per( |$)"#
        case .includes:
            return #"(^| )include(s|)( |$)"#
        case .referenceIntake:
            return #"(^| )ri(\*|)( |$)"#
        case .referenceIntakePer:
            return #"(^| )ri(\*|)( (per( |$))|$)"#
        case .requiredDietaryIntake:
            return #"(^| )rd(i|a)( |$)"#
        }
    }
    
    var containsPer: Bool {
        switch self {
        case .per, .referenceIntakePer:
            return true
        default:
            return false
        }
    }
    var invalidatesPreviousValueArtefact: Bool {
        switch self {
        case .referenceIntake, .referenceIntakePer, .requiredDietaryIntake:
            return true
        default:
            return false
        }
    }
    
    init?(fromString string: String) {
        for preposition in Self.allCases {
            if string.trimmingWhitespaces.matchesRegex(preposition.regex) {
                self = preposition
                return
            }
        }
        return nil
    }
}

extension Preposition: Identifiable {
    var id: RawValue { rawValue }
}
