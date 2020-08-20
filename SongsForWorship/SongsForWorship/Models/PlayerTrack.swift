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

struct PlayerTrack: Hashable, Equatable {
    let length: String?
    let title: String?
    let albumTitle: String?
    let artist: String?
    let albumArtwork: UIImage?
    let trackType: PlayerTrackType
    
    init(tuneDescription: TuneDescription) {
        length = tuneDescription.length
        title = tuneDescription.title
        trackType = .tune
        albumTitle = nil
        albumArtwork = nil
        artist = nil
    }
    
    init(mediaItem: MPMediaItem) {
        length = "\(mediaItem.playbackDuration)"
        title = mediaItem.title
        albumTitle = mediaItem.albumTitle
        let artwork = mediaItem.artwork
        let image = artwork?.image(at: CGSize(width: 120.0, height: 120.0))
        albumArtwork = image
        trackType = .recording
        artist = mediaItem.artist
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(length)
        hasher.combine(title)
        hasher.combine(albumTitle)
        hasher.combine(trackType)
        hasher.combine(artist)
    }
}
