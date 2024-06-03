//
//  AppleMusicMediaItem.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/15/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct AppleMusicMediaItem {
    public let id: String
    public let artistName: String
    public let albumName: String
    public let name: String
    public let artwork: Artwork
    public let length: TimeInterval

    public init(id: String, artistName: String, albumName: String, name: String, artwork: Artwork, length: TimeInterval) {
        self.id = id
        self.artistName = artistName
        self.albumName = albumName
        self.name = name
        self.artwork = artwork
        self.length = length
    }
}
