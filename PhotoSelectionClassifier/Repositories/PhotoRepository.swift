import Foundation
import Photos

protocol PhotoRepository {
    func fetchPhotos(excludingLocalIdentifiers: [String]) -> [Photo]
    func fetchPhotos(with localIdentifiers: [String]) -> [Photo]
    func fetchPhoto(with localIdentifier: String) -> Photo?
    func fetchPhotos(from startDate: Date, to endDate: Date) -> [Photo]
}

struct PhotoDataRepository: PhotoRepository {
    func fetchPhotos(excludingLocalIdentifiers: [String]) -> [Photo] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format:"NOT (localIdentifier IN %@)", excludingLocalIdentifiers)
        let result = PHAsset.fetchAssets(with: options)
        var photos = [Photo]()
        result.enumerateObjects { (asset, _, _) in
            photos.append(Photo(phAsset: asset))
        }
        return photos
    }

    func fetchPhotos(with localIdentifiers: [String]) -> [Photo] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType = %d",
            PHAssetMediaType.image.rawValue
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(withLocalIdentifiers: localIdentifiers, options: options)
        var photos = [Photo]()
        result.enumerateObjects { (asset, _, _) in
            photos.append(Photo(phAsset: asset))
        }
        return photos
    }

    func fetchPhoto(with localIdentifier: String) -> Photo? {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
            format: "mediaType = %d",
            PHAssetMediaType.image.rawValue
        )
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: options)
        return result.firstObject.map(Photo.init(phAsset:))
    }

    func fetchPhotos(from fromDate: Date, to toDate: Date) -> [Photo] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(
          format: "mediaType = %d AND (creationDate >= %@) AND (creationDate <= %@)",
          PHAssetMediaType.image.rawValue,
          fromDate as NSDate,
          toDate as NSDate
        )
        let result = PHAsset.fetchAssets(with: options)
        var photos = [Photo]()
        result.enumerateObjects { (asset, _, _) in
            photos.append(Photo(phAsset: asset))
        }
        return photos
    }
}
