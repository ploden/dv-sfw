//
//  SerializationError.swift
//  SongsForWorship
//
//  Created by Philip Loden on 4/18/21.
//  Copyright © 2021 Deo Volente, LLC. All rights reserved.
//

import Foundation

enum SerializationError: Error {
    
    /// This case indicates that the expected field in the JSON object is not found.
    case missing(String)
}
