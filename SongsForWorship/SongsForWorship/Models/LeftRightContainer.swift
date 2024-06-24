//
//  LeftRightContainer.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/18/23.
//  Copyright © 2023 Deo Volente, LLC. All rights reserved.
//

import Foundation

/// A type that assists in encoding/decoding the LeftRight type.
///
/// TODO: delete or move to TPH.
public struct LeftRightContainer {
    public let left: [String]?
    public let right: [String]?
}

extension LeftRightContainer: Decodable {}
