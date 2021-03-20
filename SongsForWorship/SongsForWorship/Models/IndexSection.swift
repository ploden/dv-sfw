//
//  IndexSection.swift
//  SongsForWorship
//
//  Created by Philip Loden on 3/20/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

struct IndexSection: Decodable {
    let title: String?
    let rows: [IndexRow]?
}
