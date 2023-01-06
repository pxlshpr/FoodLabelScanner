import Foundation

extension Attribute {
    var regex: String? {
        switch self {
        case .tableElementNutritionFacts:
            return #"nutrition facts"#
        case .tableElementSkippable:
            return #"^(vitamins (&|and) minerals|of which|alimentaires|g)$"#
        case .nutrientLabelTotal:
            return #"^[- ]*total$"#
        case .servingsPerContainerAmount:
            return #"(?:servings |serving5 |)per (container|pack(age|)|tub|pot)"#
        case .servingAmount:
            return #"((serving size|size:|dose de referencia|takaran)|^size$)"#
            /// Legacy, in case things break — TODO: Write tests for this and the other serving attributes
//            return #"((serving size|size:|dose de referencia)|^size$)"#
        case .energy:
            return Regex.energy
            
        case .protein:
            return #"(?<!high)(protein|proteine|proteines|eiweiß)(?! (bar|bas))"#

        case .carbohydrate:
            return #".*(carb|glucide(s|)|(h|b)(y|v)drate|karbohidrat).*"#
        case .dietaryFibre:
            return Regex.dietaryFibre
        case .solubleFibre:
            return Regex.solubleFibre
        case .insolubleFibre:
            return Regex.insolubleFibre
        case .polyols:
            return "(polyols|polioli)"
        case .gluten:
            return #"^.*gluten(?!,)(?! (free|(b|d)evatten)).*$"#
        case .starch:
            return Regex.starch

        case .fat:
            return Regex.fat
        case .saturatedFat:
            return Regex.saturatedFat
        case .monounsaturatedFat:
            return Regex.monounsaturatedFat
        case .polyunsaturatedFat:
            return Regex.polyunsaturatedFat
        case .transFat:
            return Regex.transFat
        case .cholesterol:
            return Regex.cholesterol
            
        case .salt:
            /// Include `hidangan` because "Serving Size" in Malay is `Saiz Hidangan` which may be misread as `Salz Hidangan`, so this rules it out.
            return #"(?<!less of )(salt|salz|[^A-z]sel|sare)(?! hidangan)([^,]|\/|$)"#
        case .sodium:
            return #"sodium"#
        case .sugar:
            return Regex.sugar
        case .addedSugar:
            return Regex.addedSugar
        case .calcium:
            return #"calcium(?! citrate)"#
        case .iron:
            return #"(^| )iron"#
        case .potassium:
            return #"potas"#
        case .magnesium:
            return #"magnesium"#
        case .zinc:
            return #"zinc"#
        case .thiamin:
            return #"thiamin"#
        case .riboflavin:
            return #"riboflavin"#
        case .niacin:
            return #"niacin"#
        
        case .folicAcid:
            return #"folic acid"#
        case .folate:
            return #"folate"#
            
        case .cobalamin: /// Vitamin B12
            return #"(?<!methyl)(?<!methy )(?<!methy)cobalamin"#
        case .vitaminA:
            return Regex.vitamin("a")
        case .vitaminC:
            return Regex.vitamin("c")
        case .vitaminD:
            return Regex.vitamin("d")
        case .vitaminB6:
            return Regex.vitamin("(b6|86)")
        case .vitaminB1:
            return Regex.vitamin("(b1|81)")
        case .vitaminB2:
            return Regex.vitamin("(b2|82)")
        case .vitaminB12:
            return Regex.vitamin("(b12|812)")
        case .vitaminB3:
            return Regex.vitamin("b3")
            
        case .iodine:
            return #"(i|l)odine"#
        case .selenium:
            return #"selenium"#
        case .manganese:
            return #"manganese"#
        case .chromium:
            return #"chromium"#
        case .biotin:
            return #"biotin"#
        case .pantothenicAcid:
            return #"pantothenic acid"#
        case .vitaminE:
            return Regex.vitamin("e")
        case .vitaminK:
            return Regex.vitamin("k")
        case .vitaminK2:
            return Regex.vitamin("k2")

        case .taurine:
            return #"taurine"#
        case .caffeine:
            return #"caffeine"#
            
        default:
            return nil
        }
    }
    
    struct Regex {
        static let amountPerServing = #"amount per serving"#
        static let amountPer100g = #"amount per 100[ ]*g"#
        static let amountPer100ml = #"amount per 100[ ]*ml"#

        static let calories = #"calories"#
        
