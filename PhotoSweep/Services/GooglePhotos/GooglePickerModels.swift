//
//  GooglePickerModels.swift
//  PhotoSweep
//
//  Wire types for the Google Photos Picker API.
//  https://developers.google.com/photos/picker/reference/rest
//

import Foundation

/// A picking session. The user opens `pickerUri` (in the Google Photos app or
/// browser), selects photos, and `mediaItemsSet` flips to true.
struct PickerSession: Decodable, Sendable {
    let id: String
    let pickerUri: String
    let pollingConfig: PollingConfig?
    let mediaItemsSet: Bool?

    struct PollingConfig: Decodable, Sendable {
        let pollInterval: String? // protobuf Duration, e.g. "5s"
        let timeoutIn: String?
    }
}

/// A media item the user picked. Distinct from the legacy Library API shape:
/// file details live under `mediaFile`.
struct PickedMediaItem: Decodable, Sendable {
    let id: String
    let createTime: String?
    let type: String? // "PHOTO" | "VIDEO"
    let mediaFile: MediaFile?

    struct MediaFile: Decodable, Sendable {
        let baseUrl: String?
        let mimeType: String?
        let filename: String?
        let mediaFileMetadata: PickedMediaFileMetadata?
    }
}

struct PickedMediaFileMetadata: Decodable, Sendable {
    let width: Int?
    let height: Int?
    let cameraMake: String?
    let cameraModel: String?
}

struct PickedMediaItemsPage: Decodable, Sendable {
    let mediaItems: [PickedMediaItem]?
    let nextPageToken: String?
}
