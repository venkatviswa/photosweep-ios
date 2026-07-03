//
//  ICloudPhotoImporter.swift
//  PhotoSweep
//
//  Converts PhotoKit PHAssets into UnifiedPhoto records (metadata only).
//  Image data and hashes are computed later, in the duplicate-detection pipeline.
//

import Foundation
import Photos

struct ICloudPhotoImporter {
    /// Builds a `UnifiedPhoto` from a PHAsset's metadata. No image data is downloaded.
    ///
    /// `fileSize`, EXIF camera fields, and hashes are intentionally left at their
    /// defaults here — they are populated during the hashing pass (Phase 3) when we
    /// actually request image bytes.
    func makeUnifiedPhoto(from asset: PHAsset, scanSessionId: UUID) -> UnifiedPhoto {
        let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename

        let photo = UnifiedPhoto(
            source: .icloud,
            scanSessionId: scanSessionId,
            localIdentifier: asset.localIdentifier,
            creationDate: asset.creationDate,
            originalFilename: filename,
            width: asset.pixelWidth,
            height: asset.pixelHeight,
            mediaType: Self.mediaType(for: asset)
        )

        if let location = asset.location {
            photo.gpsLatitude = location.coordinate.latitude
            photo.gpsLongitude = location.coordinate.longitude
        }

        return photo
    }

    /// Maps a PHAsset to our coarse `MediaType`. Extracted so the branching logic is
    /// unit-testable via `classify(...)` without constructing a real PHAsset.
    static func mediaType(for asset: PHAsset) -> MediaType {
        classify(
            isVideo: asset.mediaType == .video,
            isScreenshot: asset.mediaSubtypes.contains(.photoScreenshot),
            isLivePhoto: asset.mediaSubtypes.contains(.photoLive),
            isBurst: asset.representsBurst
        )
    }

    /// Pure classification logic, ordered most-specific first.
    static func classify(isVideo: Bool, isScreenshot: Bool, isLivePhoto: Bool, isBurst: Bool) -> MediaType {
        if isVideo { return .video }
        if isScreenshot { return .screenshot }
        if isLivePhoto { return .livePhoto }
        if isBurst { return .burst }
        return .photo
    }
}
