//
//  GooglePhotosError.swift
//  PhotoSweep
//
//  Error taxonomy for the Google Photos integration. Per CLAUDE.md, callers must
//  be able to distinguish auth failures (re-auth) from retryable API errors and
//  quota errors (back off).
//

import Foundation

enum GooglePhotosError: Error, Equatable {
    case notConfigured        // GOOGLE_CLIENT_ID missing from the build config
    case authRequired         // No valid refresh token — user must reconnect
    case rateLimited          // 429 — back off and retry later
    case serverError(Int)     // 5xx — transient, retryable
    case network(String)      // Transport-level failure
    case invalidResponse      // Unparseable or unexpected payload
    case cancelled            // User dismissed the sign-in sheet
}
