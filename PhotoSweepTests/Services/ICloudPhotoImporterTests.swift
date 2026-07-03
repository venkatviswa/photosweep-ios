//
//  ICloudPhotoImporterTests.swift
//  PhotoSweepTests
//
//  Covers the pure media-type classification logic (PHAsset itself can't be
//  constructed in tests, so the branching is extracted into `classify`).
//

import Testing
@testable import PhotoSweep

struct ICloudPhotoImporterTests {
    @Test func videoTakesPrecedence() {
        let result = ICloudPhotoImporter.classify(isVideo: true, isScreenshot: true, isLivePhoto: true, isBurst: true)
        #expect(result == .video)
    }

    @Test func screenshotBeatsLivePhotoAndBurst() {
        let result = ICloudPhotoImporter.classify(isVideo: false, isScreenshot: true, isLivePhoto: true, isBurst: true)
        #expect(result == .screenshot)
    }

    @Test func livePhotoBeatsBurst() {
        let result = ICloudPhotoImporter.classify(isVideo: false, isScreenshot: false, isLivePhoto: true, isBurst: true)
        #expect(result == .livePhoto)
    }

    @Test func burstWhenOnlyBurst() {
        let result = ICloudPhotoImporter.classify(isVideo: false, isScreenshot: false, isLivePhoto: false, isBurst: true)
        #expect(result == .burst)
    }

    @Test func plainPhotoIsDefault() {
        let result = ICloudPhotoImporter.classify(isVideo: false, isScreenshot: false, isLivePhoto: false, isBurst: false)
        #expect(result == .photo)
    }
}
