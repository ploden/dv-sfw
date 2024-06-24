//
//  LocalFileTuneDescription.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/31/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation

/// A type that represents a tune that is saved locally
/// on the device. 
public struct LocalFileTuneDescription: TuneDescriptionProtocol {
    public var length: TimeInterval?
    public let lengthString: String?
    public let title: String
    public let composer: String?
    public let copyright: String?
    public let url: URL
    public let mediaType: TuneDescriptionMediaType

    public init(lengthString: String? = nil,
                title: String,
                composer: String? = nil,
                copyright: String? = nil,
                url: URL,
                mediaType: TuneDescriptionMediaType)
    {
        self.lengthString = lengthString
        self.title = title
        self.composer = composer
        self.copyright = copyright
        self.url = url
        self.mediaType = mediaType
    }
}
