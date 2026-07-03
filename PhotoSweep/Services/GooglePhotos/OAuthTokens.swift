//
//  OAuthTokens.swift
//  PhotoSweep
//
//  OAuth token bundle and the persistence seam for it. Tokens live in the
//  Keychain in production (see KeychainTokenStore); tests substitute an
//  in-memory store.
//

import Foundation

struct OAuthTokens: Codable, Equatable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiryDate: Date

    /// Treats the token as expired 60s early so it can't die mid-request.
    var isExpired: Bool {
        Date() >= expiryDate.addingTimeInterval(-60)
    }
}

protocol TokenStore: Sendable {
    func load() throws -> OAuthTokens?
    func save(_ tokens: OAuthTokens) throws
    func clear() throws
}
