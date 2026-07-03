//
//  HomeView.swift
//  PhotoSweep
//
//  Main dashboard. For Phase 1 this requests photo access, imports iCloud metadata,
//  and shows the library as a thumbnail grid.
//

import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UnifiedPhoto.creationDate, order: .reverse) private var photos: [UnifiedPhoto]

    @State private var viewModel = HomeViewModel()
    @State private var googleViewModel = GooglePhotosViewModel()

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 4)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("PhotoSweep")
                .safeAreaInset(edge: .bottom) {
                    TrustBanner()
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
        }
        .task {
            await viewModel.loadPhotos(into: modelContext)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .requestingAccess:
            ProgressView("Preparing…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .importing(let done, let total):
            ProgressView(value: Double(done), total: Double(max(total, 1))) {
                Text("Reading your iCloud library…")
            } currentValueLabel: {
                Text("\(done) of \(total)")
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .accessDenied:
            accessDeniedView

        case .failed(let message):
            ContentUnavailableView("Something went wrong", systemImage: "exclamationmark.triangle", description: Text(message))

        case .ready:
            VStack(spacing: 8) {
                GooglePhotosSection(viewModel: googleViewModel)
                    .padding(.horizontal)
                photoGrid
            }
        }
    }

    private var photoGrid: some View {
        Group {
            if photos.isEmpty {
                ContentUnavailableView(
                    "No photos found",
                    systemImage: "photo.on.rectangle",
                    description: Text("We didn't find any photos in your iCloud library.")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(photos) { photo in
                            PhotoThumbnail(photo: photo)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private var accessDeniedView: some View {
        ContentUnavailableView {
            Label("Photo access needed", systemImage: "lock.fill")
        } description: {
            Text("""
            PhotoSweep needs access to your photo library to scan for duplicates. \
            We never delete anything — access is read-only until you choose an action.
            """)
        } actions: {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: PhotoSweepSchema.models, inMemory: true)
        .environment(AppState())
}
