import SwiftUI
import Photos
import CreateML

class PhotoPickerViewModel: ObservableObject {
    private let albumPhotoRepository: AlbumPhotoRepository
    private let photoRepository: PhotoRepository
    private let classifierFileManager: PhotoSelectionClassifierFileManager

    @Published var photoGridViewModels = [PhotoGridViewModel]()
    @Published var shouldDismiss: Bool = false
    @Published var showsAutoSelectButton: Bool = false

    init(
        albumPhotoRepository: AlbumPhotoRepository = AlbumPhotoDataRepository(),
        photoRepository: PhotoRepository = PhotoDataRepository(),
        classifierFileManager: PhotoSelectionClassifierFileManager = .init()
    ) {
        self.albumPhotoRepository = albumPhotoRepository
        self.photoRepository = photoRepository
        self.classifierFileManager = classifierFileManager
    }

    func onAppear() async {
        do {
            let albumPhotos = try await albumPhotoRepository.fetchAlbumPhotos()
            let excludingLocalIdentifiers = albumPhotos.map { $0.localIdentifier }
            photoGridViewModels = photoRepository.fetchPhotos(excludingLocalIdentifiers: excludingLocalIdentifiers)
                .map { photo in
                    PhotoGridViewModel(photo: photo)
                }
            showsAutoSelectButton = classifierFileManager.compiledClassifierFileExists
        } catch {
            print(error)
        }
    }

    func onShareButtonTapped() async {
        do {
            let selectedPhotos = photoGridViewModels.filter { $0.isSelected }.map { $0.photo }
            try await albumPhotoRepository.sharePhotosToAlbum(photos: selectedPhotos)
            shouldDismiss = true
        } catch {
            print(error)
        }
    }

    func onCloseButtonTapped() {
        shouldDismiss = true
    }

    func onAutoSelectButtonTapped() async {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for photoGridViewModel in photoGridViewModels {
                    group.addTask {
                        return try await photoGridViewModel.onAutoSelectButtonTapped()
                    }
                }
                for try await _ in group {}
            }
        } catch {
            print(error)
        }
    }
}
