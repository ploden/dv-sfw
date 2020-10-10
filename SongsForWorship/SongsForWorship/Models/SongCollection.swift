//
//  PsalmsManager.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 2/8/13.
//  Copyright (c) 2013 Deo Volente, LLC. All rights reserved.
//

import Foundation
import QuartzCore

extension Notification.Name {
    static let currentSongDidChange = Notification.Name("currentSongDidChange")
    static let selectedCollectionDidChange = Notification.Name("SelectedCollectionDidChange")
}

@objc protocol PsalmObserver {
    @objc func songDidChange(_ notification: Notification)
}

@objc protocol SongCollectionObserver {
    @objc func selectedCollectionDidChange(_ notification: Notification)
}

open class SongCollection: Equatable {
    public static func == (lhs: SongCollection, rhs: SongCollection) -> Bool {
        return lhs.displayName == rhs.displayName
    }
    
    let collectionDict: [String : Any]
    let jsonFilename: String
    let pdfFilename: String
    let directory: String
    let displayName: String
    let pdf: CGPDFDocument
    let sections: [SongCollectionSection]
    let tuneInfos: [SongCollectionTuneInfo]
    private(set) lazy var songs: [Song]? = {
        let songs = readSongsFromFile(jsonFilename: jsonFilename, directory: directory)
        for song in songs! {
            TunesLoader.loadTunes(forSong: song, collection: self) { [weak self] someError, someTuneDescriptions in }
        }
        return songs
    }()

    required public init(directory: String, collectionDict: [String : Any]) {
        self.collectionDict = collectionDict
        
        self.jsonFilename = collectionDict["json_name"] as! String
        self.displayName = collectionDict["Display name"] as! String
        self.pdfFilename = collectionDict["PDF"] as! String
        
        self.directory = directory
        
        let sections = collectionDict["Sections"] as! [[String : Any]]
        
        var collectionSections = [SongCollectionSection]()

        for section in sections {
            let title = section["Title"] as! String
            let count = section["Count"] as! NSNumber
            let newSection = SongCollectionSection(title: title, count: count.intValue)
            collectionSections.append(newSection)
        }
        
        self.sections = collectionSections
        
        let tuneInfoDicts = collectionDict["Tunes"] as? [[String : Any]]

        let tuneInfos: [SongCollectionTuneInfo]? = tuneInfoDicts?.compactMap {
            let title = $0["Title"] as! String
            let format = $0["Format"] as! String
            let type = $0["Type"] as! String
            let directory = $0["Directory"] as! String
            return SongCollectionTuneInfo(title: title, directory: directory, fileType: type, filenameFormat: format)
        }
        
        self.tuneInfos = tuneInfos ?? [SongCollectionTuneInfo]()
        
        self.pdf = CGPDFDocument(URL(fileURLWithPath: Bundle.main.path(forResource: pdfFilename, ofType: "pdf", inDirectory: directory)!) as CFURL)!
    }    

    public func defaultReadSongsFromFile(jsonFilename: String, directory: String) -> [Song]? {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: jsonFilename, ofType: "json", inDirectory: directory) ?? "")

        var _: Error? = nil
        var jsonString: String? = nil
        do {
            jsonString = try String(contentsOf: url, encoding: String.Encoding.utf8)
        } catch {
            print("There was an error setting the session category: \(error)")
        }

        let jsonData = jsonString?.data(using: .utf8)
        var _: Error? = nil
        var dictsArray: [AnyHashable]? = nil
        do {
            if let jsonData = jsonData {
                dictsArray = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [AnyHashable]
            }
        } catch {
        }

        if let dictsArray = dictsArray {
            var songsArray = [Song]()
            
            var index = 0
            
            for dict in dictsArray {
                guard let dict = dict as? [AnyHashable : Any] else {
                    continue
                }
                
                let isTuneCopyrighted: Bool = {
                    if let object = dict["is_tune_copyrighted"] as? Bool {
                        return object
                    } else {
                        return false
                    }
                }()                                
                
                let composer = Composer(fullName: dict["info_composer"] as? String ?? "",
                                        lastName: nil,
                                        firstName: nil,
                                        collection: nil)
                
                let tune = Tune(name: dict["info_tune"] as? String ?? "",
                                nameWithoutMeter: dict["info_tune_wo_meter"] as? String ?? "",
                                composer: composer,
                                isCopyrighted: isTuneCopyrighted,
                                meter: dict["info_meter"] as? String ?? "")
                
                if let p = Song(fromDict: dict, index: index, tune: tune) {
                    songsArray.append(p)
                    index += 1
                }
            }
            return songsArray
        }

        return nil
    }

    func songForNumber(_ number: String?) -> Song? {
        return songs?.first(where: { $0.number == number })
        /*
        if let songs = songs {
            let index = (songs as NSArray?)?.indexOfObject(passingTest: { obj, idx, stop in
                let song = obj as? Song
                
                if (song?.number == number) {
                    return true
                }
                
                return false
            })
            
            var song: Song?
            
            if
                let index = index,
                index < songs.count
            {
                song = songs[index]
            }
            
            return song
        }
        return nil
 */
    }
}
