//
//  StatusBadge.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 28.04.26.
//

import SwiftUI

struct StatusBadge: View {
    let title: String
    let tint: Color

    init(title: String, tint: Color = .secondary) {
        self.title = title
        self.tint = tint
    }

    init(title: String, status: VideoStatus) {
        self.title = title
        self.tint = status.tint
    }

    init(title: String, status: JobStatus) {
        self.title = title
        self.tint = status.tint
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(tint)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private extension VideoStatus {
    var tint: Color {
        switch self {
        case .ready, .processed:
            return .green
        case .failed:
            return .red
        case .processing, .uploading:
            return .blue
        case .queued, .uploaded:
            return .orange
        case .unknown:
            return .secondary
        }
    }
}

private extension JobStatus {
    var tint: Color {
        switch self {
        case .completed:
            return .green
        case .failed, .cancelled:
            return .red
        case .processing:
            return .blue
        case .pending, .queued:
            return .orange
        case .unknown:
            return .secondary
        }
    }
}

#Preview {
    StatusBadge(title: "Processing", status: JobStatus.processing)
        .padding()
}
