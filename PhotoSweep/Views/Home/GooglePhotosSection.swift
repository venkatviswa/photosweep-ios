//
//  GooglePhotosSection.swift
//  PhotoSweep
//
//  Compact Home-screen section for connecting Google Photos and showing
//  pick/import progress. Selection happens in the Google Photos app itself —
//  we only ever see the photos the user picks.
//

import SwiftData
import SwiftUI

struct GooglePhotosSection: View {
    let viewModel: GooglePhotosViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch viewModel.state {
        case .idle:
            connectButton

        case .authorizing:
            ProgressView("Connecting to Google…")
                .font(.footnote)

        case .waitingForSelection:
            VStack(spacing: 4) {
                ProgressView("Waiting for your selection…")
                    .font(.footnote)
                Text("Pick photos in Google Photos, then come back here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .importing(let done, let total):
            ProgressView(value: Double(done), total: Double(max(total, 1))) {
                Text("Importing \(done) of \(total) from Google Photos…")
                    .font(.footnote)
            }

        case .failed(let message):
            VStack(spacing: 6) {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Try Again") {
                    startFlow()
                }
                .font(.footnote.weight(.semibold))
            }
        }
    }

    private var connectButton: some View {
        Button {
            startFlow()
        } label: {
            Label(
                viewModel.isConnected ? "Add Google Photos" : "Connect Google Photos",
                systemImage: "photo.badge.plus"
            )
            .font(.footnote.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .accessibilityHint("Opens Google Photos so you can pick photos to scan")
    }

    private func startFlow() {
        Task {
            await viewModel.connectAndImport(into: modelContext)
        }
    }
}
