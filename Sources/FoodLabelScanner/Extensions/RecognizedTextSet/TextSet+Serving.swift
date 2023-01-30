import VisionSugar

extension RecognizedTextSet {
    
    var servingObservations: [Observation] {
        var observations: [Observation] = []
        
        for text in texts {
            guard text.string.containsServingAttribute else {
                continue
            }
            
            let (textObservations, observationBeingExtracted) = extractObservations(of: text)
            
            /// Process any observations that were extracted
            for observation in textObservations {
                observations.appendIfValid(observation)
            }

            /// Now do an inline search for any attribute that is still being extracted
            if let observation = observationBeingExtracted {

                /// Skip attributes that have already been added
                guard !observations.contains(attribute: observation.attributeText.attribute) else {
                    continue
                }

                /// ** Heuristic** If this is `.servingsPerContainerAmount`, look for it inline-preceding, before checking the columns
                if observation.attribute == .servingsPerContainerAmount {
                    if extractInlineObservations(of: text, into: &observations, for: observation, preceding: true) {
//                    if extractPrecedingInlineValueForServingsPerContainerAmount(
//                        of: recognizedText, for: observation) {
                        continue
                    }
                }

                /// Now look for it in-column
                let didExtractInColumn = extractInColumnObservations(of: text, into: &observations, for: observation)

                /// If it still wasn't found, now do an inline-succeeding search
                if !didExtractInColumn {
                    let _ = extractInlineObservations(of: text, into: &observations, for: observation)
                }
            }
        }
        return observations
    }
    
    func extractObservations(
        of text: RecognizedText,
        startingWith startingAttributeText: AttributeText? = nil
    ) -> (observations: [Observation], observationBeingExtracted: Observation?)
    {
        let artefacts = text.servingArtefacts

        var observations: [Observation] = []
        var attributesBeingExtracted: [AttributeText] = [startingAttributeText].compactMap { $0 }

        /// For each of the serving artefacts of this text
        for i in artefacts.indices {
            let artefact = artefacts[i]
            
            /// If the artefact is an attribute
            if let extractedAttribute = artefact.attribute {
                
                /// Populate the the `attributesBeingExtracted` array with it
                attributesBeingExtracted = [AttributeText(
                    attribute: extractedAttribute,
                    text: text)
                ]
            }
            
            /// Otherwise—if the `attributesBeingExtracted` array is not empty
            else if !attributesBeingExtracted.isEmpty {
                
                /// For each of the attribute being extracted
                ///
                for extractingAttribute in attributesBeingExtracted {
                    
                    /// If this attribute supports the serving artefact (ie we can make an observation out of them
                    guard let observation = Observation(attributeText: extractingAttribute, servingArtefact: artefact) else {
                        continue
                    }
                    
                    /// Add this observation to the array
                    observations.append(observation)
                    
                    /// If we expect attributes to follow this (for example, `.servingUnit` or `.servingUnitSize` following a `.servingAmount`) ...
                    guard let nextAttributes = extractingAttribute.attribute.nextAttributes else {
                        attributesBeingExtracted = []
                        continue
                    }
                    
                    /// ... assign those as the attributes we're now extracting
                    attributesBeingExtracted = nextAttributes.map { AttributeText(attribute: $0, text: text) }
                }
            }
        }
        
        let observationBeingExtracted: Observation?
        
        /// If we still have an attribute being extracted (by it not being cleared out of the `attributesBeingExtracted` array
        if let attributeBeingExtracted = attributesBeingExtracted.first,
           /// and the starting attribute text was nil (not sure why this is here yet)
           startingAttributeText == nil
        {
            /// Then create an empty observation being extracted that can be passed onto the inline search
            observationBeingExtracted = Observation(
                attributeText: attributeBeingExtracted,
                valueText1: nil,
                valueText2: nil)
        } else {
            observationBeingExtracted = nil
        }
        
        /// Now return the array of observations we extracted and the observation currently being extracted (if any)
        return (observations, observationBeingExtracted)
    }
    
    func extractInlineObservations(
        of recognizedText: RecognizedText,
        into observations: inout [Observation],
        for observation: Observation,
        preceding: Bool = false
    ) -> Bool
    {
        //TODO: Handle array of recognized texts
        /// **Copy across what we're doing here, of:**
        /// - Going through the entire `arrayOfRecognizedTexts` to find matching observations, and not just the array that was passed in
        /// - Make sure we're doing this in other classifiers as well
        /// - See if we can run each classifier once, feeding it the array of recognized texts, and
        ///     - Check if the tests succeed, and if so
        ///     - If this is any faster, by measuring how long it takes
        
        let inlineTextColumns = texts.inlineTextColumns(as: recognizedText, preceding: preceding)
        for column in inlineTextColumns {

            guard let inlineText = pickInlineText(fromColumn: column, for: observation.attributeText.attribute) else {
                continue
            }

            /// ** Removing this temporarily ** Until we find a case that warrants having it again.
//            guard recognizedText.isNotTooFarFrom(inlineText) else {
//                continue
//            }

            let (extractedObservations, _) = extractObservations(of: inlineText, startingWith: observation.attributeText)
            for observation in extractedObservations {
                observations.appendIfValid(observation)
            }
            if extractedObservations.count > 0 {
                return true
            }
        }
        return false
    }
    
