import Foundation
import VisionSugar
import PrepDataTypes

extension Array where Element == Observation {
    mutating func populateMissingHeaderObservations(from textSet: RecognizedTextSet) {
        /// First make sure we don't already have header observations
        guard !self.containsHeaderAttribute else {
            return
        }
        
        for text in textSet.texts {
            let headerObservations = text.singleHeaderObservations
            if !headerObservations.isEmpty {
                append(contentsOf: headerObservations)
                return
            }
        }
    }
    
    var containsHeaderAttribute: Bool {
        contains(where: {
            $0.attribute.isHeaderAttribute
        })
    }
}

extension RecognizedTextSet {
    func tabularHeaderObservations(for nutrientObservations: [Observation]) -> [Observation] {

        var observations: [Observation] = []

        /// Get top-most value1 recognized text
        guard let topMostValue1RecognizedText = topMostValue1RecognizedText(for: nutrientObservations) else {
            //TODO: Try other methods here
            return observations
        }

        /// Get preceding recognized texts in that column
        let result = extractHeaders(inSameColumnAs: topMostValue1RecognizedText, into: &observations)
        guard result.extractedHeader1 else {
            //TODO: Try other methods for header 1
            return observations
        }

        /// Make sure we haven't extracted header 2 yet before attempting to do it
        guard !result.extractedHeader2 else {
            return observations
        }
        
        /// If we haven't extracted header 2 yet, and are expecting it (by checking if we have any value 2's)
        guard nutrientObservations.containsSeparateValue2Observations else {
            return observations
        }
        
        guard let topMostValue2RecognizedText = topMostValue2RecognizedText(for: nutrientObservations) else {
            //TODO: Try first inline text to header1 that's also in the same column as value 2's
            return observations
        }
        
        let _ = extractHeaders(inSameColumnAs: topMostValue2RecognizedText, forHeaderNumber: 2, into: &observations)

        return observations
    }
    
    //MARK: - Helpers
    func extractHeaders(
        inSameColumnAs topRecognizedText: RecognizedText,
        forHeaderNumber headerNumber: Int = 1,
        into observations: inout [Observation]
    ) -> (extractedHeader1: Bool, extractedHeader2: Bool)
    {
        let inlineTextRows = texts.inlineTextRows(as: topRecognizedText, preceding: true)
        var didExtractHeader1: Bool = false
        var didExtractHeader2: Bool = false
        let headerColumnAttribute: Attribute = headerNumber == 1 ? .headerType1 : .headerType2

        for row in inlineTextRows {
            for recognizedText in row {
                if !shouldContinueExtractingAfter(
                    extracting: recognizedText,
                    into: &observations,
                    forHeaderColumnAttribute: headerColumnAttribute,
                    headerNumber: headerNumber,
                    didExtractHeader1: &didExtractHeader1,
                    didExtractHeader2: &didExtractHeader2
                ) {
                    break
                }
            }
            if didExtractHeader1 || didExtractHeader2 {
                break
            }
        }

        /// If we hadn't extracted a header, try to find a header by merging the two rows at the top
        if !didExtractHeader1 && !didExtractHeader2 {
            for row in inlineTextRows
            {
                let texts = row.reversed().prefix(2)
                guard texts.count == 2 else {
                    continue
                }

                let string = texts.map { $0.string }.joined(separator: " ")

                guard let firstText = texts.first,
                      string.matchesRegex(HeaderString.Regex.perServingWithSize2),
                      let serving = HeaderText.Serving(string: string),
                      let headerTypeObservation = Observation(
                        headerType: .perServing,
                        for: headerColumnAttribute,
                        attributeText: Array(texts)[1],
                        recognizedText: firstText
                      )
                else {
                    continue
                }
                observations.append(headerTypeObservation)

                processHeaderServing(serving, for: firstText, attributeText: Array(texts)[1], into: &observations)
                didExtractHeader1 = true
            }
        }
        return (didExtractHeader1, didExtractHeader2)
    }

