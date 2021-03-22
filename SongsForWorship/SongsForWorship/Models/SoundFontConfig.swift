//
//  SoundFontConfig.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/22/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

struct SoundFontConfig: Decodable {
    let filetype: String
    let title: String
    let filename: String
    let isDefault: Bool
}
