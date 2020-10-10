//
//  TunesLoaderHelpers.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/25/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

@objc public protocol TunesLoaderHelpers {
    @objc dynamic static func filename(forTuneInfo tuneInfo: SongCollectionTuneInfo, song: Song) -> String?
}

extension TunesLoader: TunesLoaderHelpers {
    
    @objc public dynamic static func filename(forTuneInfo tuneInfo: SongCollectionTuneInfo, song: Song) -> String? {
        return self.defaultFilename(forTuneInfo: tuneInfo, song: song)
    }

}
