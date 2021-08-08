import UIKit
import Photos

struct PhotoImageRequester {
    enum PhotoImageRequesterError: Error {
        case failedToFetchImage
    }

    private let phImageManager: PHImageManager

    init(phImageManager: PHImageManager = .default()) {
        self.phImageManager = phImageManager
    }

    func execute(
        phAsset: PHAsset,
        targetSize: CGSize,
        deliveryMode: PHImageRequestOptionsDeliveryMode = .highQualityFormat
    ) async throws -> UIImage {
        typealias RequestedImageContinuation = CheckedContinuation<UIImage, Error>
        return try await withCheckedThrowingContinuation { (continuation: RequestedImageContinuation) in
            let options: PHImageRequestOptions = {
                let options = PHImageRequestOptions()
                options.deliveryMode = deliveryMode
                return options
            }()
            phImageManager.requestImage(
                for: phAsset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { (image, info) in
                guard let image = image else {
                    continuation.resume(throwing: PhotoImageRequesterError.failedToFetchImage)
                    return
                }

                continuation.resume(returning: image)
            }
        }
    }
}
