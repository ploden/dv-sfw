//
//  HasFileURL.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/8/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

protocol HasFileURL {
    var fileURL: URL? { get set }
}

protocol HasFileInfo {
    var fileInfo: FileInfo? { get set }
}
