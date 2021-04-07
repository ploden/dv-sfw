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
        return true
    }
    
    private(set) var songCollections: [SongCollection] = [SongCollection]()
    private(set) var currentSong: Song?
    private(set) var songsToDisplay: [Song]?
    /*
    var currentCollection: SongCollection? {
        get {
            if let selectedCollection = selectedCollection {
                return selectedCollection
            } else {
                return songCollections.first
            }
        }
    }
     */
    
    required init(appConfig: AppConfig) {
        for collection in appConfig.songCollections {
            /*
            let filename = collection["json_name"] as! String
            let displayName = collection["Display name"] as! String
            let pdfName = collection["PDF"] as! String
             */
            var collectionSections = [SongCollectionSection]()
            
            let sections = collection.sections
            
            for section in sections {
                let newSection = SongCollectionSection(title: section.title, count: section.count)
                collectionSections.append(newSection)
            }
            
            /*
            let tuneInfos = collection["Tunes"] as? [[String : Any]]

            let blah: [SongCollectionTuneInfo] = tuneInfos?.compactMap {
                let title = $0["Title"] as! String
                let format = $0["Format"] as! String
                let type = $0["Type"] as! String
                let directory = $0["Directory"] as! String
                return SongCollectionTuneInfo(title: title, directory: directory, fileType: type, filenameFormat: format)
                } ?? [SongCollectionTuneInfo]()
             */
            
            let newCollection = SongCollection(directory: appConfig.directory, collectionConfig: collection)
            newCollection.pdfRenderingConfigs_iPhone = appConfig.pdfRenderingConfigs_iPhone
            newCollection.pdfRenderingConfigs_iPad = appConfig.pdfRenderingConfigs_iPad
            songCollections.append(newCollection)
        }
    }
    
    func loadSongs() {}
    
    /*
    func selectSongCollection(withName name: String) {
        if
            let collection = songCollections.filter({ $0.displayName == name }).first,
            collection != selectedCollection
        {
            selectedCollection = collection
            NotificationCenter.default.post(name: .selectedCollectionDidChange, object: self)
        }
    }
     */
    
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
        NotificationCenter.default.removeObserver(anObserver as Any)
    }
    
    func addObserver(forcurrentSong anObserver: PsalmObserver?) {
        NotificationCenter.default.addObserver(anObserver as Any, selector: #selector(PsalmObserver.songDidChange(_:)), name: .currentSongDidChange, object: nil)
    }

    func removeObserver(forcurrentSong anObserver: PsalmObserver?) {
        NotificationCenter.default.removeObserver(anObserver as Any)
    }
    
    func songForNumber(_ number: String?) -> Song? {
        if let number = number {
            let numAsInt: Int? = {
                if let i = Int(number) {
                    return i
                } else if let i = Int(number.dropLast()) {
                    return i
                } else {
                    return nil
                }
            }()

            if let numAsInt = numAsInt {
                if numAsInt > 150 {
                    return songCollections.last?.songForNumber(number)
                } else {
                    return songCollections.first?.songForNumber(number)
                }
            }
        }
        return nil
    }
    
    class func songAtIndex(_ anIndex: Int, allSongs: [Song]?) -> Song? {
        if anIndex < (allSongs?.count ?? 0) {
            return allSongs?[anIndex]
        } else {
        #if DEBUG
            //throw NSException(name: NSExceptionName("PsalmsManagerException"), reason: "songAtIndex:allSongs: index out of bounds", userInfo: nil) as! Error
        #endif
            return nil
        }
    }
}
