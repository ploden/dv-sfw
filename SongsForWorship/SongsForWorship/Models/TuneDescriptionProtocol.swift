//
//  TuneDescriptionProtocol.swift
//  SongsForWorship
//
//  Created by Philip Loden on 5/31/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation

public enum TuneDescriptionMediaType {
    case localMIDI, localMP3, musicLibrary, appleMusic
}

/// A type that represents a playable tune.
public protocol TuneDescriptionProtocol {
    var lengthString: String? { get }
    var length: TimeInterval? { get }
    var title: String { get }
    var composer: String? { get }
    var copyright: String? { get }
    var mediaType: TuneDescriptionMediaType { get }
}
