//
//  GooglePhotosViewModel.swift
//  PhotoSweep
//
//  Drives the Google Photos connect-and-pick flow: OAuth → Picker session →
//  user selects in the Google Photos app/web → poll → import into SwiftData.
//

import Foundation
import Observation
import os
import SwiftData
import UIKit

@MainActor
@Observable
final class GooglePhotosViewModel {
    enum State: Equatable {
        case idle
        case authorizing
        case waitingForSelection
        case importing(done: Int, total: Int)
        case failed(String)
    }

    private(set) var state: State = .idle

    private let authService: GoogleAuthService
    private let api: GooglePhotosAPI
    private let logger = Logger(subsystem: "com.photosweep.app", category: "GooglePhotosViewModel")

    init(authService: GoogleAuthService = GoogleAuthService()) {
        self.authService = authService
        self.api = GooglePhotosAPI(tokenProvider: { try await authService.validAccessToken() })
    }

    var isConnected: Bool {
        authService.isConnected
    }

    /// Full flow: authorize (if needed), open the Google Photos picker, wait for
    /// the user's selection, then import the picked photos.
    func connectAndImport(into context: ModelContext) async {
        do {
            state = .authorizing
            if !authService.isConnected {
                try await authService.authorize()
            }
            let session = try await api.createSession()
            guard let pickerURL = URL(string: session.pickerUri) else {
                throw GooglePhotosError.invalidResponse
            }
            state = .waitingForSelection
            _ = await UIApplication.shared.open(pickerURL)
            let ready = try await api.waitForSelection(session: session)
            let items = try await api.listPickedItems(sessionId: ready.id)
            try await importItems(items, into: context)
            cleanUpSession(id: ready.id)
            state = .idle
        } catch GooglePhotosError.cancelled {
            state = .idle
        } catch {
            logger.error("Google Photos import failed: \(error.localizedDescription, privacy: .public)")
            state = .failed(Self.friendlyMessage(for: error))
        }
    }

    private func importItems(_ items: [PickedMediaItem], into context: ModelContext) async throws {
        // Skip photos we already imported in an earlier pick.
        // (SwiftData can't predicate on our enum, so filter in Swift.)
        let existing = (try? context.fetch(FetchDescriptor<UnifiedPhoto>())) ?? []
        let knownIds = Set(existing.compactMap(\.googleMediaItemId))
        let newItems = items.filter { !knownIds.contains($0.id) }
        guard !newItems.isEmpty else { return }

        let scan = ScanSession(sourcesScanned: [.googlePhotos])
        context.insert(scan)
        state = .importing(done: 0, total: newItems.count)

        for (index, item) in newItems.enumerated() {
            let photo = GooglePhotoImporter.makeUnifiedPhoto(from: item, scanSessionId: scan.id)
            photo.thumbnailData = await thumbnailData(for: item)
            context.insert(photo)
            state = .importing(done: index + 1, total: newItems.count)
        }

        scan.totalPhotosScanned = newItems.count
        scan.status = .completed
        scan.endDate = Date()
        try context.save()
        updateAccount(in: context, imported: newItems.count)
    }

    private func thumbnailData(for item: PickedMediaItem) async -> Data? {
        guard let baseUrl = item.mediaFile?.baseUrl else { return nil }
        do {
            return try await api.fetchImageData(baseUrl: baseUrl)
        } catch {
            logger.notice("Thumbnail fetch failed for \(item.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func updateAccount(in context: ModelContext, imported: Int) {
        let accounts = (try? context.fetch(FetchDescriptor<CloudAccount>())) ?? []
        let account = accounts.first { $0.source == .googlePhotos }
            ?? {
                let created = CloudAccount(source: .googlePhotos)
                context.insert(created)
                return created
            }()
        account.isConnected = true
        account.lastSyncDate = Date()
        account.totalPhotos = (account.totalPhotos ?? 0) + imported
        do {
            try context.save()
        } catch {
            logger.error("Failed to update Google account record: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func cleanUpSession(id: String) {
        Task {
            do {
                try await api.deleteSession(id: id)
            } catch {
                logger.notice("Picker session cleanup failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private static func friendlyMessage(for error: Error) -> String {
        switch error as? GooglePhotosError {
        case .authRequired:
            return "Your Google Photos connection needs to be renewed. Please connect again."
        case .rateLimited:
            return "Google Photos is busy right now. Please try again in a few minutes."
        case .notConfigured:
            return "Google Photos isn't set up for this build yet."
        case .network:
            return "Couldn't reach Google Photos. Check your connection and try again."
        case .serverError, .invalidResponse, .cancelled, .none:
            return "Something went wrong talking to Google Photos. Please try again."
        }
    }
}
