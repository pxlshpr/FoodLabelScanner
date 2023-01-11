import Foundation

//TODO: Rename this, particularly to remove the `Text` suffix
public enum HeaderString {
    case per100
    case perServing(serving: String?)
    case per100AndPerServing(serving: String?)
    case perServingAnd100(serving: String?)

    init?(string: String) {
        if string.matchesRegex(Regex.per100WithNutritionalValuesPrefix) {
            self = .per100
        }
        else if string.matchesRegex(Regex.per100_2) {
            self = .per100
        }
        else if let size = string.firstCapturedGroup(using: Regex.perServingWithSize) {
            self = .perServing(serving: size)
        }
        else if string.matchesRegex(Regex.perServingWithSize3) {
            self = .perServing(serving: string)
        }
        else if let size = string.firstCapturedGroup(using: Regex.per100gAndPerServing) {
            self = .per100AndPerServing(serving: size)
        }
        else if let size = string.firstCapturedGroup(using: Regex.perServingAndPer100g)?.trimmingWhitespaces {
            if size.matchesRegex(#"(serv(ing|e)|portion)"#) {
                self = .perServingAnd100(serving: nil)
            } else {
                self = .perServingAnd100(serving: size)
            }
        }
        else if string.matchesRegex(Regex.perServing) {
            self = .perServing(serving: nil)
        }
        else if string.lowercased() == "serving" {
            self = .perServing(serving: nil)
        }
        else {
            return nil
        }
    }
    
    var serving: String? {
        switch self {
        case .perServing(let serving), .per100AndPerServing(let serving), .perServingAnd100(let serving):
            return serving
        default:
            return nil
        }
    }
}

struct Rx {
    static let fractions = "½⅓¼⅕⅙⅐⅛⅑⅒⅔⅖¾⅗⅜⅘⅚⅞"
    static let numerals = "0-9"
    static let numbers = "\(numerals)\(fractions)"
}
extension HeaderString {
    struct Regex {
        static let per100 =
#"^((serve |average |)(per|pour) |)100[ ]*(?:g|ml)$"#
        /// We've included `amount` here, and added more unit options without testing if this breaks previous cases
        static let per100_2 =
#"^((serve |average |amount |)(per|pour) |)100[ ]*(?:g|gram|grams|gs|gr|gm|ml|ms)$"#

        
        static let perServing =
#"^(?=^.*(amount|)[ ]*((per|par|por) |\/)(serv(ing|e)|portion|porção).*$)(?!^.*100[ ]*(?:g|ml).*$).*$"#
//#"^(?=^.*(?:amount|)[ ]*(?:(?:per|par|por) |\/)(?:serv(?:ing|e)|portion|porção)[ ]*(.*)$)(?!^.*100[ ]*(?:g|ml).*$).*$"#
        
        static let perServingWithSize =
//#"^(?=^(?:.*(?:(?:per|par|por) )(?:(?:(?:serv(?:ing|e)|portion|porção) )|)([\#(Rx.numbers)]+.*)|[\#(Rx.numbers)]+[ ]*(g)[^\#(Rx.numbers)]*[\#(Rx.numbers)]+[^\#(Rx.numbers)]+)$)(?!^.*100[ ]*(?:g|ml).*$).*$"#
#"^(?=^.*(?:(?:per|par|por) )(?:(?:(?:serv(?:ing|e)|portion|porção) )|)([\#(Rx.numbers)]+.*)$)(?!^.*100[ ]*(?:g|ml).*$).*$"#

        /// Matches headers like `80 g = 1 Wrap`
        static let perServingWithSize3 =
#"^([\#(Rx.numbers)]+[ ]*(?:g)[^\#(Rx.numbers)]*[\#(Rx.numbers)]+[^\#(Rx.numbers)]+)$"#

        /// Alternative for cases like `⅕ of a pot (100g)`
        static let perServingWithSize2 =
#"(^[0-9⅕]+(?: of a|)[ ]*[^0-9⅕]+[0-9⅕]+[ ]?[^0-9⅕ \)]+)"#
        
        static let per100gAndPerServing =
//#"(?:.*(?:per|pour) 100[ ]*(?:g|ml)[ ])(?:per[ ])?(.*)"#
#"^(?!^(?:per|pour) (?!100))(?=(?:.*(?:per|pour) 100[ ]*(?:g|ml)[ ])(?:per[ ])?(.*)).*$"#
        
        static let per100WithNutritionalValuesPrefix =
#"^Nutritional values per 100 g.*"#
        
        static let perServingAndPer100g =
#"^.*(?:(?:(?:per|par)|)[ ]+(.+(?:g|ml|)).*(?:per|pour) 100[ ]*(?:g|ml)).*$"#
        
        /// Deprecated patterns
//        static let per100 = #"^(per |)100[ ]*g$"#
        
//        static let perServingWithSize = #"^(?=^.*(?:per |serving size[:]* )([0-9]+.*)$)(?!^.*100[ ]*g.*$).*$"#
        
//        static let perServingWithSize2 = #"^([\#(Rx.numbers)]+)(?: of a|)[ ]*([^\#(Rx.numbers)]+)([\#(Rx.numbers)]+)[ ]?([^\#(Rx.numbers) \)]+)"#
   }
}

extension HeaderString: Equatable {
    public static func ==(lhs: HeaderString, rhs: HeaderString) -> Bool {
        switch (lhs, rhs) {
        case (.per100, .per100):
            return true
        case (.perServing(let lhsServing), .perServing(let rhsServing)):
            return lhsServing == rhsServing
        case (.per100AndPerServing(let lhsServing), .per100AndPerServing(let rhsServing)):
            return lhsServing == rhsServing
        case (.perServingAnd100(let lhsServing), .perServingAnd100(let rhsServing)):
            return lhsServing == rhsServing
        default:
            return false
        }
    }
}