    /// Return value indicates if search should continue
    func shouldContinueExtractingAfter(
        extracting text: RecognizedText,
        into observations: inout [Observation],
        forHeaderColumnAttribute headerColumnAttribute: Attribute,
        headerNumber: Int,
        didExtractHeader1: inout Bool,
        didExtractHeader2: inout Bool
    ) -> Bool
    {
        func extractedFirstHeader() {
            if headerNumber == 1 {
                didExtractHeader1 = true
            } else {
                didExtractHeader2 = true
            }
        }
        
        guard let extractedHeaderString = HeaderString(string: text.string) else {
            return true
        }
        
        var headerString = extractedHeaderString
        
        /// **Heuristic** for when we already have a `.perServing` header and encounter what we think is another one.
        /// This could be due to a misread (for example, partially reading `Per 100g` as `Per 10`, and classifying it as a serving heading.
        /// In such case we simply default to reassigning this second `HeaderString` as a `.per100`
        if let headerType1 = observations.headerType1, headerType1 == .perServing
        {
            headerString = .per100
        }
        
        switch headerString {
        case .per100:
            guard let observation = Observation(
                headerType: HeaderType(per100String: text.string),
                for: headerColumnAttribute,
                recognizedText: text) else
            {
                return true
            }
            observations.appendIfValid(observation)
            extractedFirstHeader()
        case .perServing:
            guard let observation = Observation(
                headerType: .perServing,
                for: headerColumnAttribute,
                recognizedText: text) else
            {
                return true
            }
            observations.appendIfValid(observation)
            extractedFirstHeader()
        case .per100AndPerServing:
            guard let firstObservation = Observation(
                headerType: HeaderType(per100String: text.string),
                for: headerColumnAttribute,
                recognizedText: text) else
            {
                return true
            }
            observations.appendIfValid(firstObservation)
            extractedFirstHeader()
            
            guard headerNumber == 1, let secondObservation = Observation(
                headerType: .perServing,
                for: .headerType2,
                recognizedText: text) else
            {
                return true
            }
            observations.appendIfValid(secondObservation)
            didExtractHeader2 = true
        case .perServingAnd100:
            guard let firstObservation = Observation(
                headerType: .perServing,
                for: headerColumnAttribute,
                recognizedText: text) else
            {
                return true
            }
            observations.appendIfValid(firstObservation)
            extractedFirstHeader()

            guard headerNumber == 1, let secondObservation = Observation(
                headerType: HeaderType(per100String: text.string),
                for: .headerType2,
                recognizedText: text) else
            {
                return true
            }
            observations.appendIfValid(secondObservation)
            didExtractHeader2 = true
        }
        
        switch headerString {
        case .perServing(let string), .per100AndPerServing(let string), .perServingAnd100(let string):
            guard let string = string, let serving = HeaderText.Serving(string: string) else {
                return false
            }
            processHeaderServing(serving, for: text, into: &observations)
        default:
            return false
        }
        if didExtractHeader1 || didExtractHeader2 {
            return false
        } else {
            return true
        }
    }
    
    func processHeaderServing(
        _ serving: HeaderText.Serving,
        for recognizedText: RecognizedText,
        attributeText: RecognizedText? = nil,
        into observations: inout [Observation]
    ) {
        if let amount = serving.amount, let observation = Observation(double: amount, attribute: .headerServingAmount, attributeText: attributeText, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let unit = serving.unit, let observation = Observation(unit: unit, attribute: .headerServingUnit, attributeText: attributeText, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let string = serving.unitName, let observation = Observation(string: string, attribute: .headerServingUnitSize, attributeText: attributeText, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        guard let equivalentSize = serving.equivalentSize else {
            return
        }
        if let observation = Observation(double: equivalentSize.amount, attribute: .headerServingEquivalentAmount, attributeText: attributeText, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let unit = equivalentSize.unit, let observation = Observation(unit: unit, attribute: .headerServingEquivalentUnit, attributeText: attributeText, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
        if let string = equivalentSize.unitName, let observation = Observation(string: string, attribute: .headerServingEquivalentUnitSize, attributeText: attributeText, recognizedText: recognizedText) {
            observations.appendIfValid(observation)
        }
    }
    
    func topMostValue1RecognizedText(for observations: [Observation]) -> RecognizedText? {
        value1RecognizedTexts(for: observations).sorted { $0.rect.minY < $1.rect.minY }.first
    }

    func value1RecognizedTexts(for observations: [Observation]) -> [RecognizedText] {
        observations.value1RecognizedTextIds.compactMap { id in
            texts.first { $0.id == id }
        }
    }
    
    func topMostValue2RecognizedText(for observations: [Observation]) -> RecognizedText? {
        value2RecognizedTexts(for: observations).sorted { $0.rect.minY < $1.rect.minY }.first
    }

    func value2RecognizedTexts(for observations: [Observation]) -> [RecognizedText] {
        observations.value2RecognizedTextIds.compactMap { id in
            texts.first { $0.id == id }
        }
    }
    

}

extension Array where Element == Observation {
    var value1RecognizedTextIds: [UUID] {
        filterContainingSeparateValue1.compactMap { $0.valueText1?.text.id }
    }

    var value2RecognizedTextIds: [UUID] {
        filterContainingSeparateValue2.compactMap { $0.valueText2?.text.id }
    }

    var containsSeparateValue2Observations: Bool {
        !filterContainingSeparateValue2.isEmpty
    }
    
    /// Filters out observations that contains separate `recognizedText`s for value 1 and 2 (if present)
    var filterContainingSeparateValues: [Observation] {
        filter { $0.valueText1?.text.id != $0.valueText2?.text.id }
    }
    /// Filters out observations that contains a separate value 1 observation (that is not the same as value 2)
    var filterContainingSeparateValue1: [Observation] {
        filterContainingSeparateValues.filter { $0.valueText1 != nil }
    }
    var filterContainingSeparateValue2: [Observation] {
        filterContainingSeparateValues.filter { $0.valueText2 != nil }
    }
}

extension Observation {
    init?(headerType: HeaderType, for attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute == .headerType1 || attribute == .headerType2 else {
            return nil
        }
        
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: headerType.rawValue,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText)
        )
    }
    
    init?(double: Double, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsDouble else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            doubleText: DoubleText(
                double: double,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText))
    }
    
    init?(unit: FoodLabelUnit, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsNutritionUnit else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: unit.description,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText))
    }

