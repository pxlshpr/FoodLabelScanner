import SwiftUI
import VisionSugar

public struct FoodLabelScanner {
    
    var image: UIImage
    var contentSize: CGSize
    
    let configs: [RecognizeTextConfiguration] = [
        RecognizeTextConfiguration(level: .accurate, languageCorrection: true),
        RecognizeTextConfiguration(level: .accurate, languageCorrection: false),
        RecognizeTextConfiguration(level: .fast)
    ]
    
    public init(image: UIImage, contentSize: CGSize) {
        self.image = image
        self.contentSize = contentSize
    }
    
    public func getScanResults() async throws {
        let start = CFAbsoluteTime()
        let textSets = try await image.recognizedTextSets(for: configs, inContentSize: contentSize)
        let end = CFAbsoluteTime()
        print("We've got: \(textSets.count) sets (took: \(end-start)s)")
    }
}
