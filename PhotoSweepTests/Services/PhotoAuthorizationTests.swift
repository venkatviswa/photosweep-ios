//
//  PhotoAuthorizationTests.swift
//  PhotoSweepTests
//
//  Covers the authorization gate that decides whether a scan can proceed.
//

import Testing
@testable import PhotoSweep

struct PhotoAuthorizationTests {
    @Test func fullAccessCanReadLibrary() {
        #expect(PhotoAuthorization.authorized.canReadLibrary)
    }

    @Test func limitedAccessCanReadLibrary() {
        // Limited selection still lets us scan what the user granted.
        #expect(PhotoAuthorization.limited.canReadLibrary)
    }

    @Test func deniedStatesCannotReadLibrary() {
        #expect(!PhotoAuthorization.denied.canReadLibrary)
        #expect(!PhotoAuthorization.restricted.canReadLibrary)
        #expect(!PhotoAuthorization.notDetermined.canReadLibrary)
    }
}
