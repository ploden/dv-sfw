//
//  IndexRow.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/20/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

struct IndexRow: Decodable {
    let filename: String?
    let filetype: String?
    let storyboardName: String?
    let storyboardID: String?
    let className: String?
    let title: String?
    let index: [IndexSection]?
    let action: String?
}
