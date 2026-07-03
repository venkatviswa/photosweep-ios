//
//  GooglePhotoImporter.swift
//  PhotoSweep
//
//  Converts picked Google Photos media items into UnifiedPhoto records.
//  File size and hashes are filled in later by the detection pipeline.
//

import Foundation

struct GooglePhotoImporter {
    static func makeUnifiedPhoto(from item: PickedMediaItem, scanSessionId: UUID) -> UnifiedPhoto {
        let file = item.mediaFile
        let metadata = file?.mediaFileMetadata
        return UnifiedPhoto(
            source: .googlePhotos,
            scanSessionId: scanSessionId,
            googleMediaItemId: item.id,
            creationDate: item.createTime.flatMap(DateNormalizer.date(fromRFC3339:)),
            originalFilename: file?.filename,
            width: metadata?.width ?? 0,
            height: metadata?.height ?? 0,
            mediaType: mediaType(forPickerType: item.type),
            cameraMake: metadata?.cameraMake,
            cameraModel: metadata?.cameraModel
        )
    }

    static func mediaType(forPickerType type: String?) -> MediaType {
        type == "VIDEO" ? .video : .photo
    }
}
