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
    
    public func scan() async throws -> ScanResult {
        let textSet = try await image.recognizedTextSet(for: .accurate, inContentSize: contentSize)
        
        let observations = getObservations(from: textSet)
        return ScanResult(
            serving: observations.serving,
            nutrients: observations.nutrients,
            texts: ScanResult.Texts(accurate: textSet.texts, accurateWithoutLanguageCorrection: [], fast: [])
        )
    }
    
    func getObservations(from textSet: RecognizedTextSet) -> [Observation] {
        
        let inline = textSet.inlineObservations
        
        if inline.isValid {
            print("🥕 using inline")
            return inline
        } else {
            print("🥕 using tabular")
            return textSet.tabularObservations
        }
    }
}

public struct FoodLabelLiveScanner {
    
    var sampleBuffer: CMSampleBuffer

    public init(sampleBuffer: CMSampleBuffer) {
        self.sampleBuffer = sampleBuffer
    }
    
    public func scan() async throws -> ScanResult {
        let textSet = try await sampleBuffer.recognizedTextSet(for: .accurate, inContentSize: UIScreen.main.bounds.size)
        
        let observations = textSet.inlineObservations
//        let observations = getObservations(from: textSet)
        return ScanResult(
            serving: observations.serving,
            nutrients: observations.nutrients,
            texts: ScanResult.Texts(accurate: textSet.texts, accurateWithoutLanguageCorrection: [], fast: [])
        )
    }

}
