//
//  TuneDescription.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 1/2/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

public enum LocalFileTuneDescriptionMediaType {
    case midi, mp3
}

public protocol TuneDescription {
    var length: String? { get }
    var title: String { get }
    var composer: String? { get }
    var copyright: String? { get }
}

public struct LocalFileTuneDescription: TuneDescription {
    public let length: String?
    public let title: String
    public let composer: String?
    public let copyright: String?
    let url: URL
    public let mediaType: LocalFileTuneDescriptionMediaType
}

public struct AppleMusicItemTuneDescription: TuneDescription {
    public let appleMusicID: String
    public let length: String?
    public let title: String
    public let composer: String?
    public let copyright: String?
}
