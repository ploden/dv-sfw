//
//  SongCollectionFactory.swift
//  SongsForWorship
//
//  Created by Philip Loden on 8/18/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

@objc public protocol SongCollectionFactory {
    @objc dynamic func readSongsFromFile(jsonFilename: String, directory: String) -> [Song]?
}

extension SongCollection: SongCollectionFactory {
    
    @objc public dynamic func readSongsFromFile(jsonFilename: String, directory: String) -> [Song]? {
        return self.defaultReadSongsFromFile(jsonFilename: jsonFilename, directory: directory)
    }

}
