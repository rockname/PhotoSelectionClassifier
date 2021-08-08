import Foundation
import CoreML
import Vision
import CoreImage

enum PhotoSelectionLabel: String {
    case selected = "Selected"
    case notSelected = "NotSelected"
}

struct PhotoSelectionImageClassifier {
    private let classifierFileManager: PhotoSelectionClassifierFileManager

    init(classifierFileManager: PhotoSelectionClassifierFileManager = .init()) {
        self.classifierFileManager = classifierFileManager
    }

    func execute(image: CGImage) async throws -> PhotoSelectionLabel {
        typealias ClassifiedResultContinuation = CheckedContinuation<PhotoSelectionLabel, Error>
        return try await withCheckedThrowingContinuation { (continuation: ClassifiedResultContinuation) in
            do {
                let modelURL = classifierFileManager.compiledClassifierURL
                let model = try MLModel(contentsOf: modelURL)
                let classifier = try VNCoreMLModel(for: model)
                let request = VNCoreMLRequest(model: classifier) { request, error in
                    guard let results = request.results else {
                        continuation.resume(throwing: error!)
                        return
                    }

                    let classification = results.first! as! VNClassificationObservation
                    continuation.resume(returning: PhotoSelectionLabel(rawValue: classification.identifier)!)
                }
                request.imageCropAndScaleOption = .centerCrop
                DispatchQueue.global(qos: .userInitiated).async {
                    let handler = VNImageRequestHandler(cgImage: image, orientation: .up)
                    do {
                        try handler.perform([request])
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
