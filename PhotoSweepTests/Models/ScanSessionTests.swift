//
//  ScanSessionTests.swift
//  PhotoSweepTests
//
//  Persistence coverage for ScanSession and CloudAccount (PS-010).
//

import Foundation
import SwiftData
import Testing
@testable import PhotoSweep

@MainActor
struct ScanSessionTests {
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(PhotoSweepSchema.models), configurations: config)
        return ModelContext(container)
    }

    @Test func newSessionHasExpectedDefaults() {
        let session = ScanSession()
        #expect(session.status == .inProgress)
        #expect(session.endDate == nil)
        #expect(session.totalPhotosScanned == 0)
        #expect(session.duplicateGroupsFound == 0)
        #expect(session.potentialSavingsBytes == 0)
        #expect(session.sourcesScanned.isEmpty)
    }

    @Test func sessionRoundTripsThroughStore() throws {
        let context = try makeContext()
        let session = ScanSession(sourcesScanned: [.icloud, .googlePhotos])
        session.totalPhotosScanned = 1_247
        session.duplicateGroupsFound = 12
        session.potentialSavingsBytes = 230_000_000
        session.status = .completed
        session.endDate = Date()
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<ScanSession>())
        #expect(fetched.count == 1)
        let saved = try #require(fetched.first)
        #expect(saved.totalPhotosScanned == 1_247)
        #expect(saved.duplicateGroupsFound == 12)
        #expect(saved.potentialSavingsBytes == 230_000_000)
        #expect(saved.status == .completed)
        #expect(saved.sourcesScanned == [.icloud, .googlePhotos])
        #expect(saved.endDate != nil)
    }

    @Test func cloudAccountRoundTripsThroughStore() throws {
        let context = try makeContext()
        let account = CloudAccount(source: .googlePhotos, isConnected: true, userEmail: "user@example.com")
        context.insert(account)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CloudAccount>())
        #expect(fetched.count == 1)
        let saved = try #require(fetched.first)
        #expect(saved.source == .googlePhotos)
        #expect(saved.isConnected == true)
        #expect(saved.userEmail == "user@example.com")
        #expect(saved.lastSyncDate == nil)
        #expect(saved.totalPhotos == nil)
    }
}
