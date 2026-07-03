//
//  GooglePhotosAPITests.swift
//  PhotoSweepTests
//
//  Picker API client: response decoding, pagination, auth headers, and the
//  error taxonomy (auth vs retry vs back-off).
//

import Foundation
import Testing
@testable import PhotoSweep

struct GooglePhotosAPITests {
    private func makeAPI(transport: @escaping HTTPTransport) -> GooglePhotosAPI {
        GooglePhotosAPI(tokenProvider: { "token-123" }, transport: transport)
    }

    @Test func createSessionDecodesAndSendsBearerToken() async throws {
        let recorder = RequestRecorder()
        let api = makeAPI { request in
            recorder.record(request)
            let body = #"""
            {"id": "session-1", "pickerUri": "https://photos.google.com/picker/abc",
             "pollingConfig": {"pollInterval": "5s"}, "mediaItemsSet": false}
            """#
            return try TestHTTP.response(for: request, status: 200, body: body)
        }

        let session = try await api.createSession()

        #expect(session.id == "session-1")
        #expect(session.pickerUri == "https://photos.google.com/picker/abc")
        #expect(session.pollingConfig?.pollInterval == "5s")
        #expect(session.mediaItemsSet == false)

        let request = try #require(recorder.requests.first)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token-123")
        #expect(request.url?.host == "photospicker.googleapis.com")
    }

    @Test func listPickedItemsFollowsNextPageToken() async throws {
        let recorder = RequestRecorder()
        let api = makeAPI { request in
            recorder.record(request)
            let query = request.url?.query ?? ""
            let body: String
            if query.contains("pageToken=page-2") {
                body = #"{"mediaItems": [{"id": "item-2"}]}"#
            } else {
                body = #"{"mediaItems": [{"id": "item-1"}], "nextPageToken": "page-2"}"#
            }
            return try TestHTTP.response(for: request, status: 200, body: body)
        }

        let items = try await api.listPickedItems(sessionId: "session-1")

        #expect(items.map(\.id) == ["item-1", "item-2"])
        #expect(recorder.requests.count == 2)
        #expect(recorder.requests.allSatisfy { ($0.url?.query ?? "").contains("sessionId=session-1") })
    }

    @Test func unauthorizedMapsToAuthRequired() async throws {
        let api = makeAPI { request in
            try TestHTTP.response(for: request, status: 401, body: "{}")
        }
        await #expect(throws: GooglePhotosError.authRequired) {
            _ = try await api.createSession()
        }
    }

    @Test func rateLimitMapsToRateLimited() async throws {
        let api = makeAPI { request in
            try TestHTTP.response(for: request, status: 429, body: "{}")
        }
        await #expect(throws: GooglePhotosError.rateLimited) {
            _ = try await api.createSession()
        }
    }

    @Test func serverFailureMapsToServerError() async throws {
        let api = makeAPI { request in
            try TestHTTP.response(for: request, status: 500, body: "{}")
        }
        await #expect(throws: GooglePhotosError.serverError(500)) {
            _ = try await api.createSession()
        }
    }

    @Test func garbagePayloadMapsToInvalidResponse() async throws {
        let api = makeAPI { request in
            try TestHTTP.response(for: request, status: 200, body: "not json")
        }
        await #expect(throws: GooglePhotosError.invalidResponse) {
            _ = try await api.createSession()
        }
    }

    @Test func durationStringsParseToSeconds() {
        #expect(GooglePhotosAPI.seconds(fromDuration: "5s") == 5)
        #expect(GooglePhotosAPI.seconds(fromDuration: "2.5s") == 2.5)
        #expect(GooglePhotosAPI.seconds(fromDuration: "5") == nil)
        #expect(GooglePhotosAPI.seconds(fromDuration: nil) == nil)
    }
}
