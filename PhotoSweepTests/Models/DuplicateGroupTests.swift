//
//  DuplicateGroupTests.swift
//  PhotoSweepTests
//
//  Covers the potential-savings calculation (SPEC §3.2).
//

import Foundation
import Testing
@testable import PhotoSweep

@MainActor
struct DuplicateGroupTests {
    private func photo(size: Int64) -> UnifiedPhoto {
        UnifiedPhoto(source: .icloud, scanSessionId: UUID(), fileSize: size)
    }

    @Test func potentialSavingsExcludesLargestPhoto() {
        let group = DuplicateGroup(
            scanSessionId: UUID(),
            matchType: .exact,
            matchConfidence: 1.0,
            photos: [photo(size: 1_000), photo(size: 5_000), photo(size: 2_000)]
        )
        // Keeps the 5,000-byte original; saves 1,000 + 2,000.
        #expect(group.potentialSavings == 3_000)
    }

    @Test func potentialSavingsIsZeroForSinglePhoto() {
        let group = DuplicateGroup(
            scanSessionId: UUID(),
            matchType: .perceptual,
            matchConfidence: 0.9,
            photos: [photo(size: 4_200)]
        )
        #expect(group.potentialSavings == 0)
    }

    @Test func potentialSavingsIsZeroForEmptyGroup() {
        let group = DuplicateGroup(scanSessionId: UUID(), matchType: .exact, matchConfidence: 1.0)
        #expect(group.potentialSavings == 0)
    }
}
