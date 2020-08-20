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
    
    let jsonFilename: String
    let pdfFilename: String
    let directory: String
    let displayName: String
    let pdf: CGPDFDocument
    let sections: [SongCollectionSection]
    let tuneInfos: [SongCollectionTuneInfo]
    private(set) lazy var songs: [Song]? = {
        return readSongsFromFile(jsonFilename: jsonFilename, directory: directory)
    }()

    required public init(jsonFilename: String, pdfFilename: String, directory: String, displayName: String, sections: [SongCollectionSection], tuneInfos: [SongCollectionTuneInfo]) {
        self.jsonFilename = jsonFilename
        self.pdfFilename = pdfFilename
        self.directory = directory
        self.displayName = displayName
        self.sections = sections
        self.tuneInfos = tuneInfos
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
                if let p = Song(fromDict: dict, index: index) {
                    songsArray.append(p)
                    index += 1
                }
            }
            return songsArray
        }

        return nil
    }

    func songForNumber(_ number: String?) -> Song? {
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
    }
}