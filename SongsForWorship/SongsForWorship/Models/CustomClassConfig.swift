//
//  CustomClassConfig.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/9/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

struct CustomClassConfig: Decodable {
    let baseName: String
    let customName: String
    let storyboardID: String?
}
