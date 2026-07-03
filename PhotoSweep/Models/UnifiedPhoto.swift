//
//  UnifiedPhoto.swift
//  PhotoSweep
//
//  The core entity: a single photo normalized across iCloud and Google Photos.
//  See SPEC.md §3.1.
//

import Foundation
import SwiftData

@Model
final class UnifiedPhoto {
    // Identity
    @Attribute(.unique) var id: UUID
    var localIdentifier: String?    // PHAsset.localIdentifier (iCloud)
    var googleMediaItemId: String?  // Google Photos mediaItem.id
    var source: PhotoSource

    // Content hashes
    var sha256Hash: String?         // Exact duplicate detection
    var perceptualHash: String?     // Near-duplicate detection (pHash)

    // Metadata
    var creationDate: Date?
    var originalFilename: String?
    var fileSize: Int64             // Bytes
    var width: Int
    var height: Int
    var mediaType: MediaType

    // EXIF
    var cameraMake: String?
    var cameraModel: String?
    var lensInfo: String?
    var gpsLatitude: Double?
    var gpsLongitude: Double?

    // Scan state
    var scanSessionId: UUID
    var duplicateGroupId: UUID?
    var isReviewed: Bool
    var disposalAction: DisposalAction? // nil = no action taken
    var qualityScore: Float?            // 0.0–1.0, AI-assessed quality

    // Thumbnail
    @Attribute(.externalStorage) var thumbnailData: Data? // Low-res thumbnail for display

    init(
        id: UUID = UUID(),
        source: PhotoSource,
        scanSessionId: UUID,
        localIdentifier: String? = nil,
        googleMediaItemId: String? = nil,
        sha256Hash: String? = nil,
        perceptualHash: String? = nil,
        creationDate: Date? = nil,
        originalFilename: String? = nil,
        fileSize: Int64 = 0,
        width: Int = 0,
        height: Int = 0,
        mediaType: MediaType = .photo,
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        lensInfo: String? = nil,
        gpsLatitude: Double? = nil,
        gpsLongitude: Double? = nil,
        duplicateGroupId: UUID? = nil,
        isReviewed: Bool = false,
        disposalAction: DisposalAction? = nil,
        qualityScore: Float? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.source = source
        self.scanSessionId = scanSessionId
        self.localIdentifier = localIdentifier
        self.googleMediaItemId = googleMediaItemId
        self.sha256Hash = sha256Hash
        self.perceptualHash = perceptualHash
        self.creationDate = creationDate
        self.originalFilename = originalFilename
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.mediaType = mediaType
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.lensInfo = lensInfo
        self.gpsLatitude = gpsLatitude
        self.gpsLongitude = gpsLongitude
        self.duplicateGroupId = duplicateGroupId
        self.isReviewed = isReviewed
        self.disposalAction = disposalAction
        self.qualityScore = qualityScore
        self.thumbnailData = thumbnailData
    }
}

extension UnifiedPhoto {
    /// Pixel count, used by quality scoring (higher resolution wins).
    var pixelCount: Int { width * height }
}
