//
//  HomeViewModel.swift
//  PhotoSweep
//
//  Drives the Home screen: requests photo access and imports iCloud metadata
//  into SwiftData so the grid has something to show.
//

import Foundation
import os
import Photos
import SwiftData

@MainActor
@Observable
final class HomeViewModel {
    enum LoadState: Equatable {
        case idle
        case requestingAccess
        case accessDenied
        case importing(done: Int, total: Int)
        case ready
        case failed(String)
    }

    private(set) var state: LoadState = .idle

    private let photoService = ICloudPhotoService()
    private let importer = ICloudPhotoImporter()
    private let logger = Logger(subsystem: "com.photosweep.app", category: "HomeViewModel")

    /// Requests access (if needed) and imports iCloud photo metadata into the store.
    /// Idempotent per scan session: each call creates a fresh ScanSession of imported photos.
    func loadPhotos(into context: ModelContext) async {
        state = .requestingAccess
        var authorization = photoService.currentAuthorization()
        if authorization == .notDetermined {
            authorization = await photoService.requestAuthorization()
        }

        guard authorization.canReadLibrary else {
            logger.notice("Photo library access not granted: \(String(describing: authorization), privacy: .public)")
            state = .accessDenied
            return
        }

        let assets = photoService.fetchImageAssets()
        let total = assets.count
        guard total > 0 else {
            state = .ready
            return
        }

        let session = ScanSession(sourcesScanned: [.icloud])
        context.insert(session)

        state = .importing(done: 0, total: total)
        for index in 0..<total {
            let asset = assets.object(at: index)
            let photo = importer.makeUnifiedPhoto(from: asset, scanSessionId: session.id)
            context.insert(photo)
            // Update progress occasionally to avoid thrashing the UI on large libraries.
            if index % 100 == 0 {
                state = .importing(done: index, total: total)
            }
        }

        session.totalPhotosScanned = total
        session.status = .completed
        session.endDate = Date()

        do {
            try context.save()
            state = .ready
        } catch {
            logger.error("Failed to save imported photos: \(error.localizedDescription, privacy: .public)")
            state = .failed("Couldn't save your photo library. Please try again.")
        }
    }
}
