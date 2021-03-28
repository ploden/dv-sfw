//
//  AppConfig.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/20/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct AppConfig: Decodable {
    let index: [IndexSection]
    let copyright: String
    let directory: String
    let defaultFont: String
    let defaultBoldFontName: String?
    let songCollections: [SongCollectionConfig]
    let soundFonts: [SoundFontConfig]
    let tuneRecordings: Bool
    let shouldShowAdditionalTunes: Bool
}