import SwiftUI
import Photos

class PhotoGridViewModel: ObservableObject {
    private let photoImageRequester: PhotoImageRequester
    private var shouldAutoSelectOnAppear = false

    @Published var image: UIImage?
    @Published var isSelected = false

    let photo: Photo

    init(
        photo: Photo,
        photoImageRequester: PhotoImageRequester = .init()
    ) {
        self.photo = photo
        self.photoImageRequester = photoImageRequester
    }

    func onAppear() async {
        do {
            let image = try await photoImageRequester.execute(
                phAsset: photo.phAsset,
                targetSize: PhotoSelectionTrainer.minimumTrainedImageSize
            )
            if shouldAutoSelectOnAppear {
                try await classifyPhotoSelection(image: image.cgImage!)
            }
            self.image = image
        } catch {
            print(error)
        }
    }

    func onPhotoGridTapped() {
        withAnimation {
            isSelected.toggle()
        }
    }

    func onAutoSelectButtonTapped() async throws {
        if let image = image {
            do {
                try await classifyPhotoSelection(image: image.cgImage!)
            } catch {
                print(error)
            }
        } else {
            shouldAutoSelectOnAppear = true
        }
    }

    private func classifyPhotoSelection(image: CGImage) async throws {
        let result = try await PhotoSelectionImageClassifier().execute(image: image)
        await reflectPhotoSelection(result)
    }

    @MainActor
    private func reflectPhotoSelection(_ photoSelection: PhotoSelectionLabel) {
        withAnimation {
            switch photoSelection {
            case .selected: isSelected = true
            case .notSelected: isSelected = false
            }
        }
    }
}

extension PhotoGridViewModel: Identifiable {
    var id: String {
        photo.phAsset.localIdentifier
    }
}
