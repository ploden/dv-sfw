//
//  TunesLoaderHelpers.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/25/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol TunesLoader {
    @objc dynamic static func filename(forTuneInfo tuneInfo: SongCollectionTuneInfo, song: Song) -> String?
    @objc dynamic static func loadTunes(forSong aSong: Song, completion: @escaping (Error?, [TuneDescription]) -> Void)
}
