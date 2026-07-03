//
//  PhotoThumbnail.swift
//  PhotoSweep
//
//  A single grid cell: lazily loads an iCloud thumbnail and overlays a source badge.
//

import SwiftUI

struct PhotoThumbnail: View {
    let photo: UnifiedPhoto

    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geometry in
            let side = geometry.size.width
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay(ProgressView())
                }
            }
            .frame(width: side, height: side)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .bottomLeading) {
                CloudBadge(source: photo.source)
                    .padding(4)
            }
            .task(id: photo.id) {
                await loadThumbnail(side: side)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(accessibilityDescription)
    }

    private func loadThumbnail(side: CGFloat) async {
        guard image == nil else { return }
        // Google photos carry a stored thumbnail; iCloud photos load via PhotoKit.
        if let data = photo.thumbnailData {
            image = UIImage(data: data)
            return
        }
        guard let localIdentifier = photo.localIdentifier else { return }
        let pixelSide = side * 3 // approximate retina scale; thumbnails only
        image = await PhotoThumbnailLoader().thumbnail(
            for: localIdentifier,
            targetSize: CGSize(width: pixelSide, height: pixelSide)
        )
    }

    private var accessibilityDescription: String {
        let name = photo.originalFilename ?? "Photo"
        return "\(name), from \(photo.source.displayName)"
    }
}
