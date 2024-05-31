//
//  LeftRightContainer.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/18/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation

public struct LeftRightContainer {
    public let left: [String]?
    public let right: [String]?
}

extension LeftRightContainer: Decodable {}
