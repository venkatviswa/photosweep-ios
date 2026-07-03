//
//  ScanSession.swift
//  PhotoSweep
//
//  Records one run of the duplicate scan. See SPEC.md §3.3.
//  (CLAUDE.md lists this under Models/ScanResult.swift; the primary type is
//  ScanSession, so the file is named to match the type per the coding standards.)
//

import Foundation
import SwiftData

@Model
final class ScanSession {
    @Attribute(.unique) var id: UUID
    var startDate: Date
    var endDate: Date?
    var status: ScanStatus
    var totalPhotosScanned: Int
    var duplicateGroupsFound: Int
    var potentialSavingsBytes: Int64
    var sourcesScanned: [PhotoSource]

    init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        status: ScanStatus = .inProgress,
        totalPhotosScanned: Int = 0,
        duplicateGroupsFound: Int = 0,
        potentialSavingsBytes: Int64 = 0,
        sourcesScanned: [PhotoSource] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.totalPhotosScanned = totalPhotosScanned
        self.duplicateGroupsFound = duplicateGroupsFound
        self.potentialSavingsBytes = potentialSavingsBytes
        self.sourcesScanned = sourcesScanned
    }
}
