//
//  ICloudPhotoService.swift
//  PhotoSweep
//
//  Thin wrapper over PhotoKit authorization and asset fetching.
//
//  Note on access level: PhotoKit has no "read-only" authorization tier — reading
//  the library requires `.readWrite` (see CLAUDE.md → API Quirks). We request
//  `.readWrite` solely to read; no write/delete happens unless the user explicitly
//  triggers a disposal action later.
//

import Foundation
import os
import Photos

/// Simplified authorization status surfaced to the UI layer.
enum PhotoAuthorization: Sendable {
    case authorized
    case limited
    case denied
    case restricted
    case notDetermined

    /// Whether we have enough access to read the library for scanning.
    var canReadLibrary: Bool {
        self == .authorized || self == .limited
    }
}

final class ICloudPhotoService: Sendable {
    private let logger = Logger(subsystem: "com.photosweep.app", category: "ICloudPhotoService")

    /// Current authorization status without prompting the user.
    func currentAuthorization() -> PhotoAuthorization {
        Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    /// Requests photo library access, prompting the system dialog if undetermined.
    func requestAuthorization() async -> PhotoAuthorization {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        let mapped = Self.map(status)
        logger.info("Photo authorization resolved: \(String(describing: mapped), privacy: .public)")
        return mapped
    }

    /// Fetches all image assets, newest first. Metadata only — no image data is loaded here.
    func fetchImageAssets() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        return PHAsset.fetchAssets(with: options)
    }

    private static func map(_ status: PHAuthorizationStatus) -> PhotoAuthorization {
        switch status {
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
}
