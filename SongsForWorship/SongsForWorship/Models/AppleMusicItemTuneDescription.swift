//
//  AppleMusicItemTuneDescription.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/31/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation

/// A type that represents a tune from Apple Music. 
public struct AppleMusicItemTuneDescription: TuneDescriptionProtocol {
    public var lengthString: String?
    public let appleMusicID: String
    public let length: TimeInterval?
    public let title: String
    public let composer: String?
    public let copyright: String?
    public let artwork: Artwork?
    public let mediaType: TuneDescriptionMediaType = .appleMusic

    public init(lengthString: String? = nil,
                appleMusicID: String,
                length: TimeInterval? = nil,
                title: String,
                composer: String? = nil,
                copyright: String? = nil,
                artwork: Artwork? = nil)
    {
        self.lengthString = lengthString
        self.appleMusicID = appleMusicID
        self.length = length
        self.title = title
        self.composer = composer
        self.copyright = copyright
        self.artwork = artwork
    }
}
