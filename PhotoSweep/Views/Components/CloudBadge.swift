//
//  CloudBadge.swift
//  PhotoSweep
//
//  Small badge indicating which cloud a photo lives in.
//  Color is never the only signal (icon + label) per the accessibility requirements.
//

import SwiftUI

struct CloudBadge: View {
    let source: PhotoSource

    private var systemImage: String {
        switch source {
        case .icloud: return "icloud.fill"
        case .googlePhotos: return "photo.on.rectangle.angled"
        }
    }

    private var tint: Color {
        switch source {
        case .icloud: return .blue
        case .googlePhotos: return .red
        }
    }

    var body: some View {
        Label(source.displayName, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundStyle(tint)
            .accessibilityLabel("Source: \(source.displayName)")
    }
}

#Preview {
    HStack {
        CloudBadge(source: .icloud)
        CloudBadge(source: .googlePhotos)
    }
    .padding()
}
