//
//  DateNormalizerTests.swift
//  PhotoSweepTests
//
//  Timezone edge cases for cross-platform date normalization (PS-020).
//

import Foundation
import Testing
@testable import PhotoSweep

struct DateNormalizerTests {
    @Test func parsesZuluTime() throws {
        let date = try #require(DateNormalizer.date(fromRFC3339: "2024-03-01T10:15:30Z"))
        #expect(date.timeIntervalSince1970 == 1_709_288_130)
    }

    @Test func parsesFractionalSeconds() throws {
        let date = try #require(DateNormalizer.date(fromRFC3339: "2024-03-01T10:15:30.500Z"))
        #expect(date.timeIntervalSince1970 == 1_709_288_130.5)
    }

    @Test func normalizesNumericOffsetsToSameInstant() throws {
        // 15:45:30 at +05:30 is the same instant as 10:15:30 UTC.
        let offset = try #require(DateNormalizer.date(fromRFC3339: "2024-03-01T15:45:30+05:30"))
        let zulu = try #require(DateNormalizer.date(fromRFC3339: "2024-03-01T10:15:30Z"))
        #expect(offset == zulu)
    }

    @Test func negativeOffsetNormalizes() throws {
        // 02:15:30 at -08:00 is 10:15:30 UTC.
        let offset = try #require(DateNormalizer.date(fromRFC3339: "2024-03-01T02:15:30-08:00"))
        #expect(offset.timeIntervalSince1970 == 1_709_288_130)
    }

    @Test func rejectsInvalidInput() {
        #expect(DateNormalizer.date(fromRFC3339: "not a date") == nil)
        #expect(DateNormalizer.date(fromRFC3339: "") == nil)
        #expect(DateNormalizer.date(fromRFC3339: "2024-03-01") == nil)
    }
}
