//
//  SongProtocol.swift
//  SongsForWorship
//
//  Created by Philip Loden on 6/24/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation

/// A type that represents a song.
protocol SongProtocol {
    var index: Int { get }
    var number: String { get }
    var title: String { get }
    var reference: String? { get }
    var stanzas: [String] { get }
    var pdfPageNumbers: [Int] { get }
    var isTuneCopyrighted: Bool { get }
    var tune: Tune? { get }
}
