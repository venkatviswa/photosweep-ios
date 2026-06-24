//
//  UnifiedPhotoTests.swift
//  PhotoSweepTests
//
//  Persistence and relationship coverage for the SwiftData models (PS-010).
//

import Foundation
import SwiftData
import Testing
@testable import PhotoSweep

@MainActor
struct UnifiedPhotoTests {
    /// Builds an in-memory container so tests never touch the real store.
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(PhotoSweepSchema.models), configurations: config)
        return ModelContext(container)
    }

    @Test func insertAndQueryUnifiedPhoto() throws {
        let context = try makeContext()
        let sessionId = UUID()
        let photo = UnifiedPhoto(source: .icloud, scanSessionId: sessionId, fileSize: 1234, width: 4032, height: 3024)
        context.insert(photo)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<UnifiedPhoto>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.source == .icloud)
        #expect(fetched.first?.fileSize == 1234)
        #expect(fetched.first?.pixelCount == 4032 * 3024)
    }

    @Test func defaultsAreApplied() {
        let photo = UnifiedPhoto(source: .googlePhotos, scanSessionId: UUID())
        #expect(photo.isReviewed == false)
        #expect(photo.disposalAction == nil)
        #expect(photo.mediaType == .photo)
        #expect(photo.fileSize == 0)
    }

    @Test func predicateFiltersBySource() throws {
        let context = try makeContext()
        let sessionId = UUID()
        context.insert(UnifiedPhoto(source: .icloud, scanSessionId: sessionId))
        context.insert(UnifiedPhoto(source: .googlePhotos, scanSessionId: sessionId))
        context.insert(UnifiedPhoto(source: .icloud, scanSessionId: sessionId))
        try context.save()

        let icloudValue = PhotoSource.icloud.rawValue
        let descriptor = FetchDescriptor<UnifiedPhoto>(
            predicate: #Predicate { $0.source.rawValue == icloudValue }
        )
        let icloudPhotos = try context.fetch(descriptor)
        #expect(icloudPhotos.count == 2)
    }

    @Test func duplicateGroupRelationshipPersists() throws {
        let context = try makeContext()
        let sessionId = UUID()
        let a = UnifiedPhoto(source: .icloud, scanSessionId: sessionId, fileSize: 5_000)
        let b = UnifiedPhoto(source: .googlePhotos, scanSessionId: sessionId, fileSize: 3_000)
        let group = DuplicateGroup(scanSessionId: sessionId, matchType: .exact, matchConfidence: 1.0, photos: [a, b])
        context.insert(group)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<DuplicateGroup>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.photos.count == 2)
    }
}