    func extractInColumnObservations(
        of recognizedText: RecognizedText,
        into observations: inout [Observation],
        for observation: Observation
    ) -> Bool {
        
        /// If we've still not found any resulting attributes, look in the next text directly below it
        guard let nextLineText = texts.filterSameColumn(as: recognizedText, removingOverlappingTexts: false).first,
            nextLineText.string != "Per 100g",
            !nextLineText.string.matchesRegex("^calories")
        else {
            return false
        }
        let (extractedObservations, _) = extractObservations(of: nextLineText, startingWith: observation.attributeText)
        
        guard extractedObservations.count > 0 else {
            return false
        }
        for observation in extractedObservations {
            observations.appendIfValid(observation)
        }
        return true
    }
    
    private func pickInlineText(fromColumn column: [RecognizedText], for attribute: Attribute) -> RecognizedText? {
        
        /// **Heuristic** Remove any texts that contain no artefacts before returning the closest one, if we have more than 1 in a column (see Test Case 22 for how `Alimentaires` and `1.5 g` fall in the same column, with the former overlapping with `Protein` more, and thus `1.5 g` getting ignored
        let column = column.filter {
            $0.servingArtefacts.count > 0
        }
        
        /// As the defaul fall-back, return the first text (ie. the one closest to the observation we're extracted)
        return column.first
    }
}

extension RecognizedText {
    //TODO: Build on this, as we're currently naively checking the horizontal distance
    func isNotTooFarFrom(_ recognizedText: RecognizedText) -> Bool {
        let HorizontalThreshold = 0.3
        let horizontalDistance: Double
        if recognizedText.boundingBox.minX < boundingBox.minX {
            horizontalDistance = abs(boundingBox.minY - recognizedText.boundingBox.maxY)
        } else {
            horizontalDistance = abs(recognizedText.boundingBox.minX - boundingBox.maxX)
        }
        
        /// Make sure the `RecognizedText` we're checking is to the right of this
//        guard horizontalDistance > 0 else {
//            return false
//        }
        
        /// Returns true if the distance between them is less than the `HorizontalThreshold` value which is in terms of the bounding box. So a value of `0.3` would mean that it's considered "not too far" if it's less than 30% of the width of the bounding box.
        return horizontalDistance < HorizontalThreshold
    }
}


extension Array where Element == Observation {
    
    func contains(attribute: Attribute) -> Bool {
        contains(where: {
            $0.attributeText.attribute == attribute
        })
    }

    func containsConflictingAttribute(to attribute: Attribute) -> Bool {
        for conflictingAttribute in attribute.conflictingAttributes {
            if contains(attribute: conflictingAttribute) {
                return true
            }
        }
        return false
    }

    mutating func appendIfValid(_ observation: Observation) {
        let attribute = observation.attributeText.attribute
        let containsAttribute = contains(attribute: attribute)
        let containsConflictingAttribute = containsConflictingAttribute(to: attribute)
        if !containsAttribute && !containsConflictingAttribute {
            append(observation)
        }
    }
}

extension Array where Element == RecognizedText {
    
    func filterSameColumn(as recognizedText: RecognizedText, preceding: Bool = false, removingOverlappingTexts: Bool = true) -> [RecognizedText] {
        let candidates = filter {
            $0.isInSameColumnAs(recognizedText)
            && (preceding ? $0.rect.maxY < recognizedText.rect.maxY : $0.rect.minY > recognizedText.rect.minY)
        }.sorted {
            $0.rect.minY < $1.rect.minY
        }

        var column: [RecognizedText] = []
        var discarded: [RecognizedText] = []
        for candidate in candidates {

            guard !discarded.contains(candidate) else {
                continue
            }
            let row = candidates.filter {
                $0.isInSameRowAs(candidate)
            }
            guard row.count > 1, let first = row.first else {
                column.append(candidate)
                continue
            }
            
            /// Deal with multiple recognizedTexts we may have grabbed from the same row due to them both overlapping with `recognizedText` by choosing the one that intersects with it the most
            if removingOverlappingTexts {
                var closest = first
                for rowElement in row {
                    /// first normalize the y values of both rects, `rowElement`, `closest` to `recognizedText` in new temporary variables, by assigning both the same y values (`origin.y` and `size.height`)
                    let yNormalizedRect = rowElement.rect.rectWithYValues(of: recognizedText.rect)
                    let closestYNormalizedRect = closest.rect.rectWithYValues(of: recognizedText.rect)

                    let intersection = yNormalizedRect.intersection(recognizedText.rect)
                    let closestIntersection = closestYNormalizedRect.intersection(recognizedText.rect)

                    let intersectionRatio = intersection.width / rowElement.rect.width
                    let closestIntersectionRatio = closestIntersection.width / closest.rect.width

                    if intersectionRatio > closestIntersectionRatio {
                        closest = rowElement
                    }
                    
                    discarded.append(rowElement)
                }
                column.append(closest)
            } else {
                column = candidates
                break
            }
        }
        
        return column
    }
}
