//
//  PhotoEnums.swift
//  PhotoSweep
//
//  Shared enumerations used across the data model.
//  Kept in one file so SwiftData @Model types and views share a single source of truth.
//

import Foundation

/// Which cloud library a photo originates from.
enum PhotoSource: String, Codable, CaseIterable, Sendable {
    case icloud
    case googlePhotos

    /// Human-readable name for display in badges and summaries.
    var displayName: String {
        switch self {
        case .icloud: return "iCloud"
        case .googlePhotos: return "Google Photos"
        }
    }
}

/// Coarse classification of a photo asset.
enum MediaType: String, Codable, CaseIterable, Sendable {
    case photo
    case screenshot
    case livePhoto
    case burst
    case video // Future
}

/// The action a user has chosen for a duplicate. `nil` on a photo means no action taken.
enum DisposalAction: String, Codable, CaseIterable, Sendable {
    case tagForLater
    case archive
    case moveToFolder
    case exportBest
    case guidedDelete
}

/// How a duplicate group was matched.
enum MatchType: String, Codable, CaseIterable, Sendable {
    case exact // SHA-256 match
    case perceptual // pHash within Hamming threshold
    case visual // Vision framework feature vector similarity (post-MVP)
}

/// Lifecycle state of a scan session.
enum ScanStatus: String, Codable, CaseIterable, Sendable {
    case inProgress
    case completed
    case cancelled
    case failed
}
