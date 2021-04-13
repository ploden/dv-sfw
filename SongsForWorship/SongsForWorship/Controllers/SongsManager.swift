//
//  SongsManager.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 3/30/20.
//  Copyright © 2020 Deo Volente, LLC. All rights reserved.
//

import Foundation

class SongsManager: Equatable {
    static func == (lhs: SongsManager, rhs: SongsManager) -> Bool {
        return lhs.songCollections == rhs.songCollections &&
            lhs.currentSong == rhs.currentSong &&
            lhs.songsToDisplay == rhs.songsToDisplay
    }
    
    private(set) var songCollections: [SongCollection] = [SongCollection]()
    private(set) var currentSong: Song?
    private(set) var songsToDisplay: [Song]?

    required init(appConfig: AppConfig) {
        for collection in appConfig.songCollections {
            var collectionSections = [SongCollectionSection]()
            
            let sections = collection.sections
            
            for section in sections {
                let newSection = SongCollectionSection(title: section.title, count: section.count)
                collectionSections.append(newSection)
            }

            let newCollection = SongCollection(directory: appConfig.directory, collectionConfig: collection)
            newCollection.pdfRenderingConfigs_iPhone = appConfig.pdfRenderingConfigs_iPhone
            newCollection.pdfRenderingConfigs_iPad = appConfig.pdfRenderingConfigs_iPad
            songCollections.append(newCollection)
        }
    }
    
    func loadSongs() {}
    
    func setcurrentSong(_ currentSong: Song?, songsToDisplay: [Song]?) {
        if self.currentSong != currentSong || self.songsToDisplay != songsToDisplay {
            let previousSong = self.currentSong
            self.currentSong = currentSong
            self.songsToDisplay = songsToDisplay
            let userInfo = [NotificationUserInfoKeys.oldValue: previousSong, NotificationUserInfoKeys.newValue: self.currentSong]
            NotificationCenter.default.post(name: .currentSongDidChange, object: self, userInfo: userInfo as [AnyHashable:Any])
        }
    }

    func addObserver(forSelectedCollection anObserver: SongCollectionObserver?) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(SongCollectionObserver.selectedCollectionDidChange), name: .selectedCollectionDidChange, object: nil)
    }

    func removeObserver(forSelectedCollection anObserver: SongCollectionObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .selectedCollectionDidChange, object: nil)
    }
    
    func addObserver(forcurrentSong anObserver: PsalmObserver?) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(PsalmObserver.songDidChange(_:)), name: .currentSongDidChange, object: nil)
    }

    func removeObserver(forcurrentSong anObserver: PsalmObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any, name: .currentSongDidChange, object: nil)
    }
    
    func songForNumber(_ number: String?) -> Song? {
        for collection in songCollections {
            if let match = collection.songForNumber(number) {
                return match
            }
        }
        return nil
    }
}
