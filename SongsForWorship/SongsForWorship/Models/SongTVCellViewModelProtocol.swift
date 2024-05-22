//
//  SongTVCellViewModelProtocol.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/11/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation

public protocol SongTVCellViewModelProtocol {
    var number: String { get }
    var title: String { get }
    var reference: String { get }

    init(_ song: Song)
}
