//
//  PhotoThumbnailLoader.swift
//  PhotoSweep
//
//  Loads display thumbnails for iCloud assets on demand via PHImageManager.
//  Thumbnails are deliberately not persisted during metadata import (SPEC §4 Phase 1),
//  so the grid fetches them lazily here.
//

import Photos
import UIKit

@MainActor
struct PhotoThumbnailLoader {
    /// Loads a thumbnail for the asset with the given local identifier.
    /// Returns nil if the asset can't be found or no image is available.
    func thumbnail(for localIdentifier: String, targetSize: CGSize) async -> UIImage? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = assets.firstObject else { return nil }
        return await thumbnail(for: asset, targetSize: targetSize)
    }

    /// - Parameter targetSize: desired size in pixels (caller accounts for screen scale).
    func thumbnail(for asset: PHAsset, targetSize: CGSize) async -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true // allow fetching from iCloud if not cached locally

        return await withCheckedContinuation { continuation in
            var didResume = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                // Opportunistic delivery can call back more than once (a fast low-res
                // image, then a higher-res one). Resume only on the final result.
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                guard !isDegraded, !didResume else { return }
                didResume = true
                continuation.resume(returning: image)
            }
        }
    }
}
