//
//  GoogleAuthService.swift
//  PhotoSweep
//
//  Google OAuth 2.0 for the Photos Picker API, using ASWebAuthenticationSession
//  with PKCE (no client secret on iOS). Tokens persist in the Keychain.
//
//  Scope note: Google removed the library-wide read scopes on March 31, 2025.
//  The only supported path to user photos is the Picker API, so we request
//  `photospicker.mediaitems.readonly` — the user picks which photos we see.
//

import AuthenticationServices
import CryptoKit
import Foundation
import os
import UIKit

@MainActor
final class GoogleAuthService: NSObject {
    private static let scope = "https://www.googleapis.com/auth/photospicker.mediaitems.readonly"
    private static let tokenEndpoint = "https://oauth2.googleapis.com/token"

    private let tokenStore: TokenStore
    private let transport: HTTPTransport
    private let clientId: String?
    private let logger = Logger(subsystem: "com.photosweep.app", category: "GoogleAuthService")

    init(
        tokenStore: TokenStore = KeychainTokenStore(),
        clientId: String? = Bundle.main.object(forInfoDictionaryKey: "GoogleClientID") as? String,
        transport: @escaping HTTPTransport = { try await URLSession.shared.data(for: $0) }
    ) {
        self.tokenStore = tokenStore
        self.clientId = (clientId?.isEmpty == false) ? clientId : nil
        self.transport = transport
        super.init()
    }

    var isConnected: Bool {
        storedTokens() != nil
    }

    /// Runs the interactive sign-in flow and stores the resulting tokens.
    func authorize() async throws {
        guard let clientId, let reversedClientId else { throw GooglePhotosError.notConfigured }
        let verifier = Self.makeCodeVerifier()
        let redirectURI = "\(reversedClientId):/oauth2redirect"
        let authURL = try Self.authorizationURL(
            clientId: clientId,
            redirectURI: redirectURI,
            challenge: Self.codeChallenge(for: verifier)
        )
        let code = try await authorizationCode(authURL: authURL, callbackScheme: reversedClientId)
        let response = try await requestToken(parameters: [
            "client_id": clientId,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI
        ])
        guard let refreshToken = response.refreshToken else {
            logger.error("Token exchange succeeded but no refresh token was returned")
            throw GooglePhotosError.invalidResponse
        }
        store(OAuthTokens(
            accessToken: response.accessToken,
            refreshToken: refreshToken,
            expiryDate: Date().addingTimeInterval(response.expiresIn)
        ))
    }

    /// Returns a non-expired access token, refreshing if needed.
    /// Throws `.authRequired` when the user must reconnect.
    func validAccessToken() async throws -> String {
        guard let tokens = storedTokens() else { throw GooglePhotosError.authRequired }
        guard tokens.isExpired else { return tokens.accessToken }
        return try await refresh(tokens).accessToken
    }

    func signOut() {
        do {
            try tokenStore.clear()
        } catch {
            logger.error("Failed to clear tokens: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Token requests

    private func refresh(_ tokens: OAuthTokens) async throws -> OAuthTokens {
        guard let clientId else { throw GooglePhotosError.notConfigured }
        let response = try await requestToken(parameters: [
            "client_id": clientId,
            "grant_type": "refresh_token",
            "refresh_token": tokens.refreshToken
        ])
        let updated = OAuthTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken ?? tokens.refreshToken,
            expiryDate: Date().addingTimeInterval(response.expiresIn)
        )
        store(updated)
        return updated
    }

    private func requestToken(parameters: [String: String]) async throws -> TokenResponse {
        guard let url = URL(string: Self.tokenEndpoint) else { throw GooglePhotosError.invalidResponse }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncoded(parameters)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await transport(request)
        } catch {
            throw GooglePhotosError.network(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw GooglePhotosError.invalidResponse }
        switch http.statusCode {
        case 200...299:
            break
        case 400, 401:
            // invalid_grant: the refresh token was revoked or expired — reconnect.
            logger.notice("Token request rejected (\(http.statusCode)); clearing stored tokens")
            try? tokenStore.clear()
            throw GooglePhotosError.authRequired
        case 429:
            throw GooglePhotosError.rateLimited
        case 500...599:
            throw GooglePhotosError.serverError(http.statusCode)
        default:
            throw GooglePhotosError.invalidResponse
        }
        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            logger.error("Failed to decode token response: \(error.localizedDescription, privacy: .public)")
            throw GooglePhotosError.invalidResponse
        }
    }

    // MARK: - Interactive sign-in

    private func authorizationCode(authURL: URL, callbackScheme: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callback: .customScheme(callbackScheme)
            ) { callbackURL, error in
                if let error {
                    let cancelled = (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin
                    let mapped: GooglePhotosError = cancelled ? .cancelled : .network(error.localizedDescription)
                    continuation.resume(throwing: mapped)
                    return
                }
                guard let callbackURL,
                      let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems,
                      let code = items.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: GooglePhotosError.invalidResponse)
                    return
                }
                continuation.resume(returning: code)
            }
            session.presentationContextProvider = self
            session.start()
        }
    }

    // MARK: - Helpers

    private func storedTokens() -> OAuthTokens? {
        (try? tokenStore.load()).flatMap { $0 }
    }

    private func store(_ tokens: OAuthTokens) {
        do {
            try tokenStore.save(tokens)
        } catch {
            logger.error("Failed to persist tokens: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// "abc.apps.googleusercontent.com" → "com.googleusercontent.apps.abc"
    private var reversedClientId: String? {
        guard let clientId else { return nil }
        return clientId.split(separator: ".").reversed().joined(separator: ".")
    }

    private static func authorizationURL(clientId: String, redirectURI: String, challenge: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.google.com"
        components.path = "/o/oauth2/v2/auth"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let url = components.url else { throw GooglePhotosError.invalidResponse }
        return url
    }

    private static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        for index in bytes.indices {
            bytes[index] = UInt8.random(in: .min ... .max)
        }
        return Data(bytes).base64URLEncoded()
    }

    private static func codeChallenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded()
    }

    private static func formEncoded(_ parameters: [String: String]) -> Data {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let pairs = parameters.map { key, value in
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(encodedKey)=\(encodedValue)"
        }
        return Data(pairs.sorted().joined(separator: "&").utf8)
    }

    private struct TokenResponse: Decodable {
        let accessToken: String
        let expiresIn: Double
        let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
        }
    }
}

extension GoogleAuthService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
            return windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}

private extension Data {
    func base64URLEncoded() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