    init?(string: String, attribute: Attribute, attributeText: RecognizedText? = nil, recognizedText: RecognizedText) {
        guard attribute.expectsString else { return nil }
        self.init(
            attributeText: AttributeText(
                attribute: attribute,
                text: attributeText ?? recognizedText),
            stringText: StringText(
                string: string,
                text: recognizedText,
                attributeText: attributeText ?? recognizedText))
    }
}

extension HeaderText.Serving {
    
    init?(string: String) {
        let regex = #"^([^\#(Rx.numbers)]*)([\#(Rx.numbers)]+[0-9\/]*)[ ]*(?:of a |)([A-z]+)(?:[^\#(Rx.numbers)]*([\#(Rx.numbers)]+)[ ]*([A-z]+)|).*$"#
        let groups = string.capturedGroups(using: regex)
        
        if groups.count == 3 {
            
            /// ** Heuristic ** If the first match contains `serving`, ignore it and assign the next two array elements as the serving amount and unit
            if !groups[0].isEmpty && !groups[0].contains("serving") {
                
                /// if we have the first group, this indicates that we got the serving unit without an amount, so assume it to be a `1`
                /// e.g. **bowl (125 g)**
                self.init(amount: 1,
                          unitString: groups[0],
                          equivalentSize: EquivalentSize(
                            amountString: groups[1],
                            unitString: groups[2]
                          )
                )
            } else {
                /// 120g
                /// 100ml
                /// 15 ml
                /// 100 ml
                self.init(amountString: groups[1], unitString: groups[2], equivalentSize: nil)
            }
        }
        else if groups.count == 5 {
            /// 74g (2 tubes)
            /// 130g (1 cup)
            /// 125g (1 cup)
            /// 3 balls (36g)
            /// 1/4 cup (30 g)
            self.init(amountString: groups[1],
                      unitString: groups[2],
                      equivalentSize: EquivalentSize(
                        amountString: groups[3],
                        unitString: groups[4]
                      )
            )
        } else {
            return nil
        }
    }
    
    init?(amountString: String, unitString: String, equivalentSize: EquivalentSize?) {
        self.init(amount: Double(fromString: amountString), unitString: unitString, equivalentSize: equivalentSize)
    }
    
    init?(amount: Double?, unitString: String, equivalentSize: EquivalentSize?) {
        self.amount = amount
        let cleaned = unitString.cleanedUnitString
        if let unit = FoodLabelUnit(string: cleaned) {
            guard unit.isAllowedInHeader else {
                return nil
            }
            self.unit = unit
            unitName = nil
        } else {
            unit = nil
            unitName = cleaned
        }
        self.equivalentSize = equivalentSize
    }

}

extension HeaderText.Serving.EquivalentSize {
    
    init?(amountString: String, unitString: String) {
        guard let amount = Double(fromString: amountString) else {
            return nil
        }
        let cleaned = unitString.cleanedUnitString
        self.amount = amount
        if let unit = FoodLabelUnit(string: cleaned) {
            self.unit = unit
            unitName = nil
        } else {
            unit = nil
            unitName = cleaned
        }
    }
}
