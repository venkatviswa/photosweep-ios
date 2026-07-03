//
//  GooglePhotosAPI.swift
//  PhotoSweep
//
//  Client for the Google Photos Picker API. The transport closure exists so
//  tests can stub HTTP without touching the network.
//

import Foundation
import os

typealias HTTPTransport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

final class GooglePhotosAPI: Sendable {
    private let transport: HTTPTransport
    private let tokenProvider: @Sendable () async throws -> String
    private let logger = Logger(subsystem: "com.photosweep.app", category: "GooglePhotosAPI")

    init(
        tokenProvider: @escaping @Sendable () async throws -> String,
        transport: @escaping HTTPTransport = { try await URLSession.shared.data(for: $0) }
    ) {
        self.tokenProvider = tokenProvider
        self.transport = transport
    }

    // MARK: - Sessions

    func createSession() async throws -> PickerSession {
        let request = try await authorizedRequest(path: "sessions", method: "POST")
        return try await perform(request, as: PickerSession.self)
    }

    func pickerSession(id: String) async throws -> PickerSession {
        let request = try await authorizedRequest(path: "sessions/\(id)")
        return try await perform(request, as: PickerSession.self)
    }

    func deleteSession(id: String) async throws {
        let request = try await authorizedRequest(path: "sessions/\(id)", method: "DELETE")
        _ = try await validatedData(for: request)
    }

    /// Polls the session until the user finishes picking, honoring the
    /// server-suggested poll interval. Respects task cancellation.
    func waitForSelection(session initial: PickerSession, timeout: TimeInterval = 900) async throws -> PickerSession {
        let interval = Self.seconds(fromDuration: initial.pollingConfig?.pollInterval) ?? 5
        let deadline = Date().addingTimeInterval(timeout)
        var current = initial
        while current.mediaItemsSet != true {
            guard Date() < deadline else {
                throw GooglePhotosError.network("Timed out waiting for photo selection")
            }
            try await Task.sleep(for: .seconds(interval))
            current = try await pickerSession(id: initial.id)
        }
        return current
    }

    // MARK: - Media items

    func listPickedItems(sessionId: String) async throws -> [PickedMediaItem] {
        var items: [PickedMediaItem] = []
        var pageToken: String?
        repeat {
            var query = [
                URLQueryItem(name: "sessionId", value: sessionId),
                URLQueryItem(name: "pageSize", value: "100")
            ]
            if let pageToken {
                query.append(URLQueryItem(name: "pageToken", value: pageToken))
            }
            let request = try await authorizedRequest(path: "mediaItems", query: query)
            let page = try await perform(request, as: PickedMediaItemsPage.self)
            items.append(contentsOf: page.mediaItems ?? [])
            pageToken = page.nextPageToken
        } while pageToken != nil
        return items
    }

    /// Downloads image bytes from a picked item's baseUrl at a bounded size.
    /// Picker baseUrls require the OAuth token and expire — never cache them.
    func fetchImageData(baseUrl: String, maxDimension: Int = 200) async throws -> Data {
        guard let url = URL(string: "\(baseUrl)=w\(maxDimension)-h\(maxDimension)") else {
            throw GooglePhotosError.invalidResponse
        }
        var request = URLRequest(url: url)
        let token = try await tokenProvider()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await validatedData(for: request)
    }

    /// Parses a protobuf Duration string like "5s" or "2.5s" into seconds.
    static func seconds(fromDuration duration: String?) -> Double? {
        guard let duration, duration.hasSuffix("s") else { return nil }
        return Double(duration.dropLast())
    }

    // MARK: - Plumbing

    private func authorizedRequest(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = []
    ) async throws -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "photospicker.googleapis.com"
        components.path = "/v1/" + path
        if !query.isEmpty {
            components.queryItems = query
        }
        guard let url = components.url else { throw GooglePhotosError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = method
        let token = try await tokenProvider()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    private func perform<Response: Decodable>(_ request: URLRequest, as type: Response.Type) async throws -> Response {
        let data = try await validatedData(for: request)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            logger.error("Decoding \(String(describing: type), privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            throw GooglePhotosError.invalidResponse
        }
    }

    private func validatedData(for request: URLRequest) async throws -> Data {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await transport(request)
        } catch {
            if error is CancellationError { throw error }
            throw GooglePhotosError.network(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw GooglePhotosError.invalidResponse }
        switch http.statusCode {
        case 200...299:
            return data
        case 401, 403:
            throw GooglePhotosError.authRequired
        case 429:
            throw GooglePhotosError.rateLimited
        case 500...599:
            throw GooglePhotosError.serverError(http.statusCode)
        default:
            logger.error("Unexpected HTTP \(http.statusCode, privacy: .public) from \(request.url?.path ?? "?", privacy: .public)")
            throw GooglePhotosError.invalidResponse
        }
    }
}
