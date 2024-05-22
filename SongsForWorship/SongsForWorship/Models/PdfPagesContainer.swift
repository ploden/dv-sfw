//
//  PdfPagesContainer.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/10/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct PdfPagesContainer {
    public let number: Int
    public let musicStart: Float
    public let musicEnd: Float

    enum CodingKeys: String, CodingKey {
        case number
        case musicStart = "music_start"
        case musicEnd = "music_end"
    }
}

extension PdfPagesContainer: Decodable {}
