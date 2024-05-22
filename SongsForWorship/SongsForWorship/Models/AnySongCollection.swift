//
//  PsalmsManager.swift
//  SongsForWorship
//
//  Created by Phil Loden on 2/8/13. Licensed under the MIT license, as follows:
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import QuartzCore
import PDFKit

extension Notification.Name {
    static let currentSongDidChange = Notification.Name("currentSongDidChange")
    static let settingsDidChange = Notification.Name("SFW_settingsDidChange")
    static let themeDidChange = Notification.Name("SFW_themeDidChange")
    static let selectedCollectionDidChange = Notification.Name("SelectedCollectionDidChange")
}

enum NotificationUserInfoKeys: String {
    case oldValue
    case newValue
}

@objc protocol PsalmObserver {
    @objc func songDidChange(_ notification: Notification)
}

@objc protocol SongCollectionObserver {
    @objc func selectedCollectionDidChange(_ notification: Notification)
}

/*
public protocol AnySongCollection: Equatable {
    associatedtype Song = any AnySong

    var jsonFilename: String { get }
    var pdfFilename: String { get }
    var directory: String { get }
    var displayName: String { get }
    var pdf: CGPDFDocument { get }
    var sections: [SongCollectionSection] { get }
    var pdfRenderingConfigsForiPhone: [PDFRenderingConfig] { get }
    var pdfRenderingConfigsForiPad: [PDFRenderingConfig] { get }
    var tuneInfos: [SongCollectionTuneInfo] { get }
    var songs: [Song] { get }

    /*
    required init(songs: [T], directory: String, collectionConfig: SongCollectionConfig) {
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

        self.songs = songs
    }
     */

    /*
    class open func readSongs(fromFile jsonFilename: String, directory: String) -> [AnySong] {
        let decoder = JSONDecoder()

        var songContainers: [SongContainer]

        do {
            guard
                let path = Bundle.main.path(forResource: jsonFilename, ofType: "json", inDirectory: directory),
                let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path))
            else
            {
                fatalError("SongCollection: readSongs: failed to read songs")
            }
            songContainers = (try decoder.decode([SongContainer].self, from: jsonData))
        } catch {
            fatalError("There was an error reading app config! \(error)")
        }

        var idx = 0

        let songs = songContainers.compactMap { songContainer in
            let composer = Composer(id: 0,
                                    fullName: songContainer.infoComposer,
                                    lastName: nil,
                                    firstName: nil,
                                    collection: nil)

            let tune = Tune(id: 0,
                            name: songContainer.infoTune ?? "",
                            nameWithoutMeter: songContainer.infoTuneWithoutMeter,
                            composer: composer,
                            composerCopyright: songContainer.composerCopyright,
                            composerDate: nil,
                            isCopyrighted: songContainer.isTuneCopyrighted ?? false,
                            meter: songContainer.infoMeter)

            let song = Song(index: idx,
                            number: songContainer.number,
                            title: songContainer.title,
                            stanzas: songContainer.stanzas,
                            pdfPageNumbers: songContainer.pdfPageNumbers.map { $0.number },
                            tune: tune,
                            left: songContainer.leftRight?.left,
                            right: songContainer.leftRight?.right)
            
            idx += 1
            return song
        }

        return songs
    }
     */

}

extension AnySongCollection {
    public static func == (lhs: any AnySongCollection, rhs: any AnySongCollection) -> Bool {
        return
            lhs.displayName == rhs.displayName //&&
            //lhs.songs == rhs.songs
    }

    func songForNumber(_ number: String?) -> (any AnySong)? {
        return nil
        //return songs.first(where: { $0.number == number })
    }
}
*/
