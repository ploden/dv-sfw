//
//  PlayerTrack.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 1/2/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import MediaPlayer

enum PlayerTrackType: UInt8 {
    case tune = 1
    case recording = 2
}

public struct PlayerTrack: Hashable, Equatable {
    let length: String?
    public let title: String?
    public let copyright: String?
    let albumTitle: String?
    public let artist: String?
    public let composer: String?
    let albumArtwork: UIImage?
    let trackType: PlayerTrackType
    
    init(tuneDescription: TuneDescription) {
        length = tuneDescription.length
        title = tuneDescription.title
        copyright = tuneDescription.copyright
        trackType = .tune
        albumTitle = nil
        albumArtwork = nil
        artist = nil
        composer = tuneDescription.composer
    }
    
    init(mediaItem: MPMediaItem) {
        length = "\(mediaItem.playbackDuration)"
        title = mediaItem.title
        copyright = nil
        albumTitle = mediaItem.albumTitle
        let artwork = mediaItem.artwork
        let image = artwork?.image(at: CGSize(width: 120.0, height: 120.0))
        albumArtwork = image
        trackType = .recording
        artist = mediaItem.artist
        composer = nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(length)
        hasher.combine(title)
        hasher.combine(albumTitle)
        hasher.combine(trackType)
        hasher.combine(artist)
        hasher.combine(composer)
    }
}
