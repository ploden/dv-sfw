//
//  Error.swift
//  SongsForWorship
//
//  Created by Philip Loden on 7/25/24.
//  Copyright © 2024 Deo Volente, LLC. All rights reserved.
//

import Foundation

enum AppError: Error {

    /// This case indicates that setting up the initial view hierarchy failed.
    case buildNavStackFailed(String)
}
