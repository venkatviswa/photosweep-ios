//
//  TestNetworking.swift
//  PhotoSweepTests
//
//  Shared fakes for network-facing tests: an in-memory token store, a
//  thread-safe request recorder, and HTTP response builders.
//

import Foundation
@testable import PhotoSweep

final class InMemoryTokenStore: TokenStore, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: OAuthTokens?

    func load() throws -> OAuthTokens? {
        lock.withLock { stored }
    }

    func save(_ tokens: OAuthTokens) throws {
        lock.withLock { stored = tokens }
    }

    func clear() throws {
        lock.withLock { stored = nil }
    }
}

final class RequestRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    func record(_ request: URLRequest) {
        lock.withLock { recorded.append(request) }
    }

    var requests: [URLRequest] {
        lock.withLock { recorded }
    }
}

enum TestHTTP {
    struct ResponseError: Error {}

    static func response(for request: URLRequest, status: Int, body: String) throws -> (Data, URLResponse) {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) else {
            throw ResponseError()
        }
        return (Data(body.utf8), response)
    }
}
