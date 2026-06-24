//
//  TrustBanner.swift
//  PhotoSweep
//
//  Reassuring "we never delete your photos" messaging. Shown on screens where a
//  user might worry about losing photos (CLAUDE.md → keep trust language visible).
//

import SwiftUI

struct TrustBanner: View {
    var message: String = "PhotoSweep never deletes a photo. Nothing happens unless you say so."

    var body: some View {
        Label {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.green)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TrustBanner()
        .padding()
}
