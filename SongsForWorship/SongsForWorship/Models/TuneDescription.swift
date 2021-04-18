//
//  TuneDescription.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 1/2/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import MediaPlayer

public enum TuneDescriptionMediaType {
    case localMIDI, localMP3, musicLibrary, appleMusic
}

public protocol TuneDescription {
    var length: TimeInterval? { get }
    var title: String { get }
    var composer: String? { get }
    var copyright: String? { get }
    var mediaType: TuneDescriptionMediaType { get }
}

public struct LocalFileTuneDescription: TuneDescription {
    public let length: TimeInterval?
    public let title: String
    public let composer: String?
    public let copyright: String?
    let url: URL
    public let mediaType: TuneDescriptionMediaType
}

public struct MusicLibraryItemTuneDescription: TuneDescription {
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
}

public struct AppleMusicItemTuneDescription: TuneDescription {
    public let appleMusicID: String
    public let length: TimeInterval?
    public let title: String
    public let composer: String?
    public let copyright: String?
    public let artwork: Artwork?
    public let mediaType: TuneDescriptionMediaType = .appleMusic
}
