import SwiftUI
import VisionSugar
import CoreMedia

public struct FoodLabelScanner {
    
    var image: UIImage
    var contentSize: CGSize
    
    public init(image: UIImage, contentSize: CGSize? = nil) {
        self.image = image
        self.contentSize = contentSize ?? image.size
    }
    
    public func scan() async throws -> ScanResultSet {
        try await image
            .recognizedTextSet(for: .accurate, inContentSize: contentSize)
            .scanResultSet
    }
}

extension RecognizedTextSet {
    var scanResultSet: ScanResultSet {
        return ScanResultSet(
            inline: inlineResult,
            tabular: tabularResult,
            texts: texts
        )
    }
}
