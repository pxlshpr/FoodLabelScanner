import Foundation
import VisionSugar

extension RecognizedTextSet {
    func columnsOfAttributes() -> [[AttributeText]] {
        
        var columns: [[AttributeText]] = []
        
        for text in texts {
            guard Attribute.haveNutrientAttribute(in: text.string) else {
                continue
            }
            
            /// Go through texts until a nutrient attribute is found
            let columnOfTexts = getColumnOfNutrientLabelTexts(startingFrom: text)
                .sorted(by: { $0.rect.minY < $1.rect.minY })
            
            guard let column = getUniqueAttributeTextsFrom(columnOfTexts) else {
                continue
            }

            /// First, make sure the column is at least the threshold of attributes long
//                guard column.count >= 3 else {
//                    continue
//                }
            
            if columns.containsArrayWithAnAttributeFrom(column) {
                
                if columns.contains(where: {
                    $0.containsAnyAttributeIn(column) && $0.count <= column.count
                }) {
                    /// filter out the columns
                    columns = columns.filter {
                        !$0.containsAnyAttributeIn(column) ||
                        $0.count >= column.count
                    }
                }
                
//                /// Now see if we have any existing columns that is a subset of this column
//                if let index = columns.indexOfSubset(of: column), columns[index].count < column.count {
//
//                    if columns.containsArrayWithAnAttributeFrom(column) {
//                        /**
//                         Consider the following case
//                         ```
//                         (lldb) po column.map { $0.attribute }
//                         ▿ 8 elements
//                           - 0 : Energy
//                           - 1 : Protein
//                           - 2 : Carbohydrate
//                           - 3 : Total Sugars
//                           - 4 : Fat
//                           - 5 : Saturated Fat
//                           - 6 : Dietary Fibre
//                           - 7 : Sodium
//
//                         (lldb) po columns.map { $0.map { $0.attribute } }
//                         ▿ 2 elements
//                           ▿ 0 : 1 element
//                             - 0 : Total Sugars
//                           ▿ 1 : 2 elements
//                             - 0 : Fat
//                             - 1 : Gluten
//                         ```
//                         So we need to replace both of them in this case and only retain the first one
//                         */
//
//                        /// Remove the column
//                        let _ = columns.remove(at: index)
//                    } else {
//                        /// Replace it
//                        columns[index] = column
//                    }
//
//
//                } else if columns.containsArrayWithAnAttributeFrom(column) {
//                    /// Ignore it
//                } else if let index = columns.indexOfArrayContainingAnyAttribute(in: column) {
//                    /// This `column` has attributes that another added `column has`
//                    if columns[index].count < column.count {
//                        /// This column has more attributes, so replace the smaller one with it
//                        columns[index] = column
//                    }
            } else {
                
                /// Otherwise, set it as a new column
                columns.append(column)
            }
        }
        
        /// Sort the columns by the `text.rect.midX` values (so that we get them in the order they appear), and only return the `attribute`s
        let columnsOfAttributes = columns.sorted(by: {
            $0.averageMidX < $1.averageMidX
        })
        
        guard columnsOfAttributes.count > 1 else {
            return columnsOfAttributes
        }
        
        /// If we've got more than one column, remove any that's less than 3 first
        var unfiltered = columnsOfAttributes.filter { $0.count >= 3 }
//        var filtered: [[Attribute]] = []
//        for array in unfiltered {
//            if
//        }
//        if columnsOfAttributes.count > 1 {
//            return columnsOfAttributes.filter { $0.count >= 3 }
//        } else {
        if !unfiltered.contains(.energy),
           let firstEnergyText = texts(for: .energy).first
        {
            let attributeText = AttributeText(attribute: .energy, text: firstEnergyText)
            unfiltered[0].insert(attributeText, at: 0)
        }
        
        return unfiltered
    }
    
