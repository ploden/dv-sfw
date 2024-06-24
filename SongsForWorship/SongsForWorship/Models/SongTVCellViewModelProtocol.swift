//
//  SongTVCellViewModelProtocol.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/11/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation

/// A type that assists in configuring a SongTVCell.
///
/// A SFW app can implement the view model to fulfill
/// its own requirements.
public protocol SongTVCellViewModelProtocol {
    var number: String { get }
    var title: String { get }
    var reference: String { get }

    init?(_ song: Song)
}
