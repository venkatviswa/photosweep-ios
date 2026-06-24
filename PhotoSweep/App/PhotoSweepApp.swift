//
//  PhotoSweepApp.swift
//  PhotoSweep
//
//  App entry point. Wires up the SwiftData container and global app state.
//

import SwiftData
import SwiftUI

@main
struct PhotoSweepApp: App {
    /// Shared model container for all persisted entities.
    let modelContainer: ModelContainer

    @State private var appState = AppState()

    init() {
        do {
            modelContainer = try ModelContainer(for: PhotoSweepSchema.models)
        } catch {
            // A failure here means the on-disk store is unreadable/incompatible.
            // There is no meaningful recovery at launch, so crash loudly with context.
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
        }
        .modelContainer(modelContainer)
    }
}

/// Central registry of the SwiftData schema so the app and tests stay in sync.
enum PhotoSweepSchema {
    static let models: [any PersistentModel.Type] = [
        UnifiedPhoto.self,
        DuplicateGroup.self,
        ScanSession.self,
        CloudAccount.self
    ]
}
