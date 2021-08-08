import Foundation
import Photos

struct AlbumPhoto: Identifiable, Codable {
    let id: UUID
    let localIdentifier: String
    let takenAt: Date
}
