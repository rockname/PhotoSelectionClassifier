import SwiftUI
import Photos

class AlbumGridViewModel: ObservableObject {
    private let albumPhoto: AlbumPhoto
    private let photoRepository: PhotoRepository
    private let photoImageRequester: PhotoImageRequester

    @Published var image: UIImage?

    init(
        albumPhoto: AlbumPhoto,
        photoRepository: PhotoRepository = PhotoDataRepository(),
        photoImageRequester: PhotoImageRequester = .init()
    ) {
        self.albumPhoto = albumPhoto
        self.photoRepository = photoRepository
        self.photoImageRequester = photoImageRequester
    }

    func onAppear() async {
        guard let photo = photoRepository.fetchPhoto(with: albumPhoto.localIdentifier) else { return }

        do {
            image = try await photoImageRequester.execute(
                phAsset: photo.phAsset,
                targetSize: PhotoSelectionTrainer.minimumTrainedImageSize
            )
        } catch {
            print(error)
        }
    }
}
