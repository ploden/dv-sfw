//
//  MusicLibraryItemTuneDescription.swift
//  SongsForWorship
//
//  Created by Philip Loden on 6/3/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation
import MediaPlayer

/// A type that represents a tune existing in the user's music library. 
public struct MusicLibraryItemTuneDescription: TuneDescriptionProtocol {
    public var lengthString: String?
    public let mediaItem: MPMediaItem
    public var length: TimeInterval? {
        get {
            return mediaItem.playbackDuration
        }
    }
    public var title: String {
        get {
            return mediaItem.title ?? ""
        }
    }
    public let composer: String?
    public let copyright: String?
    public let mediaType: TuneDescriptionMediaType = .musicLibrary

    public init(lengthString: String? = nil, mediaItem: MPMediaItem, composer: String? = nil, copyright: String? = nil) {
        self.lengthString = lengthString
        self.mediaItem = mediaItem
        self.composer = composer
        self.copyright = copyright
    }
}
