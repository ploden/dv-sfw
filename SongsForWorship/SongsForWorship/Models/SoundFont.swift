//
//  SoundFont.swift
//  SongsForWorship
//
//  Created by Philip Loden on 9/17/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct SoundFont: Codable, Equatable {
    var filename: String
    var fileExtension: String
    var isDefault: Bool = false
    var title: String
}
