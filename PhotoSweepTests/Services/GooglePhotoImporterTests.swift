//
//  GooglePhotoImporterTests.swift
//  PhotoSweepTests
//
//  Picker payload → UnifiedPhoto mapping (PS-016).
//

import Foundation
import Testing
@testable import PhotoSweep

struct GooglePhotoImporterTests {
    private func decodeItem(_ json: String) throws -> PickedMediaItem {
        try JSONDecoder().decode(PickedMediaItem.self, from: Data(json.utf8))
    }

    @Test func mapsFullPhotoPayload() throws {
        let item = try decodeItem(#"""
        {"id": "gm-1", "createTime": "2024-03-01T10:15:30Z", "type": "PHOTO",
         "mediaFile": {"baseUrl": "https://lh3.example.com/base", "mimeType": "image/jpeg",
                       "filename": "IMG_0042.jpg",
                       "mediaFileMetadata": {"width": 4032, "height": 3024,
                                             "cameraMake": "Apple", "cameraModel": "iPhone 15 Pro"}}}
        """#)
        let sessionId = UUID()

        let photo = GooglePhotoImporter.makeUnifiedPhoto(from: item, scanSessionId: sessionId)

        #expect(photo.source == .googlePhotos)
        #expect(photo.googleMediaItemId == "gm-1")
        #expect(photo.localIdentifier == nil)
        #expect(photo.scanSessionId == sessionId)
        #expect(photo.originalFilename == "IMG_0042.jpg")
        #expect(photo.width == 4032)
        #expect(photo.height == 3024)
        #expect(photo.cameraMake == "Apple")
        #expect(photo.cameraModel == "iPhone 15 Pro")
        #expect(photo.mediaType == .photo)
        let created = try #require(photo.creationDate)
        #expect(created.timeIntervalSince1970 == 1_709_288_130)
    }

    @Test func mapsVideoTypeAndSurvivesSparsePayload() throws {
        let item = try decodeItem(#"{"id": "gm-2", "type": "VIDEO"}"#)

        let photo = GooglePhotoImporter.makeUnifiedPhoto(from: item, scanSessionId: UUID())

        #expect(photo.mediaType == .video)
        #expect(photo.creationDate == nil)
        #expect(photo.originalFilename == nil)
        #expect(photo.width == 0)
        #expect(photo.height == 0)
    }
}