    func getColumnOfNutrientLabelTexts(startingFrom startingText: RecognizedText) -> [RecognizedText] {
        
        // print("Getting column starting from: \(startingText.string)")

        let BoundingBoxMinXDeltaThreshold = 0.26
        var array: [RecognizedText] = [startingText]
        
        var skipPassUsed = false
        
        /// Now go upwards to get nutrient-attribute texts in same column as it
        let textsAbove = texts.filterColumn(of: startingText, preceding: true).filter { !$0.string.isEmpty }.reversed()
        
        // print("  ⬆️ textsAbove: \(textsAbove.map { $0.string } )")

        for text in textsAbove {
            // print("    Checking: \(text.string)")
            let boundingBoxMinXDelta = abs(text.boundingBox.minX - startingText.boundingBox.minX)
            
            /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
            guard boundingBoxMinXDelta < BoundingBoxMinXDeltaThreshold else {
                // print("    ignoring because boundingBoxMinXDelta = \(boundingBoxMinXDelta)")
                continue
            }
            
            /// Until we reach a non-nutrient-attribute text
            guard text.string.containsNutrientAttributesOrSkippableTableElements else {
                if skipPassUsed {
                    // print("    ✋🏽 ending search because no nutrient attributes can be detected in string AND skip pass was used")
                    break
                } else if text.string.terminatesColumnWiseAttributeSearch {
                    // print("    ✋🏽 ending search because cannot use skipPass")
                    break
                } else {
                    // print("    ignoring and using up skipPass")
                    skipPassUsed = true
                    continue
                }
            }
            
            skipPassUsed = false

            /// Skip over title attributes, but don't stop searching because of them
            guard !text.string.isSkippableTableElement else {
                continue
            }

            /// Insert these into the start of our column of labels as we read them in
            array.insert(text, at: 0)
        }

        /// Reset skipPass
        skipPassUsed = false
        
        /// Now do the same thing downwards
        let textsBelow = texts.filterColumn(of: startingText, preceding: false).filter { !$0.string.isEmpty }
        
        // print("  ⬇️ textsBelow: \(textsBelow.map { $0.string } )")

        for text in textsBelow {
            // print("    Checking: \(text.string)")
            let boundingBoxMinXDelta = abs(text.boundingBox.minX - startingText.boundingBox.minX)
            
            /// Ignore `text`s that are clearly not in-line with the `startingText`, in terms of its `boundingBox.minX` being more than `0.05` from the `startingText`s
            guard boundingBoxMinXDelta < BoundingBoxMinXDeltaThreshold else {
                // print("    ignoring because boundingBoxMinXDelta = \(boundingBoxMinXDelta)")
                continue
            }
            
            guard text.string.containsNutrientAttributesOrSkippableTableElements else {
                if skipPassUsed {
                    // print("    ✋🏽 ending search because no nutrient attributes can be detected in string AND skip pass was used")
                    break
                } else if text.string.terminatesColumnWiseAttributeSearch {
                    // print("    ✋🏽 ending search because cannot use skipPass")
                    break
                } else {
                    // print("    ignoring and using up skipPass")
                    skipPassUsed = true
                    continue
                }
            }
            
            skipPassUsed = false
            
            /// Skip over title attributes, but don't stop searching because of them
            guard !text.string.isSkippableTableElement else {
                continue
            }
            
            array.append(text)
        }

        // print("    ✨Got: \(array.description)")
        // print(" ")
        // print(" ")
        return array
    }
    
    func getUniqueAttributeTextsFrom(_ texts: [RecognizedText]) -> [AttributeText]? {
        var lastAddedAttribute: Attribute? = nil
        var attributeTexts: [AttributeText] = []
        for text in texts {
            let attributes = Attribute.detect(in: text.string)
            for attribute in attributes {
                /// Make sure each `Attribute` detected in this text hasn't already been added, and is also a nutrient (for edge cases where strings containing both a nutrient and a serving (or other type) of attribute may have been picked up and then the nutrient attribute disregarded
                guard !attributeTexts.contains(where: { $0.attribute.isSameAttribute(as: attribute) }),
                      attribute.isNutrientAttribute
                else { continue }
                
                /// If this is the `nutrientLabelTotal` attribute (where `Total` may come after a nutrient)
                guard attribute != .nutrientLabelTotal else {
                    /// Check if the last attribute appended supports total
                    guard let lastAttributeText = attributeTexts.last, lastAttributeText.attribute.supportsTotalLabel else {
                        continue
                    }
                    
                    /// If it does, add this text to its list of texts so that its considered when finding values in-line with it
                    attributeTexts[attributeTexts.count-1].allTexts.append(text)
                    continue
                }
                
                /// If this is part of the last added attribute, simply append the text to its `allTexts`
                if let index = attributeTexts.firstIndex(where: { $0.attribute == attribute }) {
                    guard let lastAddedAttribute = lastAddedAttribute, lastAddedAttribute == attribute else {
                        continue
                    }
                    attributeTexts[index].allTexts.append(text)
                } else {
                    attributeTexts.append(AttributeText(attribute: attribute,
                                                        text: text,
                                                        allTexts: [text]))
                    lastAddedAttribute = attribute
                }
            }
        }
        return attributeTexts.count > 0 ? attributeTexts : nil
    }
}
