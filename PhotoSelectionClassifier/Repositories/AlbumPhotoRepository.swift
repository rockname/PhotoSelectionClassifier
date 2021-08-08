import Foundation
import CoreData

protocol AlbumPhotoRepository {
    func fetchAlbumPhotos() async throws -> [AlbumPhoto]
    func sharePhotosToAlbum(photos: [Photo]) async throws
    func fetchOldestAndLatestTakenAt() async throws -> (oldest: Date, latest: Date)?
}

struct AlbumPhotoDataRepository: AlbumPhotoRepository {
    enum AlbumPhotoError: Error {
        case batchInsertError
    }

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func fetchAlbumPhotos() async throws -> [AlbumPhoto] {
        try await context.perform {
            let request = NSFetchRequest<CoreDataAlbumPhoto>(entityName: String(describing: CoreDataAlbumPhoto.self))
            let fetchResult = try request.execute()
            return fetchResult.compactMap {
                AlbumPhoto(
                    id: $0.id!,
                    localIdentifier: $0.localIdentifier!,
                    takenAt: $0.takenAt!
                )
            }
        }
    }

    func fetchOldestAndLatestTakenAt() async throws -> (oldest: Date, latest: Date)? {
        try await context.perform {
            guard
                let oldestAlbumPhoto = try fetchTop(ascending: true),
                let latestAlbumPhoto = try fetchTop(ascending: false)
            else {
                return nil
            }

            return (
                oldest: oldestAlbumPhoto.takenAt,
                latest: latestAlbumPhoto.takenAt
            )
        }
    }

    func sharePhotosToAlbum(photos: [Photo]) async throws {
        try await context.perform {
            var index = 0
            let total = photos.count

            let insertRequest = NSBatchInsertRequest(
                entity: CoreDataAlbumPhoto.entity()
            ) { (managedObject: NSManagedObject) in
                guard index < total else { return true }

                if let albumPhoto = managedObject as? CoreDataAlbumPhoto {
                    let data = photos[index]
                    albumPhoto.id = UUID()
                    albumPhoto.localIdentifier = data.phAsset.localIdentifier
                    albumPhoto.takenAt = data.phAsset.creationDate!
                }
                index += 1
                return false
            }
            let fetchResult = try context.execute(insertRequest)
            guard
                let batchInsertResult = fetchResult as? NSBatchInsertResult,
                let success = batchInsertResult.result as? Bool,
                success
            else {
                throw AlbumPhotoError.batchInsertError
            }
        }
    }

    private func fetchTop(ascending: Bool) throws -> AlbumPhoto? {
        let request = NSFetchRequest<CoreDataAlbumPhoto>(entityName: String(describing: CoreDataAlbumPhoto.self))
        let sortDescriptor = NSSortDescriptor(key: "takenAt", ascending: ascending)
        request.sortDescriptors = [sortDescriptor]
        request.fetchLimit = 1
        let fetchResult = try request.execute()
        return fetchResult.compactMap {
            AlbumPhoto(
                id: $0.id!,
                localIdentifier: $0.localIdentifier!,
                takenAt: $0.takenAt!
            )
        }.first
    }
}
