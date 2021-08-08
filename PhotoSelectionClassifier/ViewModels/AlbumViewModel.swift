import SwiftUI

class AlbumViewModel: ObservableObject {
    private let albumPhotoRepository: AlbumPhotoRepository
    private let photoSelectionTrainer: PhotoSelectionTrainer

    private var trainingTask: Task<(), Never>?

    @Published var albumPhotos = [AlbumPhoto]()

    init(
        albumPhotoRepository: AlbumPhotoRepository = AlbumPhotoDataRepository(),
        photoSelectionTrainer: PhotoSelectionTrainer = .init()
    ) {
        self.albumPhotoRepository = albumPhotoRepository
        self.photoSelectionTrainer = photoSelectionTrainer
    }

    func onAppear() async {
        await loadAlbumPhotos()
        await startTraining()
    }

    func onPhotoPickerViewDismissed() async {
        await loadAlbumPhotos()
        await startTraining()
    }

    private func loadAlbumPhotos() async {
        do {
            albumPhotos = try await albumPhotoRepository.fetchAlbumPhotos()
        } catch {
            print(error)
        }
    }

    private func startTraining() async {
        trainingTask?.cancel()
        trainingTask = Task {
            return await photoSelectionTrainer.execute(selectedLocalIdentifiers: albumPhotos.map { $0.localIdentifier })
        }
    }
}
