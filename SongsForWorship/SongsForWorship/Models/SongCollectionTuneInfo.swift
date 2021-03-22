//
//  SongCollectionTuneInfo.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 5/18/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

public class SongCollectionTuneInfo: NSObject, Decodable {
    let title: String
    let directory: String
    let filetype: String
    let filenameFormat: String
    
    public init(title: String, directory: String, fileType: String, filenameFormat: String) {
        self.title = title
        self.directory = directory
        self.filetype = fileType
        self.filenameFormat = filenameFormat
    }
}
