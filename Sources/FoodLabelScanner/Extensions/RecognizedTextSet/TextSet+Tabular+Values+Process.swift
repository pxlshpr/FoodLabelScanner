import Foundation
import VisionSugar

extension RecognizedTextSet {

    static func process(valuesTextColumns: [ValuesTextColumn], attributes: [[AttributeText]], using textSet: RecognizedTextSet) -> [[ValuesTextColumn]] {
        let start = CFAbsoluteTimeGetCurrent()

        var columns = valuesTextColumns

        columns.removeTextsAboveEnergy(for: attributes)
        columns.removeTextsAboveHeader(from: textSet)
        columns.removeTextsBelowLastAttribute(of: attributes)
        columns.removeTextsWithMultipleNutrientValues()
        columns.removeTextsWithExtraLargeValues()
        columns.removeTextsWithHeaderAttributes()

        columns.removeDuplicateColumns()
        columns.removeEmptyColumns()
        columns.removeColumnsWithSingleValuesNotInColumnWithAllOtherSingleValues()
        columns.removeExtraLongFooterValuesWithNoAttributes(for: attributes)
        columns.removeInvalidColumns()
        columns.pickTopColumns(using: attributes)
        columns.removeColumnsWithServingAttributes()

        columns.removeColumnsWithNoValuesPastFirstAttributesColumn(in: attributes)

        columns.sort()
        columns.removeSubsetColumns()
        columns.splitUpColumnsWithAllMultiColumnedValues()
        columns.cleanupEnergyValues(using: attributes)

        columns.removeOverlappingTextsWithSameString()
        columns.removeFullyOverlappingTexts()

        columns.removeReferenceColumns()

        var groupedColumns = groupByAttributes(columns, attributes: attributes)
        groupedColumns.removeColumnsInSameColumnAsAttributes(in: attributes)
        groupedColumns.removeExtraneousColumns()
//        groupedColumns.removeInvalidValueTexts()
         print("⏱ processing columns took: \(CFAbsoluteTimeGetCurrent()-start)s")
        return groupedColumns
    }

}


extension RecognizedTextSet {
    /// - Group columns if `attributeTextColumns.count > 1`
    static func groupByAttributes(_ initialColumnsOfTexts: [ValuesTextColumn], attributes: [[AttributeText]]) -> [[ValuesTextColumn]] {
        
        let attributeColumns = attributes
        guard attributeColumns.count > 1 else {
            return [initialColumnsOfTexts]
        }
        
        var columnsOfTexts = initialColumnsOfTexts
        var groups: [[ValuesTextColumn]] = []

        /// For each Attribute Column
        for i in attributeColumns.indices {
            let attributeColumn = attributeColumns[i]

            /// Get the minX of the shortest attribute
            guard let attributeColumnMinX = attributeColumn.shortestText?.rect.minX else { continue }

            var group: [ValuesTextColumn] = []
            while group.count < 2 && !columnsOfTexts.isEmpty {
                let column = columnsOfTexts.removeFirst()

                /// Skip columns that are clearly to the left of this `attributeTextColumn`
                guard let columnMaxX = column.shortestText?.rect.maxX,
                      columnMaxX > attributeColumnMinX else {
                    continue
                }

                /// If we have another attribute column
                if i < attributeColumns.count - 1 {
                    /// If we have reached columns that is to the right of it
                    guard let nextAttributeColumnMinX = attributeColumns[i+1].shortestText?.rect.minX,
                          columnMaxX < nextAttributeColumnMinX else
                    {
                        /// Make sure we re-insert the column so that it's extracted by that column
                        columnsOfTexts.insert(column, at: 0)

                        /// Stop the loop so that the next attribute column is focused on
                        break
                    }
                }

                group.append(column)

                /// Skip columns that contain all nutrient attributes
//                guard !column.allElementsContainNutrientAttributes else {
//                    continue
//                }

                /// Skip columns that contain all percentage values
//                guard !column.allElementsArePercentageValues else {
//                    continue
//                }

                //TODO: Write this
                /// If this column has more elements than the existing (first) column and contains any texts belonging to it, replace it
//                if let existing = group.first,
//                    column.count > existing.count,
//                    column.containsTextsFrom(existing)
//                {
//                    group[0] = column
//                } else {
//                    group.append(column)
//                }
            }

            groups.append(group)
        }

        return groups
        
//        return [initialColumnsOfTexts]
    }
}
