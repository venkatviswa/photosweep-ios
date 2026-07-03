//
//  GoogleAuthServiceTests.swift
//  PhotoSweepTests
//
//  Token refresh integration tests (PS-019): expired tokens trigger a refresh
//  request, new tokens are persisted, and revoked grants demand re-auth.
//

import Foundation
import Testing
@testable import PhotoSweep

@MainActor
struct GoogleAuthServiceTests {
    private static let clientId = "test-client.apps.googleusercontent.com"

    private func expiredTokens() -> OAuthTokens {
        OAuthTokens(accessToken: "stale-token", refreshToken: "refresh-1", expiryDate: .distantPast)
    }

    @Test func expiredTokenTriggersRefreshAndPersistsResult() async throws {
        let store = InMemoryTokenStore()
        try store.save(expiredTokens())
        let recorder = RequestRecorder()
        let service = GoogleAuthService(tokenStore: store, clientId: Self.clientId) { request in
            recorder.record(request)
            let body = #"{"access_token":"fresh-token","expires_in":3600}"#
            return try TestHTTP.response(for: request, status: 200, body: body)
        }

        let token = try await service.validAccessToken()

        #expect(token == "fresh-token")
        let saved = try #require(try store.load())
        #expect(saved.accessToken == "fresh-token")
        #expect(saved.refreshToken == "refresh-1") // preserved when Google omits it
        #expect(!saved.isExpired)

        let request = try #require(recorder.requests.first)
        #expect(request.url?.host == "oauth2.googleapis.com")
        let bodyData = try #require(request.httpBody)
        let body = try #require(String(data: bodyData, encoding: .utf8))
        #expect(body.contains("grant_type=refresh_token"))
        #expect(body.contains("refresh_token=refresh-1"))
    }

    @Test func validTokenIsReturnedWithoutRefresh() async throws {
        let store = InMemoryTokenStore()
        try store.save(OAuthTokens(
            accessToken: "still-good",
            refreshToken: "refresh-1",
            expiryDate: Date().addingTimeInterval(3_600)
        ))
        let service = GoogleAuthService(tokenStore: store, clientId: Self.clientId) { _ in
            throw TestHTTP.ResponseError() // any network call fails the test
        }

        let token = try await service.validAccessToken()
        #expect(token == "still-good")
    }

    @Test func revokedGrantClearsTokensAndRequiresReauth() async throws {
        let store = InMemoryTokenStore()
        try store.save(expiredTokens())
        let service = GoogleAuthService(tokenStore: store, clientId: Self.clientId) { request in
            try TestHTTP.response(for: request, status: 400, body: #"{"error":"invalid_grant"}"#)
        }

        await #expect(throws: GooglePhotosError.authRequired) {
            _ = try await service.validAccessToken()
        }
        #expect(try store.load() == nil)
    }

    @Test func missingTokensRequireAuthWithoutNetworkCall() async throws {
        let service = GoogleAuthService(tokenStore: InMemoryTokenStore(), clientId: Self.clientId) { _ in
            throw TestHTTP.ResponseError()
        }
        await #expect(throws: GooglePhotosError.authRequired) {
            _ = try await service.validAccessToken()
        }
        #expect(!service.isConnected)
    }

    @Test func serverErrorDuringRefreshIsRetryableNotAuthFailure() async throws {
        let store = InMemoryTokenStore()
        try store.save(expiredTokens())
        let service = GoogleAuthService(tokenStore: store, clientId: Self.clientId) { request in
            try TestHTTP.response(for: request, status: 503, body: "unavailable")
        }

        await #expect(throws: GooglePhotosError.serverError(503)) {
            _ = try await service.validAccessToken()
        }
        // Tokens survive a transient server error — no forced re-auth.
        #expect(try store.load() != nil)
    }
}
