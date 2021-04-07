//
//  PsalmsManager.swift
//  PsalmsForWorship
//
//  Created by Philip Loden on 2/8/13.
//  Copyright (c) 2013 Deo Volente, LLC. All rights reserved.
//

import Foundation
import QuartzCore
import PDFKit

extension Notification.Name {
    static let currentSongDidChange = Notification.Name("currentSongDidChange")
    static let settingsDidChange = Notification.Name("settingsDidChange")
    static let selectedCollectionDidChange = Notification.Name("SelectedCollectionDidChange")
}

enum NotificationUserInfoKeys: String {
    case oldValue = "oldValue"
    case newValue = "newValue"
}

@objc protocol PsalmObserver {
    @objc func songDidChange(_ notification: Notification)
}

@objc protocol SongCollectionObserver {
    @objc func selectedCollectionDidChange(_ notification: Notification)
}

open class SongCollection: NSObject {
    public static func == (lhs: SongCollection, rhs: SongCollection) -> Bool {
        return lhs.displayName == rhs.displayName
    }
    
    let jsonFilename: String
    let pdfFilename: String
    let directory: String
    let displayName: String
    let pdf: CGPDFDocument
    let sections: [SongCollectionSection]
    var pdfRenderingConfigs_iPhone: [PDFRenderingConfig] = [PDFRenderingConfig]()
    var pdfRenderingConfigs_iPad: [PDFRenderingConfig] = [PDFRenderingConfig]()
    public let tuneInfos: [SongCollectionTuneInfo]
    private(set) lazy var songs: [Song]? = {
        let songs = readSongsFromFile(jsonFilename: jsonFilename, directory: directory)
        
        func loadAll(idx: Int) {
            var song = songs![idx]
            
            BaseTunesLoader.loadTunes(forSong: song) { [weak self] someError, someTuneDescriptions in
                if idx+1 < songs!.count {
                    loadAll(idx: idx+1)
                }
            }
        }
        
        //loadAll(idx: 0)
        return songs
    }()

    required public init(directory: String, collectionConfig: SongCollectionConfig) {        
        self.jsonFilename = collectionConfig.jsonFilename
        self.displayName = collectionConfig.displayName
        self.pdfFilename = collectionConfig.pdfFilename
        
        self.directory = directory
                
        var collectionSections = [SongCollectionSection]()

        for section in collectionConfig.sections {
            let newSection = SongCollectionSection(title: section.title, count: section.count)
            collectionSections.append(newSection)
        }
        
        self.sections = collectionSections
        
        let tuneInfos: [SongCollectionTuneInfo]? = collectionConfig.tunes.compactMap {            
            return SongCollectionTuneInfo(title: $0.title, directory: $0.directory, fileType: $0.filetype, filenameFormat: $0.filenameFormat)
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
                                composerDate: nil,
                                composerCopyright: dict["composer_copyright"] as? String,
                                isCopyrighted: isTuneCopyrighted,
                                meter: dict["info_meter"] as? String ?? "")
                
                if let p = Song(fromDict: dict, index: index, tune: tune, collection: self) {
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
    }
}
