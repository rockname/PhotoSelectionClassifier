import Foundation
import Photos

struct Photo: Hashable {
    let phAsset: PHAsset

    init(phAsset: PHAsset) {
        self.phAsset = phAsset
    }
}
