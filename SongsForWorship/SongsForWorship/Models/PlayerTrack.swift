//
//  PlayerTrack.swift
//  SongsForWorship
//
//  Created by Phil Loden on 1/2/20. Licensed under the MIT license, as follows:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
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