        static let energy_legacy = #"^(.*energy.*|.*energi.*|.*calories.*|.*energie.*|.*valoare energetica.*|y kcal)$"#
        static let energyOptions = [
            ".*energy.*", ".*energi.*", ".*calories.*", ".*energie.*", ".*valoare energetica.*", "y kcal"
        ]
        static let energyOnly = #"^(\#(energyOptions.joined(separator: "|")))$"#
        static let energyOutOfContext = #".*(calories a day|2000 calories|energy from fat).*"#
        static let energy = #"^(?=\#(energyOnly))(?!\#(energyOutOfContext)).*$"#
//        static let energy = #"^(?=\#(energyOnly)).*$"#

        static let totalSugarOptions = [
            "sugar", "sucres", "zucker", "zuccheri", "dont sucres", "din care zaharuri", "azucares", "waarvan suikers", "sigar"
        ]
        
        static let totalSugar = #"^.*(\#(totalSugarOptions.joined(separator: "|")))(?!,).*$"#
        static let addedSugar = #"^.*(added sugar(s|)|includes [0-9,.]+ (grams|g)).*$"#
        static let sugar = #"^(?=\#(totalSugar))(?!\#(addedSugar)).*$"#
        
        static let dietaryFibreOptions = [
            "(dietary |)fib(re|er)", "fibra", "voedingsvezel",
            "ballaststoffe",
            "serabut diet",
            "ballaststottest", "libre", "libron" /// Vision Errors
        ]
        static let solubleFibreOptions = [
            "(^|[ ])soluble fib(re|er)"
        ]
        static let insolubleFibreOptions = [
            "insoluble fib(re|er)"
        ]
        static let dietaryFibreOnly = #"^.*(\#(dietaryFibreOptions.joined(separator: "|"))).*$"#
        static let solubleFibre = #"^.*(\#(solubleFibreOptions.joined(separator: "|"))).*$"#
        static let insolubleFibre = #"^.*(\#(insolubleFibreOptions.joined(separator: "|"))).*$"#
        
        static let dietaryFibre = #"^(?=\#(dietaryFibreOnly))(?!\#(solubleFibre))(?!\#(insolubleFibre)).*$"#
        
        /// Negative lookbehind makes sure starch isn't preceded by tapioca
        static let starch = #"^(of which |)starch$"#
        
        static let totalFatOptions = [
            "(?<!anu)fa(t|i)", "fett", "grassi", "lipidos", "grasa total", "grasimi", "jumlah lemak"
        ]

        static let saturatedFatOptions = [
            "saturated",
            "satuwed", "satu[^ ]+ed", "saturat[^ ]+d", /// Vision typos
            "saturates",
            "lemak tepu",
            "davon gesattigte",
            "mattat fett",
            "of which saturates", "saturi", "saturados", "gras satures", "sat. fat", "kwasy nasycone", "grasi saturati", "sociosios"
        ]

//        static let totalFat = #"^.*(\#(totalFatOptions.joined(separator: "|"))).*$"#

        static let fatOutOfContext = #".*(energy from fat|calories from fat).*"#
        static let fatOnly = #"^.*(\#(totalFatOptions.joined(separator: "|"))).*$"#
        static let totalFat = #"^(?=\#(fatOnly))(?!\#(fatOutOfContext)).*$"#

        static let saturatedFatOnly = #"^.*(\#(saturatedFatOptions.joined(separator: "|"))).*$"#
        static let transFat = #"^.*trans.*$"#
        
        /// Replaced when `monounsat.` failed to be picked up. Delete the commented out lines after we've added a test suite for these
//        static let monounsaturatedFat = #"^.*mono(-|)unsaturat.*$"#
//        static let polyunsaturatedFat = #"^.*poly(-|)unsaturat.*$"#
        static let monounsaturatedFat = #"^.*mono(-|)unsat.*$"#
        static let polyunsaturatedFat = #"^.*poly(-|)unsat.*$"#

        static let saturatedFat = #"^(?=\#(saturatedFatOnly))(?!\#(monounsaturatedFat))(?!\#(polyunsaturatedFat)).*$"#

        static let fat = #"^(?=\#(totalFat))(?!\#(saturatedFat))(?!\#(transFat))(?!\#(polyunsaturatedFat))(?!\#(monounsaturatedFat)).*$"#

        static let cholesterol = #"(cholest|kolesterol)"#
        
        static func vitamin(_ letter: String) -> String {
            #"vit(amin[ ]+|\.[ ]*|[ ]+)\#(letter)( |$)"#
        }
    }
}
