import Foundation
import PrepShared

public extension ScanResult.Serving {
    var amount: Double? { amountText?.double }
    var unit: FoodLabelUnit? { unitText?.unit }
    var unitName: String? { unitNameText?.string }
    
    var amountId: UUID? { amountText?.text.id }
    var unitId: UUID? { unitText?.text.id }
    var unitNameId: UUID? { unitNameText?.text.id }
}

public extension ScanResult.Serving.EquivalentSize {
    var amount: Double { amountText.double }
    var unit: FoodLabelUnit? { unitText?.unit }
    var unitName: String? { unitNameText?.string }
    
    var amountId: UUID { amountText.text.id }
    var unitId: UUID? { unitText?.text.id }
    var unitNameId: UUID? { unitNameText?.text.id }
}

public extension ScanResult.Serving.PerContainer {
    var amount: Double { amountText.double }
    var name: String? { nameText?.string }
//    var containerName: ContainerName? { identifiableContainerName?.containerName }
    
    var amountId: UUID { amountText.text.id }
    var nameId: UUID? { nameText?.text.id }
//    var containerNameId: UUID? { identifiableContainerName?.id }
}

public extension ScanResult.Headers {
    var header1Type: HeaderType? { headerText1?.type }
    var header2Type: HeaderType? { headerText2?.type }

    var header1Id: UUID? { headerText1?.text.id }
    var header2Id: UUID? { headerText2?.text.id }
}

public extension ScanResult.Nutrients.Row {
    var attribute: Attribute { attributeText.attribute }
    var value1: FoodLabelValue? { valueText1?.value }
    var value2: FoodLabelValue? { valueText2?.value }
    
    var attributeId: UUID { attributeText.text.id }
    var value1Id: UUID? { valueText1?.text.id }
    var value2Id: UUID? { valueText2?.text.id }
}

//public extension ScanResult {
//    var headerServing: HeaderText.Serving? {
//        servingHeaderText?.serving
//    }
//    
//    var servingHeaderText: HeaderText? {
//        if let type = nutrients.header1Type,
//           type == .perServing {
//            return nutrients.headerText1
//        }
//        if let type = nutrients.header2Type,
//           type == .perServing {
//            return nutrients.headerText2
//        }
//        return nil
//    }
//}
