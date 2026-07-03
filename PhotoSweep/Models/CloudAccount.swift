//
//  CloudAccount.swift
//  PhotoSweep
//
//  A connected cloud photo library. See SPEC.md §3.4.
//  OAuth tokens are stored in the Keychain, never on this model.
//

import Foundation
import SwiftData

@Model
final class CloudAccount {
    @Attribute(.unique) var id: UUID
    var source: PhotoSource
    var isConnected: Bool
    var lastSyncDate: Date?
    var totalPhotos: Int?
    var userEmail: String? // Google only, for display

    init(
        id: UUID = UUID(),
        source: PhotoSource,
        isConnected: Bool = false,
        lastSyncDate: Date? = nil,
        totalPhotos: Int? = nil,
        userEmail: String? = nil
    ) {
        self.id = id
        self.source = source
        self.isConnected = isConnected
        self.lastSyncDate = lastSyncDate
        self.totalPhotos = totalPhotos
        self.userEmail = userEmail
    }
}
