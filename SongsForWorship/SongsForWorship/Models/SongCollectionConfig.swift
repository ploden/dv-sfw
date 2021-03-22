//
//  SongCollectionConfig.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/22/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct SongCollectionConfig: Decodable {
    let displayName: String
    let sections: [SongCollectionSection]
    let jsonFilename: String
    let pdfFilename: String
    let tunes: [SongCollectionTuneInfo]
}
