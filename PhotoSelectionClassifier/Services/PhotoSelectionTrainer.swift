import UIKit
import Photos
import CreateML
import CoreML

actor PhotoSelectionTrainer {
    private let albumPhotoRepository: AlbumPhotoRepository
    private let photoRepository: PhotoRepository
    private let photoImageRequester: PhotoImageRequester
    private let classifierFileManager: PhotoSelectionClassifierFileManager

    init(
        albumPhotoRepository: AlbumPhotoRepository = AlbumPhotoDataRepository(),
        photoRepository: PhotoRepository = PhotoDataRepository(),
        photoImageRequester: PhotoImageRequester = .init(),
        classifierFileManager: PhotoSelectionClassifierFileManager = .init()
    ) {
        self.albumPhotoRepository = albumPhotoRepository
        self.photoRepository = photoRepository
        self.photoImageRequester = photoImageRequester
        self.classifierFileManager = classifierFileManager
    }

    func execute(selectedLocalIdentifiers: [String]) async {
        do {
            print("👀 Checking if enough training data")
            var photoSelections = try await fetchPhotoSelections(selectedLocalIdentifiers: selectedLocalIdentifiers)
            let selectedCount = photoSelections.filter({ $0.isSelected }).count
            let notSelectedCount = photoSelections.count - selectedCount
            print("🚩 Selected: \(selectedCount), Not Selected: \(notSelectedCount)")
            let minPhotoSelectionCount = min(selectedCount, notSelectedCount)
            guard minPhotoSelectionCount >= 20 else {
                print("❎ Not enough training data yet")
                return
            }

            print("⛰ Aligning the number of Selected / Not selected to the smaller one")
            photoSelections = filterPhotoSelections(photoSelections, limit: minPhotoSelectionCount)

            print("""
            ⚡️ Preprocessing training data
              - Fetching image data
              - Resizing images to minimum required size
              - Outputing image data to the training data directory
            """
            )
            try classifierFileManager.cleanTrainingDataDirectory()
            let photoSelectionImagesFetcher = PhotoSelectionImagesFetcher(
                photoSelections: photoSelections,
                photoImageRequester: photoImageRequester
            )
            for try await result in photoSelectionImagesFetcher {
                let (photoSelection, image) = result
                let resizedImage = resizeImage(image, targetSize: PhotoSelectionTrainer.minimumTrainedImageSize)
                let imageURL = (
                    photoSelection.isSelected
                    ? classifierFileManager.selectedDataDirectory
                    : classifierFileManager.notSelectedDataDirectory
                )
                    .appendingPathComponent("\(UUID().uuidString).jpg")
                let imageData = resizedImage.jpegData(compressionQuality: 1.0)!
                try imageData.write(to: imageURL)
            }

            print("🤖 Training photo selections")
            let parameters = MLImageClassifier.ModelParameters(
                featureExtractor: .scenePrint(revision: 1),
                validationData: nil,
                maxIterations: 20,
                augmentationOptions: [.crop, .blur, .exposure, .flip, .noise, .rotation]
            )
            let trainer = ImageClassifierTrainer()
            let imageClassifier = try await trainer.execute(
                trainingDataDirectory: classifierFileManager.trainingDataDirectory,
                modelParameters: parameters
            )
            print("🔧 Compiling a trained model and saving permanently")
            let imageClassifierURL = classifierFileManager.classifierURL
            try imageClassifier.write(
                to: imageClassifierURL,
                metadata: .init(
                    author: "rockname",
                    shortDescription: "Photo Selection Classifier"
                )
            )
            let temporaryClassifierURL = try MLModel.compileModel(at: imageClassifierURL)
            try classifierFileManager.preserveTemporaryClassifierURL(temporaryClassifierURL)
        } catch {
            print(error)
        }
    }

    private func fetchPhotoSelections(selectedLocalIdentifiers: [String]) async throws -> [PhotoSelection] {
        guard let (oldest, latest) = try await albumPhotoRepository.fetchOldestAndLatestTakenAt() else { return [] }

        let targetPhotos = photoRepository.fetchPhotos(from: oldest, to: latest)
        return targetPhotos.map { photo in
            if selectedLocalIdentifiers.contains(where: { selectedLocalIdentifier in
                selectedLocalIdentifier == photo.phAsset.localIdentifier
            }) {
                return PhotoSelection(photo: photo, isSelected: true)
            } else {
                return PhotoSelection(photo: photo, isSelected: false)
            }
        }
    }

    private func filterPhotoSelections(_ photoSelections: [PhotoSelection], limit: Int) -> [PhotoSelection] {
        let descendingPhotoSelections = photoSelections.sorted { $0.photo.phAsset.creationDate! > $1.photo.phAsset.creationDate! }
        var selected = [PhotoSelection]()
        var notSelected = [PhotoSelection]()
        for photoSelection in descendingPhotoSelections {
            if photoSelection.isSelected {
                selected.append(photoSelection)
            } else {
                notSelected.append(photoSelection)
            }

            if [selected.count, notSelected.count].contains(where: { count in
                count >= limit
            }) {
                break
            }
        }
        return selected + notSelected
    }

    private func fetchTargetImages(photoSelections: [PhotoSelection]) async throws -> [(photoSelection: PhotoSelection, image: UIImage)] {
        var targetImages = [(photoSelection: PhotoSelection, image: UIImage)]()
        try await withThrowingTaskGroup(of: (PhotoSelection, UIImage).self) { [photoImageRequester] group in
            for photoSelection in photoSelections {
                group.addTask {
                    return (
                        photoSelection,
                        try await photoImageRequester.execute(
                            phAsset: photoSelection.photo.phAsset,
                            targetSize: PHImageManagerMaximumSize,
                            deliveryMode: .highQualityFormat
                        )
                    )
                }

                for try await (photoSelection, image) in group {
                    targetImages.append((photoSelection: photoSelection, image: image))
                }
            }
        }
        return targetImages
    }

    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        return UIGraphicsImageRenderer(size: newSize).image { (context) in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private struct PhotoSelectionImagesFetcher: AsyncSequence, AsyncIteratorProtocol {
        typealias Element = (photoSelection: PhotoSelection, image: UIImage)

        private var index = 0

        let photoSelections: [PhotoSelection]
        let photoImageRequester: PhotoImageRequester

        init(
            photoSelections: [PhotoSelection],
            photoImageRequester: PhotoImageRequester
        ) {
            self.photoSelections = photoSelections
            self.photoImageRequester = photoImageRequester
        }

        mutating func next() async throws -> (photoSelection: PhotoSelection, image: UIImage)? {
            defer { index += 1 }

            if index >= photoSelections.count - 1 {
                return nil
            } else {
                return (
                    photoSelection: photoSelections[index],
                    image: try await photoImageRequester.execute(
                        phAsset: photoSelections[index].photo.phAsset,
                        targetSize: PhotoSelectionTrainer.minimumTrainedImageSize
                    )
                )
            }
        }

        func makeAsyncIterator() -> PhotoSelectionImagesFetcher { self }
    }
}

extension PhotoSelectionTrainer {
    static let minimumTrainedImageSize = CGSize(width: 300, height: 300)
}
