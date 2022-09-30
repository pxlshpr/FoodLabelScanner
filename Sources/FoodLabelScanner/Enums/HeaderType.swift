import Foundation

public enum HeaderType: String, CaseIterable, Codable {
    case per100g
    case per100ml
    case perServing
}

extension HeaderType {
    init(per100String string: String) {
        if string.matchesRegex(#"100[ ]*ml"#) {
            self = .per100ml
        } else {
            self = .per100g
        }
    }
    
    init?(string: String) {
        if string.matchesRegex(Attribute.Regex.amountPerServing) {
            self = .perServing
            return
        }
        
        if string.matchesRegex(Attribute.Regex.amountPer100g) {
            self = .per100g
            return
        }
        
        if string.matchesRegex(Attribute.Regex.amountPer100ml) {
            self = .per100ml
            return
        }
        return nil
    }
}

extension HeaderType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .per100g:
            return "Per 100g"
        case .per100ml:
            return "Per 100ml"
        case .perServing:
            return "Per Serving"
        }
    }
    
    public var stringFieldName: String {
        switch self {
        case .perServing:
            return "Serving"
        default:
            return ""
        }
    }
}
