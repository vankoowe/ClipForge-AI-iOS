//
//  PickedVideo.swift
//  ClipForgeAI
//
//  Created by Ivan Gamov on 05.05.26.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { receivedFile in
            let pathExtension = receivedFile.file.pathExtension
            let fileExtension = pathExtension.isEmpty ? "mov" : pathExtension
            let copiedURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(fileExtension)

            try FileManager.default.copyItem(at: receivedFile.file, to: copiedURL)
            return PickedVideo(url: copiedURL)
        }
    }
}
