//
//  DateNormalizer.swift
//  PhotoSweep
//
//  Normalizes cloud API timestamps to Date (an absolute UTC instant), so
//  photos from different platforms compare correctly regardless of the
//  timezone the API expressed them in (SPEC §4 Phase 1).
//

import Foundation

enum DateNormalizer {
    /// Parses an RFC 3339 timestamp (Google Photos `createTime` format),
    /// with or without fractional seconds, Zulu or numeric offsets.
    static func date(fromRFC3339 string: String) -> Date? {
        let fractional = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
        let standard = Date.ISO8601FormatStyle()
        return (try? fractional.parse(string)) ?? (try? standard.parse(string))
    }
}
