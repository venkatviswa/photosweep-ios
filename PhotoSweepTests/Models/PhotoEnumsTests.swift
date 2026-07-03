//
//  PhotoEnumsTests.swift
//  PhotoSweepTests
//
//  Pins enum raw values. These are persisted by SwiftData — changing a raw
//  value silently breaks existing stores, so a rename must fail here first.
//

import Testing
@testable import PhotoSweep

struct PhotoEnumsTests {
    @Test func photoSourceRawValuesAreStable() {
        #expect(PhotoSource.icloud.rawValue == "icloud")
        #expect(PhotoSource.googlePhotos.rawValue == "googlePhotos")
    }

    @Test func mediaTypeRawValuesAreStable() {
        #expect(MediaType.photo.rawValue == "photo")
        #expect(MediaType.screenshot.rawValue == "screenshot")
        #expect(MediaType.livePhoto.rawValue == "livePhoto")
        #expect(MediaType.burst.rawValue == "burst")
        #expect(MediaType.video.rawValue == "video")
    }

    @Test func disposalActionRawValuesAreStable() {
        #expect(DisposalAction.tagForLater.rawValue == "tagForLater")
        #expect(DisposalAction.archive.rawValue == "archive")
        #expect(DisposalAction.moveToFolder.rawValue == "moveToFolder")
        #expect(DisposalAction.exportBest.rawValue == "exportBest")
        #expect(DisposalAction.guidedDelete.rawValue == "guidedDelete")
    }

    @Test func matchTypeAndScanStatusRawValuesAreStable() {
        #expect(MatchType.exact.rawValue == "exact")
        #expect(MatchType.perceptual.rawValue == "perceptual")
        #expect(MatchType.visual.rawValue == "visual")
        #expect(ScanStatus.inProgress.rawValue == "inProgress")
        #expect(ScanStatus.completed.rawValue == "completed")
        #expect(ScanStatus.cancelled.rawValue == "cancelled")
        #expect(ScanStatus.failed.rawValue == "failed")
    }

    @Test func photoSourceDisplayNames() {
        #expect(PhotoSource.icloud.displayName == "iCloud")
        #expect(PhotoSource.googlePhotos.displayName == "Google Photos")
    }
}
