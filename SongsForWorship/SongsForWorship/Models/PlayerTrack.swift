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
    public let title: String?
    public let copyright: String?
    let albumTitle: String?
    public let artist: String?
    public let composer: String?
    let albumArtworkImage: UIImage?
    let albumArtwork: Artwork?
    let trackType: PlayerTrackType
    
    init(localFileTuneDescription: LocalFileTuneDescription) {
        title = localFileTuneDescription.title
        copyright = localFileTuneDescription.copyright
        trackType = .tune
        albumTitle = nil
        albumArtworkImage = nil
        albumArtwork = nil
        artist = nil
        composer = localFileTuneDescription.composer
    }
    
    init(mediaItem: MPMediaItem) {
        title = mediaItem.title
        copyright = nil
        albumTitle = mediaItem.albumTitle
        let artwork = mediaItem.artwork
        let image = artwork?.image(at: CGSize(width: 120.0, height: 120.0))
        albumArtworkImage = image
        albumArtwork = nil
        trackType = .recording
        artist = mediaItem.artist
        composer = nil
    }
    
    init(appleMusicItemTuneDescription: AppleMusicItemTuneDescription) {
        title = appleMusicItemTuneDescription.title
        copyright = nil
        
         // Image loading.
        if
            let imageCacheManager = (UIApplication.shared.delegate as? SFWAppDelegate)?.imageCacheManager,
            let imageURL = appleMusicItemTuneDescription.artwork?.imageURL(size: CGSize(width: 120, height: 120)),
            let image = imageCacheManager.cachedImage(url: imageURL)
        {
            albumArtworkImage = image
        } else {
            albumArtworkImage = nil
        }
                
        albumTitle = nil
        albumArtwork = appleMusicItemTuneDescription.artwork
        trackType = .recording
        artist = nil
        composer = nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        //hasher.combine(albumTitle)
        hasher.combine(trackType)
        //hasher.combine(artist)
        //hasher.combine(composer)
    }
}
