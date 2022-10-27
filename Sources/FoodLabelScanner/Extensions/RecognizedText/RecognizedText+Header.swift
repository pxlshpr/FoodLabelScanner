import VisionSugar

extension RecognizedText {
    var singleHeaderObservations: [Observation] {
        guard let headerString = HeaderString(string: string) else {
            return []
        }

        let headerType: HeaderType
        let servingString: String?
        
        // print("Header String for: \(string) -> \(headerString)")
        
        switch headerString {
        case .per100:
            headerType = HeaderType(per100String: string)
            servingString = nil
        case .perServing(let serving):
            headerType = .perServing
            servingString = serving
        case .per100AndPerServing(let string):
            /// Treat these as `.per100` as well, ignoring the serving sring
            servingString = nil
            if let string {
                headerType = HeaderType(per100String: string)
            } else {
                headerType = HeaderType(string: self.string) ?? .per100g
            }
        default:
            return []
        }

        guard let headerTypeObservation = Observation(
            headerType: headerType,
            for: .headerType1,
            recognizedText: self
        ) else {
            return []
        }
        
        if let servingString, let serving = HeaderText.Serving(string: servingString) {
            let servingObservations = headerServingObservations(serving: serving)
            return [headerTypeObservation] + servingObservations
        } else {
            return [headerTypeObservation]
        }
    }
    
    func headerServingObservations(serving: HeaderText.Serving) -> [Observation] {
        
        var observations: [Observation] = []
        if let amount = serving.amount,
           let observation = Observation(double: amount,
                                         attribute: .headerServingAmount,
                                         recognizedText: self)
        {
                observations.appendIfValid(observation)
        }
        
        if let unit = serving.unit,
           let observation = Observation(unit: unit,
                                         attribute: .headerServingUnit,
                                         recognizedText: self)
        {
            observations.appendIfValid(observation)
        }
        
        if let string = serving.unitName,
           let observation = Observation(string: string,
                                         attribute: .headerServingUnitSize,
                                         recognizedText: self)
        {
            observations.appendIfValid(observation)
        }
        
        guard let equivalentSize = serving.equivalentSize else {
            return observations
        }
        
        if let observation = Observation(double: equivalentSize.amount,
                                         attribute: .headerServingEquivalentAmount,
                                         recognizedText: self)
        {
            observations.appendIfValid(observation)
        }
        
        if let unit = equivalentSize.unit,
           let observation = Observation(unit: unit,
                                         attribute: .headerServingEquivalentUnit,
                                         recognizedText: self)
        {
            observations.appendIfValid(observation)
        }
        
        if let string = equivalentSize.unitName,
           let observation = Observation(string: string,
                                         attribute: .headerServingEquivalentUnitSize,
                                         recognizedText: self)
        {
            observations.appendIfValid(observation)
        }
        
        return observations
    }
}
