//
//  DuplicateGroup.swift
//  PhotoSweep
//
//  A set of 2+ photos detected as duplicates of one another.
//  See SPEC.md §3.2.
//

import Foundation
import SwiftData

@Model
final class DuplicateGroup {
    @Attribute(.unique) var id: UUID
    var scanSessionId: UUID
    var matchType: MatchType
    var matchConfidence: Float   // 0.0–1.0
    var suggestedKeepId: UUID?   // recommendation for the "best" photo
    var isReviewed: Bool

    @Relationship(deleteRule: .nullify)
    var photos: [UnifiedPhoto]

    init(
        id: UUID = UUID(),
        scanSessionId: UUID,
        matchType: MatchType,
        matchConfidence: Float,
        suggestedKeepId: UUID? = nil,
        isReviewed: Bool = false,
        photos: [UnifiedPhoto] = []
    ) {
        self.id = id
        self.scanSessionId = scanSessionId
        self.matchType = matchType
        self.matchConfidence = matchConfidence
        self.suggestedKeepId = suggestedKeepId
        self.isReviewed = isReviewed
        self.photos = photos
    }

    /// Bytes saved if every photo except the largest is removed.
    var potentialSavings: Int64 {
        let sorted = photos.sorted { $0.fileSize > $1.fileSize }
        return sorted.dropFirst().reduce(0) { $0 + $1.fileSize }
    }
}
